import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { lintDocument, differences } from './contract-tools.mjs';

test('contract lint rejects duplicated operations and unresolved refs', async () => {
  const source = JSON.parse(await readFile(new URL('../openapi.json', import.meta.url)));
  lintDocument(source);
  const duplicate = structuredClone(source); duplicate.paths['/another'] = structuredClone(duplicate.paths['/api/v1/health']);
  assert.throws(() => lintDocument(duplicate), /duplicate/);
  const broken = structuredClone(source); broken.components.schemas.HealthResponse.properties.extra = { $ref: '#/components/schemas/Missing' };
  assert.throws(() => lintDocument(broken), /Broken ref/);
});

test('drift comparison includes edited, missing, added/untracked and empty generated output without mutation', () => {
  const expected = new Map([['a', Buffer.from('one')], ['b', Buffer.from('two')]]);
  assert.deepEqual(differences(expected, new Map(expected)), []);
  assert.deepEqual(differences(expected, new Map([['a', Buffer.from('edit')], ['untracked', Buffer.from('new')]])), ['a', 'b', 'untracked']);
  assert.deepEqual(differences(expected, new Map()), ['a', 'b']);
  assert.deepEqual([...expected].map(([path, bytes]) => [path, bytes.toString()]), [['a', 'one'], ['b', 'two']]);
});
