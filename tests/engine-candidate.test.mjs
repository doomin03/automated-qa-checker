import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp, mkdir, readFile, writeFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {basename, dirname, join, resolve} from 'node:path';
import {createHash} from 'node:crypto';
import {installCandidate, preflightCandidate} from '../scripts/engine-candidate.mjs';
test('candidate approval checks precede npm, directory creation and any replacement', async t => {
  const root = await mkdtemp(join(tmpdir(), 'checker-candidate-preflight-'));
  t.after(async () => {
    assert.equal(dirname(resolve(root)), resolve(tmpdir()));
    assert(basename(root).startsWith('checker-candidate-preflight-'));
    await rm(root, {recursive: true, force: true});
  });
  const artifact = join(root, 'fixture.tgz'), verificationPath = join(root, 'verification.json');
  const bytes = Buffer.from('inert test bytes, never installed');
  const sha256 = createHash('sha256').update(bytes).digest('hex'), bundleSha256 = 'a'.repeat(64);
  const input = {artifact, verificationPath, version: '0.1.0-alpha.8', contractVersion: '0.3.0-draft.2', sha256, bundleSha256};
  const verification = {status: 'passed', engineVersion: input.version, contractVersion: input.contractVersion, sha256, bundle: {engineVersion: input.version, contractVersion: input.contractVersion, sha256: bundleSha256}, installedFiles: ['package.json', 'packages/cli/aqa.mjs', 'contracts/schemas/qa.schema.json', `contracts/releases/qa-contract-${input.version}.json`].map(path => ({path, sha256: bundleSha256}))};
  await writeFile(artifact, bytes); await writeFile(verificationPath, JSON.stringify(verification));
  const accepted = await preflightCandidate(input, root);
  assert.equal(Object.keys(accepted.expectedFiles).length, 4);
  let spawnCalls = 0;
  const run = () => { spawnCalls++; throw Error('npm must not start'); };
  for (const patch of [{version: '0.1.0-alpha.9'}, {version: '../escape'}, {sha256: 'b'.repeat(64)}, {bundleSha256: 'b'.repeat(64)}, {contractVersion: 'bad'}, {artifact: 'relative.tgz'}]) {
    await assert.rejects(installCandidate({...input, ...patch}, {root, run}));
  }
  await writeFile(artifact, 'tampered');
  await assert.rejects(installCandidate(input, {root, run}), /Archive bytes mismatch/);
  await writeFile(artifact, bytes);
  await writeFile(verificationPath, JSON.stringify({...verification, installedFiles: [...verification.installedFiles, verification.installedFiles[0]]}));
  await assert.rejects(installCandidate(input, {root, run}), /Duplicate/);
  await writeFile(verificationPath, JSON.stringify(verification));
  await mkdir(accepted.destination, {recursive: true});
  const sentinel = join(accepted.destination, 'preserve.txt'); await writeFile(sentinel, 'keep');
  await assert.rejects(installCandidate(input, {root, run}), /overwrite/);
  assert.equal(await readFile(sentinel, 'utf8'), 'keep');
  assert.equal(spawnCalls, 0);
});
