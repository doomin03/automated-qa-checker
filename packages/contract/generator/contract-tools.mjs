import { readFile, readdir, mkdir, writeFile, rm, mkdtemp, cp } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { resolve, dirname, relative, join, isAbsolute } from 'node:path';
import { tmpdir } from 'node:os';

export const root = fileURLToPath(new URL('../../../', import.meta.url));
const config = JSON.parse(await readFile(new URL('toolchain.json', import.meta.url)));
const toolDirectory = resolve(root, '.local/server-tools');
const java = process.env.QA_JAVA ?? resolve(toolDirectory, 'jdk-21.0.13+9-jre/bin/java.exe');
const dart = process.env.QA_DART ?? resolve(root, '../.tools/flutter-3.47.5/bin/cache/dart-sdk/bin/dart.exe');
const jar = resolve(toolDirectory, `openapi-generator-cli-${config.generatorVersion}.jar`);

export function run(command, args, cwd = root) {
  const result = spawnSync(command, args, { cwd, encoding: 'utf8', windowsHide: true, maxBuffer: 16 * 1024 * 1024 });
  if (result.error || result.status !== 0) throw new Error(`${command} ${args.join(' ')} failed\n${result.error ?? ''}\n${result.stdout}\n${result.stderr}`);
  return result.stdout;
}

export function lintDocument(document) {
  if (document.openapi !== '3.0.3') throw new Error('Only OpenAPI 3.0.3 is supported');
  const ids = new Set();
  for (const path of Object.values(document.paths)) for (const method of ['get', 'post', 'put', 'patch', 'delete']) {
    if (!path[method]) continue;
    const id = path[method].operationId;
    if (!id || ids.has(id)) throw new Error(`Missing or duplicate operationId: ${id}`);
    ids.add(id);
  }
  function visit(value) {
    if (!value || typeof value !== 'object') return;
    if (value.$ref) {
      if (!value.$ref.startsWith('#/')) throw new Error(`External ref is not reproducible: ${value.$ref}`);
      let item = document;
      for (const key of value.$ref.slice(2).split('/')) item = item?.[key.replaceAll('~1', '/').replaceAll('~0', '~')];
      if (!item) throw new Error(`Broken ref: ${value.$ref}`);
    }
    for (const item of Object.values(value)) visit(item);
  }
  visit(document);
}

export async function files(directory) {
  const output = new Map();
  async function walk(current) {
    for (const entry of await readdir(current, { withFileTypes: true })) {
      const path = join(current, entry.name);
      if (entry.isDirectory()) await walk(path);
      else output.set(relative(directory, path).replaceAll('\\', '/'), await readFile(path));
    }
  }
  try { await walk(directory); } catch (error) { if (error.code !== 'ENOENT') throw error; }
  return output;
}

export function differences(expected, actual) {
  return [...new Set([...expected.keys(), ...actual.keys()])].sort().filter(path => !expected.has(path) || !actual.has(path) || !expected.get(path).equals(actual.get(path)));
}

async function copyTree(source, destination) {
  for (const [path, bytes] of await files(source)) {
    await mkdir(dirname(join(destination, path)), { recursive: true });
    await writeFile(join(destination, path), bytes);
  }
}

export async function generate(destination, fixtureDocument) {
  const hash = createHash('sha256').update(await readFile(jar)).digest('hex');
  if (hash !== config.jarSha256) throw new Error('OpenAPI generator JAR checksum mismatch');
  const javaInfo = spawnSync(java, ['-version'], { encoding: 'utf8', windowsHide: true });
  if (javaInfo.error || !javaInfo.stderr?.includes(`"${config.javaVersion}"`)) throw new Error(`Required Java ${config.javaVersion}: ${javaInfo.error ?? javaInfo.stderr}`);
  if (!run(dart, ['--version']).includes(config.dartVersion)) throw new Error(`Required Dart ${config.dartVersion}; set QA_DART`);
  const documentPath = join(destination, 'openapi.json');
  if (fixtureDocument) await writeFile(documentPath, fixtureDocument);
  else run(process.execPath, ['apps/server/dist/scripts/export-openapi.js', documentPath]);
  const document = JSON.parse(await readFile(documentPath)); lintDocument(document);
  const operations = Object.entries(document.paths).flatMap(([path, item]) => Object.entries(item)
    .filter(([method, operation]) => ['get', 'post', 'put', 'patch', 'delete'].includes(method) && operation.operationId)
    .map(([method, operation]) => ({ operationId: operation.operationId, method: method.toUpperCase(), path, schema: (Object.entries(operation.responses).find(([status]) => /^2\d\d$/.test(status))?.[1]?.content?.['application/json']?.schema?.$ref ?? '').split('/').at(-1) })));
  const stage = await mkdtemp(join(tmpdir(), 'qa-codegen-'));
  try {
    for (const [name, generator] of [['typescript', 'typescript-fetch'], ['dart', 'dart-dio']]) {
      const target = join(stage, name);
      const args = ['-jar', jar, 'generate', '-i', documentPath, '-g', generator, '-o', target,
        '--additional-properties', Object.entries(config[name]).map(([key, value]) => `${key}=${value}`).join(','),
        '--global-property', 'apiTests=false,modelTests=false,apiDocs=false,modelDocs=false'];
      if (name === 'dart') args.push('-t', resolve(root, 'packages/contract/generator/templates'));
      run(java, args);
    }
    await copyTree(join(stage, 'typescript/apis'), join(destination, 'ts/apis'));
    await copyTree(join(stage, 'typescript/models'), join(destination, 'ts/models'));
    for (const name of ['index.ts', 'runtime.ts']) await cp(join(stage, 'typescript', name), join(destination, 'ts', name));
    await writeFile(join(destination, 'ts/contract-schema.ts'), `// Generated from server OpenAPI. Do not edit.\nexport const schemas = ${JSON.stringify(document.components.schemas, null, 2)} as const;\nexport const responseOperations = ${JSON.stringify(operations, null, 2)} as const;\n`);
    const lock = resolve(root, 'packages/api_client_dart/pubspec.lock');
    try { await cp(lock, join(stage, 'dart/pubspec.lock')); } catch (error) { if (error.code !== 'ENOENT') throw error; }
    run(dart, ['pub', 'get'], join(stage, 'dart'));
    run(dart, ['run', 'build_runner', 'build'], join(stage, 'dart'));
    // dart-dio emits error DTO imports unused by its success-only API parser.
    run(dart, ['fix', '--apply', '--code=unused_import'], join(stage, 'dart'));
    await writeFile(join(stage, 'dart/lib/src/contract_schema.dart'), `// Generated from server OpenAPI. Do not edit.\nimport 'dart:convert';\nfinal Map<String, dynamic> contractSchemas = jsonDecode(r'''${JSON.stringify(document.components.schemas)}''') as Map<String, dynamic>;\nfinal List<dynamic> responseOperations = jsonDecode(r'''${JSON.stringify(operations)}''') as List<dynamic>;\n`);
    run(dart, ['format', 'lib'], join(stage, 'dart'));
    await copyTree(join(stage, 'dart/lib'), join(destination, 'dart/lib'));
    for (const name of ['pubspec.yaml', 'pubspec.lock', 'build.yaml', 'analysis_options.yaml']) await cp(join(stage, 'dart', name), join(destination, 'dart', name));
  } finally { await rm(stage, { recursive: true, force: true }); }
}

export async function generateOrCheck(check) {
  const stage = await mkdtemp(join(tmpdir(), 'qa-contract-'));
  try {
    await generate(stage);
    const groups = [
      [join(stage, 'ts'), resolve(root, 'packages/api-client/src/generated')],
      [join(stage, 'dart/lib/src'), resolve(root, 'packages/api_client_dart/lib/src')],
    ];
    const singles = [
      ['openapi.json', 'packages/contract/openapi.json'],
      ...['pubspec.yaml', 'pubspec.lock', 'build.yaml', 'analysis_options.yaml', 'lib/api_client_dart.dart'].map(p => [`dart/${p}`, `packages/api_client_dart/${p}`]),
    ];
    const drift = [];
    for (const [source, target] of groups) {
      if (check) drift.push(...differences(await files(source), await files(target)).map(p => `${relative(root, target)}/${p}`));
      else {
        const rel = relative(root, target);
        if (rel.startsWith('..') || isAbsolute(rel) || !rel.startsWith('packages')) throw new Error('Unsafe generation destination');
        await rm(target, { recursive: true, force: true });
        await copyTree(source, target);
      }
    }
    for (const [source, target] of singles) {
      const bytes = await readFile(join(stage, source));
      if (check) {
        const actual = await readFile(resolve(root, target)).catch(error => { if (error.code === 'ENOENT') return null; throw error; });
        if (!actual?.equals(bytes)) drift.push(target);
      } else { await mkdir(dirname(resolve(root, target)), { recursive: true }); await writeFile(resolve(root, target), bytes); }
    }
    if (drift.length) throw new Error(`Generated contract drift:\n${drift.join('\n')}`);
    console.log(check ? 'Contract drift check passed (working tree unchanged).' : 'OpenAPI and TS/Dart clients generated.');
  } finally { await rm(stage, { recursive: true, force: true }); }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  if (!['generate', 'check'].includes(process.argv[2])) throw new Error('Usage: contract-tools.mjs generate|check');
  await generateOrCheck(process.argv[2] === 'check');
}
