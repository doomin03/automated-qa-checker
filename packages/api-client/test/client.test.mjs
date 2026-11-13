import { test } from 'node:test';
import assert from 'node:assert/strict';
import { HealthClient, ApiFailure, ContractFailure, TransportFailure, validateModel, apiOrigin, HealthResponseFromJSON, HealthResponseToJSON } from '../dist/index.js';
const fixture = { status: 'ok', service: 'automated-qa-checker', apiVersion: 'v1', client: null };

test('required nullable and enum parser guards preserve null and ignore unknown additions', async () => {
  const client = new HealthClient('http://127.0.0.1', { fetch: async () => Response.json({ ...fixture, future: true }) });
  assert.deepEqual(await client.getHealth(), fixture);
  assert.deepEqual(HealthResponseToJSON(HealthResponseFromJSON(fixture)), fixture);
  for (const bad of [{ ...fixture, client: undefined }, { ...fixture, client: 'desktop' }, { ...fixture, status: null }, null]) {
    assert.throws(() => validateModel('HealthResponse', bad), ContractFailure);
    await assert.rejects(new HealthClient('http://127.0.0.1', { fetch: async () => Response.json(bad) }).getHealth(), ContractFailure);
  }
});

test('HTTP failures retain status/body while timeout and connection have no API status', async () => {
  const error = { code: 'VALIDATION_ERROR', message: 'Request validation failed', requestId: '00000000-0000-4000-8000-000000000000', details: [{ field: 'client', code: 'isIn', message: 'Invalid value' }] };
  await assert.rejects(new HealthClient('http://127.0.0.1', { fetch: async () => Response.json(error, { status: 400 }) }).getHealth(), failure => failure instanceof ApiFailure && failure.status === 400 && failure.body.code === 'VALIDATION_ERROR');
  await assert.rejects(new HealthClient('http://127.0.0.1', { fetch: async () => { throw new TypeError('connect failed'); } }).getHealth(), failure => failure instanceof TransportFailure && failure.reason === 'connection' && !('status' in failure));
  await assert.rejects(new HealthClient('http://127.0.0.1', { timeoutMs: 5, fetch: async (_url, init) => new Promise((_resolve, reject) => init.signal.addEventListener('abort', () => reject(new Error('abort')))) }).getHealth(), failure => failure instanceof TransportFailure && failure.reason === 'timeout' && !('status' in failure));
  await assert.rejects(new HealthClient('http://127.0.0.1', { fetch: async () => new Response('<html>', { status: 500 }) }).getHealth(), ContractFailure);
});

test('origin validation prevents duplicate prefix and query/credential injection', () => {
  assert.equal(apiOrigin('http://127.0.0.1:3000/'), 'http://127.0.0.1:3000');
  for (const bad of ['', 'file:///tmp', 'https://example.com/api/v1', 'https://x?foo=bar', 'https://user:secret@x']) assert.throws(() => apiOrigin(bad));
});

test('caller cancellation composes with the timeout and remains a transport outcome', async () => {
  const abort = new AbortController();
  const client = new HealthClient('http://127.0.0.1', { fetch: async (_url, init) => new Promise((_resolve, reject) => {
    init.signal.addEventListener('abort', () => reject(new Error('abort'))); abort.abort();
  }) });
  await assert.rejects(client.getHealth({}, { signal: abort.signal }), failure => failure instanceof TransportFailure && failure.reason === 'cancelled');
});
