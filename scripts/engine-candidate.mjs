// Test tooling only: the default installer, source assets and pins are untouched.
import assert from 'node:assert/strict';
import {access, mkdir, readFile, readdir, realpath, writeFile} from 'node:fs/promises';
import {dirname, isAbsolute, join, relative, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';

const repository = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const digest = bytes => createHash('sha256').update(bytes).digest('hex');
const shaPattern = /^[a-f0-9]{64}$/;
export async function preflightCandidate(input, root = repository) {
  const {artifact, version, sha256, bundleSha256, contractVersion, verificationPath} = input;
  assert(isAbsolute(artifact ?? '') && isAbsolute(verificationPath ?? ''), 'Absolute archive and verification paths required');
  assert(/^0\.1\.0-alpha\.[1-9][0-9]*$/.test(version ?? ''), 'Explicit expected version required');
  assert(shaPattern.test(sha256 ?? '') && shaPattern.test(bundleSha256 ?? ''), 'Explicit SHA-256 values required');
  assert.equal(contractVersion, '0.3.0-draft.2', 'Unsupported expected contract');
  const verificationBytes = await readFile(verificationPath);
  const verification = JSON.parse(verificationBytes);
  assert.equal(verification.status, 'passed', 'Candidate verification must have passed');
  assert.equal(verification.engineVersion, version, 'Expected version mismatch');
  assert.equal(verification.contractVersion, contractVersion, 'Expected contract mismatch');
  assert.equal(verification.sha256, sha256, 'Expected archive hash mismatch');
  assert.equal(verification.bundle?.engineVersion, version, 'Bundle version mismatch');
  assert.equal(verification.bundle?.contractVersion, contractVersion, 'Bundle contract mismatch');
  assert.equal(verification.bundle?.sha256, bundleSha256, 'Expected bundle hash mismatch');
  assert.equal(digest(await readFile(artifact)), sha256, 'Archive bytes mismatch');
  assert(Array.isArray(verification.installedFiles) && verification.installedFiles.length > 0, 'Missing candidate file hashes');
  const expectedFiles = {};
  for (const file of verification.installedFiles) {
    assert(typeof file.path === 'string' && file.path.split('/').every(segment => /^[A-Za-z0-9_.-]+$/.test(segment) && segment !== '.' && segment !== '..'), 'Unsafe candidate file path');
    assert(!Object.hasOwn(expectedFiles, file.path) && shaPattern.test(file.sha256), 'Duplicate file or invalid file hash');
    expectedFiles[file.path] = file.sha256;
  }
  assert(expectedFiles['package.json'] && expectedFiles['packages/cli/aqa.mjs'] && expectedFiles['contracts/schemas/qa.schema.json'], 'Missing public package files');
  assert.equal(expectedFiles[`contracts/releases/qa-contract-${version}.json`], bundleSha256, 'Release file differs from approved bundle');
  const destination = resolve(root, '.local/service-audit/candidates', version, sha256);
  try { await access(destination); assert.fail('Refuse to overwrite existing candidate directory'); } catch (error) { if (error.code !== 'ENOENT') throw error; }
  return {...input, destination, expectedFiles, verificationSha256: digest(verificationBytes)};
}

export async function installCandidate(input, {root = repository, run = spawnSync} = {}) {
  // All approval/metadata/archive checks precede mkdir and npm execution.
  const accepted = await preflightCandidate(input, root);
  const {destination, artifact, version, sha256, bundleSha256, contractVersion, expectedFiles} = accepted;
  await mkdir(dirname(destination), {recursive: true});
  await mkdir(destination); // Atomic refusal if another invocation claimed this path.
  const npm = resolve(dirname(process.execPath), 'node_modules/npm/bin/npm-cli.js');
  const installed = run(process.execPath, [npm, 'install', '--prefix', destination, '--ignore-scripts', '--no-audit', '--no-fund', artifact], {windowsHide: true, encoding: 'utf8', timeout: 180000, maxBuffer: 4 * 1024 * 1024});
  await writeFile(join(destination, 'install.log'), String(installed.stdout ?? '') + String(installed.stderr ?? ''));
  assert.equal(installed.status, 0, 'Candidate installation failed');
  const packageRoot = await realpath(join(destination, 'node_modules/automated-qa-engine'));
  const files = {};
  async function walk(directory) {
    for (const entry of (await readdir(directory, {withFileTypes: true})).sort((a, b) => a.name.localeCompare(b.name))) {
      assert(!entry.isSymbolicLink(), 'Unexpected package symlink');
      const path = join(directory, entry.name);
      if (entry.isDirectory()) { if (entry.name !== 'node_modules') await walk(path); }
      else files[relative(packageRoot, path).replaceAll('\\', '/')] = digest(await readFile(path));
    }
  }
  await walk(packageRoot);
  assert.deepEqual(files, expectedFiles, 'Installed payload differs from Engine candidate verification');
  const pkg = JSON.parse(await readFile(join(packageRoot, 'package.json')));
  assert.equal(pkg.name, 'automated-qa-engine'); assert.equal(pkg.version, version);
  assert.equal(pkg.bin?.aqa, 'packages/cli/aqa.mjs');
  const bundle = JSON.parse(await readFile(join(packageRoot, `contracts/releases/qa-contract-${version}.json`)));
  assert.equal(bundle.engineVersion, version); assert.equal(bundle.contractVersion, contractVersion);
  const manifest = {packageName: pkg.name, engineVersion: version, artifact, sha256, entrypoint: 'packages/cli/aqa.mjs', controlStdin: true, designChecks: true, appium: true, authoring: true, files};
  const manifestPath = join(destination, 'engine-runtime.json');
  await writeFile(manifestPath, JSON.stringify(manifest, null, 2) + '\n');
  const cli = run(process.execPath, [join(packageRoot, manifest.entrypoint), '--version'], {windowsHide: true, encoding: 'utf8', timeout: 10000, maxBuffer: 1048576});
  assert.equal(cli.status, 0); assert.equal(JSON.parse(cli.stdout).engineVersion, version);
  const receipt = {packageRoot, manifestPath, engineVersion: version, contractVersion, packageSha256: sha256, bundleSha256, packageFiles: Object.keys(files).length, verificationPath: accepted.verificationPath, verificationSha256: accepted.verificationSha256, reportRoot: resolve(root, 'artifacts/engine-refactor', version, sha256), nodePath: process.execPath, defaultPinChanged: false};
  await writeFile(join(destination, 'installation.json'), JSON.stringify(receipt, null, 2) + '\n');
  return receipt;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [artifact, version, sha256, bundleSha256, contractVersion, verificationPath, ...extra] = process.argv.slice(2);
  assert.equal(extra.length, 0, 'Unexpected arguments');
  console.log(JSON.stringify(await installCandidate({artifact, version, sha256, bundleSha256, contractVersion, verificationPath}), null, 2));
}
