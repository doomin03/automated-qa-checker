import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, isAbsolute, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { isBuiltin } from 'node:module';
import ts from 'typescript';

const root = fileURLToPath(new URL('../', import.meta.url));
const inside = (base, file) => {
  const rel = relative(base, file);
  return rel === '' || (!rel.startsWith('..') && !isAbsolute(rel));
};
const readJson = file => JSON.parse(readFileSync(file, 'utf8'));
const layers = ['app', 'pages', 'widgets', 'features', 'entities', 'shared'];

export function packagesAt(repository) {
  return ['apps', 'packages'].flatMap(group =>
    readdirSync(resolve(repository, group), { withFileTypes: true })
      .filter(entry => entry.isDirectory())
      .map(entry => ({ path: `${group}/${entry.name}`, directory: resolve(repository, group, entry.name) }))
      .filter(entry => existsSync(resolve(entry.directory, 'package.json')))
      .map(entry => ({ ...entry, manifest: readJson(resolve(entry.directory, 'package.json')) }))
  );
}

export function checkDependency(owner, name, version, packages) {
  const errors = [];
  const target = packages.find(item => item.manifest.name === name);
  if (/^(?:file:|link:|\.\.?[/\\]|[/\\]|[A-Za-z]:[/\\])/.test(version)) errors.push(`local path dependency forbidden: ${name}`);
  if (target) {
    if (version !== 'workspace:*') errors.push(`internal dependency must use workspace:*: ${name}`);
    if (target.path.startsWith('apps/')) errors.push(`application dependency forbidden: ${name}`);
    if (owner.path === 'apps/server' && target.path === 'packages/api-client') errors.push('server cannot consume its generated API client');
  } else if (version.startsWith('workspace:')) {
    errors.push(`missing workspace package: ${name}`);
  }
  return errors;
}

export function checkSource(file, source, owner, packages) {
  const errors = [];
  const declared = owner.manifest.dependencies ?? {};
  const check = specifier => {
    if (specifier.startsWith('.')) {
      const target = resolve(dirname(file), specifier);
      if (!inside(owner.directory, target)) errors.push(`cross-package source import: ${specifier}`);
      if (owner.path === 'apps/web') {
        const layerOf = p => relative(resolve(owner.directory, 'src'), p).split(/[/\\]/)[0];
        const from = layers.indexOf(layerOf(file));
        const to = layers.indexOf(layerOf(target));
        if (from >= 0 && to >= 0 && from > to) errors.push(`FSD upward import: ${specifier}`);
      }
      return;
    }
    if (isBuiltin(specifier)) {
      if (owner.path === 'apps/web') errors.push(`Node builtin in browser source: ${specifier}`);
      return;
    }
    if (/^(?:[/\\]|[A-Za-z]:|https?:|file:|data:|#|@\/)/.test(specifier)) {
      errors.push(`unsupported module path or alias: ${specifier}`);
      return;
    }
    const name = specifier.startsWith('@') ? specifier.split('/').slice(0, 2).join('/') : specifier.split('/')[0];
    if (!(name in declared)) errors.push(`undeclared runtime dependency: ${name}`);
    const target = packages.find(item => item.manifest.name === name);
    if (target) {
      errors.push(...checkDependency(owner, name, declared[name] ?? '', packages));
      const subpath = specifier === name ? '.' : `.${specifier.slice(name.length)}`;
      const exports = target.manifest.exports;
      const exposed = typeof exports === 'string' ? subpath === '.' : exports && Object.hasOwn(exports, subpath);
      if (!exposed) errors.push(`workspace public export required: ${specifier}`);
    }
  };
  const tree = ts.createSourceFile(file, source, ts.ScriptTarget.Latest, true);
  function visit(node) {
    if (ts.isImportEqualsDeclaration(node) && ts.isExternalModuleReference(node.moduleReference) && node.moduleReference.expression && ts.isStringLiteralLike(node.moduleReference.expression)) check(node.moduleReference.expression.text);
    if ((ts.isImportDeclaration(node) || ts.isExportDeclaration(node)) && node.moduleSpecifier && ts.isStringLiteralLike(node.moduleSpecifier)) check(node.moduleSpecifier.text);
    if (ts.isImportTypeNode(node) && ts.isLiteralTypeNode(node.argument) && ts.isStringLiteralLike(node.argument.literal)) check(node.argument.literal.text);
    if (ts.isCallExpression(node) && (node.expression.kind === ts.SyntaxKind.ImportKeyword || (ts.isIdentifier(node.expression) && node.expression.text === 'require'))) {
      if (node.arguments.length === 1 && ts.isStringLiteralLike(node.arguments[0])) check(node.arguments[0].text);
      else errors.push('computed module import requires an explicit boundary policy');
    }
    ts.forEachChild(node, visit);
  }
  visit(tree);
  return errors;
}

function sources(directory) {
  if (!existsSync(directory)) return [];
  return readdirSync(directory, { withFileTypes: true }).flatMap(entry => {
    if (['node_modules', 'dist', 'build', '.git'].includes(entry.name)) return [];
    const file = resolve(directory, entry.name);
    return entry.isDirectory() ? sources(file) : /\.[cm]?[jt]sx?$/.test(entry.name) ? [file] : [];
  });
}

export function checkRepository(repository = root) {
  const packages = packagesAt(repository);
  const errors = [];
  const names = new Set();
  for (const owner of packages) {
    if (names.has(owner.manifest.name)) errors.push(`duplicate package name: ${owner.manifest.name}`);
    names.add(owner.manifest.name);
    if (['apps/app', 'packages/api_client_dart'].includes(owner.path)) errors.push(`Dart boundary cannot be a Node package: ${owner.path}`);
    if (owner.path === 'packages/engine') errors.push('engine source must stay in its independent repository');
    for (const group of ['dependencies', 'devDependencies', 'optionalDependencies', 'peerDependencies']) {
      for (const [name, version] of Object.entries(owner.manifest[group] ?? {})) {
        errors.push(...checkDependency(owner, name, version, packages).map(error => `${owner.path}: ${error}`));
      }
    }
    for (const file of sources(resolve(owner.directory, 'src'))) {
      errors.push(...checkSource(file, readFileSync(file, 'utf8'), owner, packages).map(error => `${relative(repository, file)}: ${error}`));
    }
  }
  // Manifest edges must also be acyclic, including future SDK/build-tool packages.
  const active = new Set();
  const done = new Set();
  function visit(owner) {
    const name = owner.manifest.name;
    if (active.has(name)) { errors.push(`workspace dependency cycle: ${[...active, name].join(' -> ')}`); return; }
    if (done.has(name)) return;
    active.add(name);
    const deps = { ...owner.manifest.dependencies, ...owner.manifest.devDependencies, ...owner.manifest.optionalDependencies, ...owner.manifest.peerDependencies };
    for (const target of packages.filter(p => p.manifest.name in deps)) visit(target);
    active.delete(name);
    done.add(name);
  }
  for (const owner of packages) visit(owner);
  return errors;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const errors = checkRepository();
  if (errors.length) { console.error(errors.join('\n')); process.exitCode = 1; }
  else console.log('Monorepo boundaries OK: package manifests and JS/TS source imports. Flutter runtime checks remain separate.');
}
