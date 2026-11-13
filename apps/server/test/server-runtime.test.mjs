import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, writeFile, mkdir, readFile } from 'node:fs/promises';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { DatabaseSync } from 'node:sqlite';
import { createHash } from 'node:crypto';
import { runtimePaths, guardRegisteredRuntime } from '../scripts/server-runtime.mjs';
import { verifyServerRuntime, prepareServerRuntime } from '../scripts/prepare-server-runtime.mjs';
const sha = bytes => createHash('sha256').update(bytes).digest('hex');

test('server runtime overrides are paired and previous Agent registrations are checked read-only', async () => {
  assert.match(runtimePaths({}).engineCli, /engine-server-alpha10/);
  assert.throws(() => runtimePaths({ QA_ENGINE_CLI: 'one' }), /together/);
  assert.throws(() => runtimePaths({ QA_ENGINE_MANIFEST: 'one' }), /together/);
  assert.deepEqual(runtimePaths({ QA_ENGINE_CLI: 'one', QA_ENGINE_MANIFEST: 'two' }), { engineCli: 'one', engineManifest: 'two' });
  const dir = await mkdtemp(join(tmpdir(), 'qa-runtime-guard-')), file = join(dir, 'platform.sqlite'), manifest = join(dir, 'runtime.json');
  const db = new DatabaseSync(file);
  db.exec('CREATE TABLE agents(engine_version TEXT,contract_hash TEXT,contract_version TEXT); CREATE TABLE lease_history(payload TEXT); INSERT INTO lease_history VALUES(\'unchanged\')');
  db.prepare('INSERT INTO agents VALUES(?,?,?)').run('old', 'old-hash', 'old-contract'); db.close();
  await writeFile(manifest, JSON.stringify({ engineVersion: 'new', files: { 'contracts/releases/qa-contract-new.json': 'new-hash' } }));
  const before = sha(await readFile(file));
  await assert.rejects(guardRegisteredRuntime(dir, manifest), /separate demo identity/);
  assert.equal(sha(await readFile(file)), before);
  await writeFile(manifest, JSON.stringify({ engineVersion: 'old', files: { 'contracts/releases/qa-contract-old.json': 'old-hash' } }));
  await guardRegisteredRuntime(dir, manifest);
  assert.equal(sha(await readFile(file)), before);
  await writeFile(manifest, JSON.stringify({ engineVersion: 'old', contractVersion: 'wrong-contract', files: { 'contracts/releases/qa-contract-old.json': 'old-hash' } }));
  await assert.rejects(guardRegisteredRuntime(dir, manifest), /separate demo identity/);
  assert.equal(sha(await readFile(file)), before);
});

test('runtime verifier rejects missing, additional and altered package files before CLI trust', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'qa-runtime-files-'));
  await mkdir(join(dir, 'contracts/releases'), { recursive: true });
  const bundle = JSON.stringify({ contractVersion: 'fixture' }), cli = 'console.log(JSON.stringify({engineVersion:"fixture"}));';
  await writeFile(join(dir, 'contracts/releases/qa-contract-fixture.json'), bundle);
  await writeFile(join(dir, 'cli.mjs'), cli);
  const pin = { engineVersion: 'fixture', contractVersion: 'fixture', bundleSha256: sha(bundle), entrypoint: 'cli.mjs', files: { 'cli.mjs': sha(cli), 'contracts/releases/qa-contract-fixture.json': sha(bundle) } };
  assert.equal((await verifyServerRuntime(dir, pin)).fileCount, 2);
  await writeFile(join(dir, 'cli.mjs'), 'throw Error("must not run")');
  await assert.rejects(verifyServerRuntime(dir, pin), /inventory/);
  await writeFile(join(dir, 'cli.mjs'), cli);
  await writeFile(join(dir, 'unexpected.txt'), 'extra');
  await assert.rejects(verifyServerRuntime(dir, pin), /inventory/);
  const wrong = join(dir, 'untrusted.tgz'); await writeFile(wrong, 'wrong archive');
  await assert.rejects(prepareServerRuntime(wrong), /archive SHA/);
});
