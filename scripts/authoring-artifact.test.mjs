import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp, mkdir, writeFile, rm} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
import {createHash} from 'node:crypto';
import {readAuthoringArtifact} from './lib/authoring-artifact.mjs';

test('public alpha9/alpha10 metadata, pin/manifest mismatch and unsafe paths', async () => {
  const root = await mkdtemp(join(tmpdir(), 'qa-authoring-metadata-'));
  try {
    await mkdir(join(root, 'contracts/releases'), {recursive: true});
    const bytes = Buffer.from('{"schemaVersion":"qa.authoringContract/v1"}');
    const hash = createHash('sha256').update(bytes).digest('hex');
    for (const name of ['qa-authoring-0.1.0-draft.1.json', 'qa-authoring-0.1.0-draft.1-engine-0.1.0-alpha.10.json']) {
      await writeFile(join(root, 'contracts/releases', name), bytes);
      await writeFile(join(root, 'contracts/authoring-release.json'), JSON.stringify({artifact:name,sha256:hash}));
      const files = {[`contracts/releases/${name}`]:hash};
      assert.deepEqual(await readAuthoringArtifact(root,{authoringBundleSha256:hash},files),bytes);
      await assert.rejects(readAuthoringArtifact(root,{authoringBundleSha256:'0'.repeat(64)},files),/pin mismatch/);
      await assert.rejects(readAuthoringArtifact(root,{authoringBundleSha256:hash},{}),/manifest mismatch/);
    }
    for (const artifact of ['../escape.json','/absolute.json','C:/escape.json','\\\\host\\share','a//b','a/./b']) {
      await writeFile(join(root,'contracts/authoring-release.json'),JSON.stringify({artifact,sha256:hash}));
      await assert.rejects(readAuthoringArtifact(root,{authoringBundleSha256:hash},{}),/Unsafe/);
    }
  } finally { await rm(root,{recursive:true,force:true}); }
});
