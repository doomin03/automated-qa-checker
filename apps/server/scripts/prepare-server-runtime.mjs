import assert from 'node:assert/strict';
import { readFile, writeFile, mkdir, readdir, realpath, rename, access } from 'node:fs/promises';
import { resolve, join, dirname, relative, isAbsolute } from 'node:path';
import { pathToFileURL } from 'node:url';
import { createHash, randomUUID } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import { root } from './server-runtime.mjs';

const sha = bytes => createHash('sha256').update(bytes).digest('hex');
export async function verifyServerRuntime(packageRoot, pin) {
  const actual = {};
  async function walk(directory) {
    for (const entry of (await readdir(directory, { withFileTypes: true })).sort((a, b) => a.name.localeCompare(b.name))) {
      assert(!entry.isSymbolicLink(), 'Runtime package links are not allowed');
      const file = join(directory, entry.name);
      if (entry.isDirectory()) { if (entry.name !== 'node_modules') await walk(file); }
      else actual[relative(packageRoot, file).replaceAll('\\', '/')] = sha(await readFile(file));
    }
  }
  await walk(packageRoot);
  assert.deepEqual(actual, pin.files, 'Installed package file inventory differs from approved runtime');
  const bundle = await readFile(join(packageRoot, `contracts/releases/qa-contract-${pin.engineVersion}.json`));
  assert.equal(sha(bundle), pin.bundleSha256, 'Execution bundle SHA mismatch');
  assert.equal(JSON.parse(bundle).contractVersion, pin.contractVersion, 'Execution contract version mismatch');
  const cliPath = join(await realpath(packageRoot), pin.entrypoint);
  const version = spawnSync(process.execPath, [cliPath, '--version', '--json'], { encoding: 'utf8', windowsHide: true, timeout: 15000, maxBuffer: 1048576 });
  assert.equal(version.status, 0, 'Runtime CLI probe failed');
  assert.equal(JSON.parse(version.stdout).engineVersion, pin.engineVersion, 'Runtime version mismatch');
  return { cliPath, packageRoot: await realpath(packageRoot), fileCount: Object.keys(actual).length };
}

export async function prepareServerRuntime(archive) {
  assert(isAbsolute(archive ?? ''), 'Pass the absolute approved Engine archive path');
  const manifestPath = join(root, 'packages/contract/runtime/engine-runtime.json');
  const pin = JSON.parse(await readFile(manifestPath));
  assert.equal(sha(await readFile(archive)), pin.sha256, 'Approved archive SHA mismatch');
  const destination = join(root, '.local/engine-server-alpha10');
  const packageRoot = join(destination, 'node_modules/automated-qa-engine');
  let existing = false;
  try { await access(destination); existing = true; } catch (error) { if (error.code !== 'ENOENT') throw error; }
  if (!existing) {
    const stage = `${destination}.stage-${randomUUID()}`;
    await mkdir(stage, { recursive: true });
    const npm = join(dirname(process.execPath), 'node_modules/npm/bin/npm-cli.js');
    const installed = spawnSync(process.execPath, [npm, 'install', '--prefix', stage, '--ignore-scripts', '--no-audit', '--no-fund', archive], { encoding: 'utf8', windowsHide: true, timeout: 180000, maxBuffer: 4 * 1048576 });
    await writeFile(join(stage, 'install.log'), `${installed.stdout ?? ''}${installed.stderr ?? ''}`);
    assert.equal(installed.status, 0, 'Server runtime installation failed; staging directory retained');
    await verifyServerRuntime(join(stage, 'node_modules/automated-qa-engine'), pin);
    // Destination must still be absent: never replace another install or legacy runtime.
    await rename(stage, destination);
  }
  const verified = await verifyServerRuntime(packageRoot, pin);
  const receipt = { ...verified, engineVersion: pin.engineVersion, archiveSha256: pin.sha256, bundleSha256: pin.bundleSha256, manifestSha256: sha(await readFile(manifestPath)), nodePath: process.execPath };
  if (!existing) await writeFile(join(destination, 'installation.json'), JSON.stringify(receipt, null, 2) + '\n', { flag: 'wx' });
  else {
    const previous = JSON.parse(await readFile(join(destination, 'installation.json')));
    for (const key of ['engineVersion', 'archiveSha256', 'bundleSha256', 'manifestSha256']) assert.equal(previous[key], receipt[key], 'Existing receipt pin mismatch');
  }
  return receipt;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  try { console.log(JSON.stringify(await prepareServerRuntime(process.argv[2]), null, 2)); }
  catch (error) { console.error(error.message); process.exitCode = 1; }
}
