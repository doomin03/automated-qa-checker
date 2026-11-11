import { test } from 'node:test';
import assert from 'node:assert/strict';
import { PlatformClient, ApiFailure, ContractFailure, TransportFailure } from '../dist/index.js';
test('platform facade uses generated authorization/routes/schema and keeps HTTP errors', async () => {
  const client = new PlatformClient('http://127.0.0.1', 'local-token', { fetch: async (url, init) => {
    assert.equal(new URL(url).pathname, '/api/v1/me'); assert.equal(new Headers(init.headers).get('Authorization'), 'Bearer local-token');
    return Response.json({ userId: 'tester', localMode: true, projects: [{ id: 'one', name: 'Project', role: 'qa_tester' }], unknownAddition: 1 });
  } });
  assert.equal((await client.me()).projects[0].role, 'qa_tester');
  await assert.rejects(new PlatformClient('http://127.0.0.1', 'token', { fetch: async () => Response.json({ userId: 'tester', projects: [] }) }).me(), ContractFailure);
  const error = { code: 'FORBIDDEN', message: 'Forbidden', requestId: '00000000-0000-4000-8000-000000000000', details: [] };
  await assert.rejects(new PlatformClient('http://127.0.0.1', 'token', { fetch: async () => Response.json(error, { status: 403 }) }).me(), failure => failure instanceof ApiFailure && failure.status === 403);
});
test('platform cancellation covers caller disposal and timeout independently', async () => {
  for (const reason of ['cancelled', 'timeout']) {
    const abort = new AbortController();
    const client = new PlatformClient('http://127.0.0.1', 'token', { timeoutMs: 10, fetch: async (_url, init) => new Promise((_resolve, reject) => {
      init.signal.addEventListener('abort', () => reject(new Error('abort')));
      if (reason === 'cancelled') abort.abort();
    }) });
    await assert.rejects(client.me({ signal: abort.signal }), failure => failure instanceof TransportFailure && failure.reason === reason);
    client.close();
  }
});
