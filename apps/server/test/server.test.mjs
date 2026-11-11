import 'reflect-metadata';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { NestFactory } from '@nestjs/core';
import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import { AppModule } from '../dist/src/app.module.js';
import { configureApp, corsOrigins } from '../dist/src/config/configure-app.js';
import { createOpenApi, sortedJson } from '../dist/src/config/openapi.js';
import { exportOpenApi } from '../dist/scripts/export-openapi.js';
import { HealthController } from '../dist/src/modules/health/health.controller.js';
import { HealthService } from '../dist/src/modules/health/health.service.js';
import { FixtureModule } from '../dist/test/fixtures/fixture.module.js';

function validator(document) {
  const ajv = new Ajv({ strict: false }); addFormats(ajv);
  ajv.addSchema({ $id: 'contract', ...document });
  return (name, value) => {
    const check = ajv.compile({ $ref: `contract#/components/schemas/${name}` });
    assert.equal(check(value), true, JSON.stringify(check.errors));
  };
}
async function server(module, run) {
  const log = [];
  const app = await NestFactory.create(module, { logger: false });
  configureApp(app, record => log.push(record));
  try {
    const document = createOpenApi(app);
    await app.listen(0, '127.0.0.1');
    await run(await app.getUrl(), document, log);
  } finally { await app.close(); }
}

test('controller and mapper preserve explicit required nullable client', () => {
  const controller = new HealthController(new HealthService());
  assert.deepEqual(controller.getHealth({}), { status: 'ok', service: 'automated-qa-checker', apiVersion: 'v1', client: null });
});

test('CORS permits only configured exact origins and supports browser preflight', async () => {
  const app = await NestFactory.create(AppModule, { logger: false });
  configureApp(app, () => {}, corsOrigins('http://127.0.0.1:4318'));
  try {
    await app.listen(0, '127.0.0.1');
    const url = `${await app.getUrl()}/api/v1/health`;
    const allowed = await fetch(url, { headers: { Origin: 'http://127.0.0.1:4318' } });
    assert.equal(allowed.headers.get('access-control-allow-origin'), 'http://127.0.0.1:4318');
    assert.equal(allowed.headers.get('access-control-allow-credentials'), null);
    const denied = await fetch(url, { headers: { Origin: 'http://untrusted.example' } });
    assert.equal(denied.headers.get('access-control-allow-origin'), null);
    const options = await fetch(url, { method: 'OPTIONS', headers: { Origin: 'http://127.0.0.1:4318', 'Access-Control-Request-Method': 'GET', 'Access-Control-Request-Headers': 'authorization' } });
    assert.equal(options.status, 204); assert.equal(options.headers.get('access-control-allow-origin'), 'http://127.0.0.1:4318');
    for (const invalid of ['*', 'https://x/path', 'https://user:secret@x']) assert.throws(() => corsOrigins(invalid));
  } finally { await app.close(); }
});

test('real HTTP health/query/errors agree with production OpenAPI and request logs', async () => {
  await server(AppModule, async (origin, document, log) => {
    assert.ok(document.paths['/api/v1/health']);
    assert.equal(Object.keys(document.paths).some(path => path.includes('__fixture')), false);
    assert.equal(document.paths['/api/v1/health'].get.operationId, 'getHealth');
    const valid = validator(document);
    for (const client of [null, 'web', 'app']) {
      const response = await fetch(`${origin}/api/v1/health${client ? '?client=' + client : ''}`);
      assert.equal(response.status, 200); const body = await response.json();
      valid('HealthResponse', body); assert.equal(body.client, client);
    }
    for (const query of ['client=desktop', 'client=', 'client=web&client=app', 'unknown=true', 'client[x]=web']) {
      const response = await fetch(`${origin}/api/v1/health?${query}`);
      assert.equal(response.status, 400, query); const body = await response.json();
      valid('ApiErrorResponse', body); assert.equal(body.code, 'VALIDATION_ERROR');
      assert.ok(body.details.length); assert.equal(body.requestId, response.headers.get('x-request-id'));
      assert.ok(log.some(item => item.requestId === body.requestId && item.status === 400));
    }
    const response = await fetch(`${origin}/api/v1/missing`);
    assert.equal(response.status, 404); const body = await response.json(); valid('ApiErrorResponse', body);
    assert.equal(body.code, 'NOT_FOUND');
    assert.throws(() => valid('HealthResponse', { status: 'ok', service: 'automated-qa-checker', apiVersion: 'v1' }));
  });
});

test('offline export is deterministic and identical to runtime document without listener or credentials', async () => {
  const temp = await mkdtemp(join(tmpdir(), 'qa-openapi-'));
  try {
    await exportOpenApi(join(temp, 'one.json')); await exportOpenApi(join(temp, 'two.json'));
    const one = await readFile(join(temp, 'one.json'), 'utf8');
    assert.equal(one, await readFile(join(temp, 'two.json'), 'utf8'));
    await server(AppModule, async (_origin, document) => assert.equal(one, sortedJson(document)));
    assert.equal(one.includes('__fixture'), false);
  } finally { await rm(temp, { recursive: true, force: true }); }
});

test('fixture module checks body/path/query/nullability/numeric/time/list and sanitized 500', async () => {
  await server(FixtureModule, async (origin, document) => {
    const valid = validator(document);
    const fixture = { label: null, choice: 'one', count: Number.MAX_SAFE_INTEGER, measurement: 0.25, largeId: '9007199254740992', utc: '2026-10-31T00:00:00.000Z', values: ['한글', ''] };
    const post = async (body, query = 'false', id = 'a%2Fb%20%ED%95%9C') => fetch(`${origin}/api/v1/__fixture/${id}?enabled=${query}`, { method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body) });
    const response = await post(fixture); assert.equal(response.status, 201);
    const body = await response.json(); assert.deepEqual(body, fixture); valid('FixtureBody', body);
    const escaped = await post(fixture, 'true'); assert.equal((await escaped.json()).optional, 'a/b 한');
    for (const bad of [{ ...fixture, label: undefined }, { ...fixture, optional: null }, { ...fixture, count: 9007199254740992 }, { ...fixture, measurement: Infinity }, { ...fixture, utc: '2026-10-31T09:00:00+09:00' }, { ...fixture, values: [3] }, { ...fixture, surprise: true }]) {
      assert.equal((await post(bad)).status, 400);
    }
    for (const bad of ['', '1', 'false&enabled=true']) assert.equal((await post(fixture, bad)).status, 400);
    const failure = await fetch(`${origin}/api/v1/__fixture/fail`); assert.equal(failure.status, 500);
    const error = await failure.json(); valid('ApiErrorResponse', error); assert.equal(error.code, 'INTERNAL_ERROR');
    assert.equal(JSON.stringify(error).includes('private-secret'), false);
  });
});
