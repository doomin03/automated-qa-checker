import assert from 'node:assert/strict';
import { HealthClient, ApiFailure, TransportFailure } from '../dist/index.js';
if (!process.env.QA_TEST_ORIGIN) throw new Error('QA_TEST_ORIGIN required; use contract integration runner');
const client = new HealthClient(process.env.QA_TEST_ORIGIN);
for (const value of [undefined, 'web', 'app']) {
  const response = await client.getHealth({ client: value });
  assert.equal(response.client, value ?? null); assert.equal(response.status, 'ok');
}
await assert.rejects(client.getHealth({ client: 'desktop' }), error => error instanceof ApiFailure && error.status === 400 && error.body.code === 'VALIDATION_ERROR');
await assert.rejects(new HealthClient('http://127.0.0.1:1').getHealth(), TransportFailure);
console.log('TS generated SDK + adapter: same Nest server health null/web/app, HTTP400, unreachable passed');
