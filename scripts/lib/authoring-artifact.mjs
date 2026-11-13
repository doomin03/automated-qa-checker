import assert from 'node:assert/strict';
import {readFile, realpath} from 'node:fs/promises';
import {resolve, relative, isAbsolute} from 'node:path';
import {createHash} from 'node:crypto';

export async function readAuthoringArtifact(packageRoot, pin, files) {
  const metadata = JSON.parse(await readFile(resolve(packageRoot, 'contracts/authoring-release.json')));
  const name = metadata.artifact;
  assert(typeof name === 'string' && name.length > 0 && !isAbsolute(name) &&
    !name.includes('\\') && !name.includes(':') &&
    name.split('/').every(p => p !== '' && p !== '.' && p !== '..'), 'Unsafe authoring artifact path');
  const root = await realpath(packageRoot);
  const artifactPath = `contracts/releases/${name}`;
  const path = await realpath(resolve(root, artifactPath));
  const rel = relative(root, path);
  assert(rel && !rel.startsWith('..') && !isAbsolute(rel), 'Authoring artifact escapes package');
  const bytes = await readFile(path);
  const hash = createHash('sha256').update(bytes).digest('hex');
  assert.equal(hash, pin.authoringBundleSha256, 'Authoring pin mismatch');
  assert.equal(hash, metadata.sha256, 'Authoring metadata mismatch');
  assert.equal(hash, files[artifactPath], 'Authoring manifest mismatch');
  return bytes;
}
