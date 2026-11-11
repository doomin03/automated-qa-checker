import { readFile } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import assert from 'node:assert/strict';
import { Ajv } from 'ajv';
import { lintDocument } from '../generator/contract-tools.mjs';
const directory = new URL('./v0.1.0-draft.1/', import.meta.url);
const bytes = await readFile(new URL('openapi.json', directory));
const document = JSON.parse(bytes); lintDocument(document);
const expected = '8c25e3c853f3b8d24003464d2ddc55a20675b7ac3f741a46c238a50ce4149490';
assert.equal(createHash('sha256').update(bytes).digest('hex'), expected, 'Reviewed HTTP baseline changed');
function schema(value) {
  if (Array.isArray(value)) return value.map(schema);
  if (!value || typeof value !== 'object') return value;
  const copy = Object.fromEntries(Object.entries(value).filter(([key]) => key !== 'nullable').map(([key, child]) => [key, schema(child)]));
  return value.nullable ? { anyOf: [copy, { type: 'null' }] } : copy;
}
const ajv = new Ajv({ strict: false, allErrors: true });
ajv.addFormat('uuid', /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
ajv.addFormat('date-time', value => /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d\.\d{3}Z$/.test(value) && Number.isFinite(Date.parse(value)));
ajv.addFormat('byte', { type: 'string', validate: value => Buffer.from(value, 'base64').toString('base64') === value });
ajv.addSchema({ $id: 'agent-http', components: { schemas: schema(document.components.schemas) } });
const mappings = { 'claim-request': 'ClaimRequest', 'claim-response': 'ClaimResponse', 'events-request': 'EventsRequest', 'preflight-blocked-complete': 'CompleteRequest', 'reconcile-response': 'ReconcileResponse', 'historical-evidence-request': 'HistoricalEvidenceRequest', 'instance-release-request': 'InstanceReleaseRequest', 'forbidden-response': 'ApiErrorResponse' };
const fixtures = {};
for (const [name, model] of Object.entries(mappings)) {
  const value = JSON.parse(await readFile(new URL(`examples/${name}.json`, directory)));
  const validate = ajv.getSchema(`agent-http#/components/schemas/${model}`);
  assert.ok(validate(value), `${name}: ${JSON.stringify(validate.errors)}`); fixtures[name] = value;
}
const claim = ajv.getSchema('agent-http#/components/schemas/ClaimRequest');
assert.equal(claim({ ...fixtures['claim-request'], unexpected: true }), false);
const missing = structuredClone(fixtures['claim-response']); delete missing.lease.executionPolicy.allowProduction;
assert.equal(ajv.getSchema('agent-http#/components/schemas/ClaimResponse')(missing), false);
const release = structuredClone(fixtures['instance-release-request']); release.receipts[0].acceptedThrough = -1;
assert.equal(ajv.getSchema('agent-http#/components/schemas/InstanceReleaseRequest')(release), false);
const resource = ajv.getSchema('agent-http#/components/schemas/ResourceManifest');
const recovered = structuredClone(fixtures['reconcile-response']);
recovered.decisions[0].lease.state = 'recovered'; recovered.decisions[0].directive = 'observe';
recovered.decisions[0].operatorRecovery = { id: '99999999-9999-4999-8999-999999999999', confirmedAt: '2026-10-31T00:00:00.000Z', priorFence: 1, newFence: 2 };
assert.equal(ajv.getSchema('agent-http#/components/schemas/ReconcileResponse')(recovered), true);
const common = { resourceId: '88888888-8888-4888-8888-888888888888', sha256: 'a'.repeat(64), size: 100, mimeType: 'font/woff2' };
assert.equal(resource({ ...common, name: 'fonts/local.woff2' }), true);
for (const name of ['../secret.woff2', '/etc/a.woff2', 'C:/secret.woff2', '//host/file.woff2', 'fonts\\x.woff2']) assert.equal(resource({ ...common, name }), false);
console.log(`Reviewed Agent HTTP draft: ${Object.keys(mappings).length} fixtures and rejection cases passed; SHA256 ${expected}`);
