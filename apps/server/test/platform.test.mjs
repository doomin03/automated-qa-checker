import 'reflect-metadata';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, rm, mkdir, readdir } from 'node:fs/promises';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { tmpdir } from 'node:os';
import { execFileSync } from 'node:child_process';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../dist/src/app.module.js';
import { configureApp } from '../dist/src/config/configure-app.js';
import { PlatformService } from '../dist/src/modules/platform/platform.service.js';
import { PlatformRepository, sha256 } from '../dist/src/modules/platform/platform.repository.js';
import { EngineContractService, parseBounded } from '../dist/src/modules/platform/engine-contract.service.js';
import { platformConfig } from '../dist/src/modules/platform/platform.config.js';

const root = fileURLToPath(new URL('../../../', import.meta.url));
const cli = resolve(root, '.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs');
const manifest = resolve(root, 'apps/app/assets/engine-runtime.json');
const tokens = Object.fromEntries(['author', 'reviewer', 'tester', 'viewer', 'outsider'].map(id => [id, `${id}-local-test-token-with-32-characters`]));
const identities = {
  users: Object.entries(tokens).map(([id, token]) => ({ id, token, active: true })),
  projects: [{ id: 'project-a', name: 'QA Project' }, { id: 'project-b', name: 'Other Project' }],
  memberships: [{ userId: 'author', projectId: 'project-a', role: 'qa_manager' }, { userId: 'reviewer', projectId: 'project-a', role: 'qa_manager' }, { userId: 'tester', projectId: 'project-a', role: 'qa_tester' }, { userId: 'viewer', projectId: 'project-a', role: 'viewer' }, { userId: 'outsider', projectId: 'project-b', role: 'qa_manager' }],
};

async function start(config) {
  const app = await NestFactory.create(AppModule, { logger: false });
  configureApp(app, () => {});
  try { await app.get(PlatformService).start(config); await app.listen(0, '127.0.0.1'); }
  catch (error) { await app.close(); throw error; }
  const origin = await app.getUrl();
  const request = async (path, options = {}) => {
    const { user = 'author', body, key, method = body ? 'POST' : 'GET' } = options;
    const response = await fetch(origin + '/api/v1' + path, { method, headers: { ...(user ? { authorization: `Bearer ${tokens[user]}` } : {}), ...(body ? { 'content-type': 'application/json' } : {}), ...(key ? { 'Idempotency-Key': key } : {}) }, ...(body ? { body: JSON.stringify(body) } : {}) });
    return { status: response.status, body: await response.json() };
  };
  return { app, request, origin, repo: app.get(PlatformRepository), engine: app.get(EngineContractService) };
}

test('local authentication config fails closed outside explicit loopback development/test', () => {
  const env = { QA_AUTH_MODE: 'local', NODE_ENV: 'development', HOST: '127.0.0.1', QA_DATA_DIR: resolve(root, '.local/data'), QA_ENGINE_CLI: cli, QA_ENGINE_MANIFEST: manifest, QA_LOCAL_IDENTITIES_JSON: JSON.stringify(identities) };
  assert.equal(platformConfig(env).mode, 'local');
  for (const patch of [{ NODE_ENV: 'production' }, { NODE_ENV: '' }, { HOST: '0.0.0.0' }, { QA_AUTH_MODE: 'fake' }, { QA_ENGINE_MANIFEST: 'relative.json' }]) assert.throws(() => platformConfig({ ...env, ...patch }));
  assert.throws(() => parseBounded(JSON.stringify({ x: { constructor: {} } })));
  let deep = {}; for (let i = 0; i < 42; i++) deep = { nested: deep }; assert.throws(() => parseBounded(JSON.stringify(deep)));
});

test('durable Registry/identity/events/evidence enforce project scope and transactional invariants', { timeout: 120000 }, async t => {
  const dataDir = await mkdtemp(join(tmpdir(), 'qa-platform-'));
  const config = { mode: 'test', dataDir, identities, engineCli: cli, engineManifest: manifest };
  let server = await start(config);
  const xml = execFileSync(process.execPath, [cli, 'template', '--format', 'xml'], { encoding: 'utf8', windowsHide: true });
  const project = '/projects/project-a';
  const request = (...args) => server.request(...args);
  let version; let run; let result; let terminal; let plan;
  const png = Buffer.from('89504e470d0a1a0a00000000', 'hex');
  const reportBytes = Buffer.from(JSON.stringify({ schemaVersion: 'qa.checkReport/v1', nodeId: 'start', kind: 'image', verdict: 'passed', reason: 'MATCH', artifactRefs: [{ role: 'actual', path: 'proof.png' }] }));
  try {
    await t.test('registered identity and project roles are enforced; tokens are hashed', async () => {
      assert.equal((await request('/me', { user: null })).status, 401);
      const me = await request('/me'); assert.equal(me.body.localMode, true); assert.equal(me.body.projects[0].id, 'project-a');
      assert.equal((await request(`${project}/registry/versions`, { user: 'outsider' })).status, 403);
      assert.equal((await request(`${project}/registry/drafts`, { user: 'viewer', body: { packageId: 'demo', title: 'Demo', xml, dependencies: [] } })).status, 403);
      assert.equal(server.repo.get('SELECT token_hash FROM users WHERE id=?', 'author').token_hash, sha256(tokens.author));
      server.repo.exec('UPDATE users SET active=0 WHERE id=?', 'viewer'); assert.equal((await request('/me', { user: 'viewer' })).status, 401);
      server.repo.exec('UPDATE users SET active=1 WHERE id=?', 'viewer');
    });
    await t.test('public CLI validation, independent review, immutable idempotent concurrent publication', async () => {
      const invalid = await request(`${project}/registry/drafts`, { body: { packageId: 'demo', title: 'Bad', xml: '<unknown/>', dependencies: [] } }); assert.equal(invalid.status, 400);
      const created = await request(`${project}/registry/drafts`, { body: { packageId: 'demo', title: 'Demo', xml, dependencies: [] } }); assert.equal(created.status, 201, JSON.stringify(created));
      const draft = created.body;
      assert.equal((await request(`${project}/registry/drafts/${draft.id}/review`, { method: 'POST' })).status, 403);
      assert.equal((await request(`${project}/registry/drafts/${draft.id}/publish`, { body: { version: '1.0.0' }, key: 'unreviewed' })).status, 409);
      assert.equal((await request(`${project}/registry/drafts/${draft.id}/review`, { method: 'POST', user: 'reviewer' })).status, 200);
      const publish = () => request(`${project}/registry/drafts/${draft.id}/publish`, { body: { version: '1.0.0' }, key: 'publish-1' });
      const [first, retry] = await Promise.all([publish(), publish()]); assert.equal(first.status, 201, JSON.stringify(first)); assert.deepEqual(first.body, retry.body); version = first.body;
      assert.equal(version.sha256, sha256(xml));
      assert.equal((await request(`${project}/registry/drafts/${draft.id}/publish`, { body: { version: '2.0.0' }, key: 'publish-1' })).status, 409);
      assert.throws(() => server.repo.exec('UPDATE versions SET xml=? WHERE id=?', '<tamper/>', version.id), /Immutable/);
      const second = await request(`${project}/registry/drafts`, { body: { packageId: 'demo', title: 'Next', xml, dependencies: [{ versionId: version.id, sha256: version.sha256 }] } });
      await request(`${project}/registry/drafts/${second.body.id}/review`, { method: 'POST', user: 'reviewer' });
      assert.equal((await request(`${project}/registry/drafts/${second.body.id}/publish`, { body: { version: '1.0.0' }, key: 'collision' })).status, 409);
      const next = await request(`${project}/registry/drafts/${second.body.id}/publish`, { body: { version: '1.1.0' }, key: 'publish-2' }); assert.equal(next.status, 201);
      const page = await request(`${project}/registry/versions?limit=1`); assert.equal(page.body.items.length, 1); assert.ok(page.body.nextCursor);
      assert.equal((await request(`${project}/registry/versions?limit=1&cursor=${page.body.nextCursor}`)).body.items[0].id, next.body.id);
      const diff = await request(`${project}/registry/upgrade-diff?fromVersionId=${version.id}&toVersionId=${next.body.id}`); assert.equal(diff.body.dependenciesChanged, true);
      assert.equal((await request(`${project}/registry/pins`, { user: 'tester', method: 'PUT', body: { versionId: version.id, sha256: version.sha256 } })).status, 200);
      assert.equal((await request(`${project}/audit`)).body.items.some(a => a.action === 'version.published'), true);
    });
    await t.test('Engine start/blueprint is fixed; batch replay is atomic and rejects conflicts/gaps/late events', async () => {
      plan = await server.engine.plan(xml);
      const event = { schemaVersion: 'qa.runEvent/v1', runId: 'shared-run-1', attempt: 1, sequence: 1, type: 'run.started', timestamp: '2026-10-31T00:00:00.000Z', blueprintSnapshotHash: plan.blueprintSnapshotHash };
      const body = { engineRunId: event.runId, attempt: 1, snapshotHash: plan.blueprintSnapshotHash, engineVersion: plan.engineVersion, blueprintJson: JSON.stringify(plan.blueprint), startedEventJson: JSON.stringify(event), versionId: version.id };
      const created = await request(`${project}/runs`, { user: 'tester', body, key: 'run-1' }); assert.equal(created.status, 201, JSON.stringify(created)); run = created.body;
      assert.equal((await request(`${project}/runs`, { user: 'tester', body, key: 'run-1' })).body.id, run.id);
      assert.equal((await request(`${project}/runs`, { user: 'tester', body: { ...body, snapshotHash: 'sha256:' + '0'.repeat(64) }, key: 'run-bad' })).status, 409);
      const stepStart = { ...event, sequence: 2, type: 'step.started', nodeId: 'start' };
      const append = (events, user = 'tester') => request(`${project}/runs/${run.id}/events`, { user, body: { eventsJson: events.map(e => JSON.stringify(e)) } });
      assert.deepEqual(JSON.parse(run.blueprintJson), plan.blueprint);
      assert.equal((await request(`${project}/runs`, { user: 'tester', body: { ...body, blueprintJson: JSON.stringify({ schemaVersion: 'qa.testcase/v1', flowRef: '//untrusted/flow.xml' }) }, key: 'not-blueprint' })).status, 400);
      assert.equal((await append([{ ...stepStart, nodeId: 'unknownNode' }])).status, 409);
      assert.equal((await append([{ ...stepStart, type: 'step.finished', outcome: 'passed' }])).status, 409);
      assert.equal((await append([stepStart, { ...stepStart, sequence: 3 }])).status, 409);
      assert.equal((await append([stepStart, { ...stepStart, type: 'run.finished', sequence: 3, outcome: 'passed' }])).status, 409);
      assert.equal((await append([stepStart, { ...stepStart, type: 'step.retrying', sequence: 3, failure: { code: 'ASSERTION_FAILED', message: 'Retry', phase: 'step' } }])).status, 409);
      assert.equal((await append([event])).status, 200);
      assert.equal((await append([{ ...event, schemaVersion: 'qa.runEvent/unknown' }])).status, 400);
      assert.equal((await append([{ ...event, timestamp: 'different' }])).status, 409);
      const step = { schemaVersion: 'qa.runEvent/v1', runId: event.runId, attempt: 1, sequence: 3, type: 'step.finished', timestamp: event.timestamp, nodeId: 'start', outcome: 'passed' };
      terminal = { schemaVersion: 'qa.runEvent/v1', runId: event.runId, attempt: 1, sequence: 4, type: 'run.finished', timestamp: event.timestamp, outcome: 'passed', resultPath: 'result.json' };
      assert.equal((await append([{ ...step, sequence: 3 }])).status, 409);
      assert.equal((await append([stepStart, step, { ...terminal, sequence: 5 }])).status, 409);
      assert.equal((await request(`${project}/runs/${run.id}`)).body.lastSequence, 1);
      assert.equal((await append([step], 'author')).status, 403);
      assert.equal((await append([stepStart, step, terminal])).status, 200);
      assert.equal((await append([stepStart, step, terminal])).status, 200);
      assert.equal((await append([{ ...step, sequence: 4 }])).status, 409);
      const replay = await request(`${project}/runs/${run.id}/events?afterSequence=1&limit=1`, { user: 'viewer' }); assert.equal(replay.body.nextSequence, 2); assert.equal(replay.body.hasMore, true);
      assert.equal((await request(`${project}/runs/${run.id}/events?afterSequence=100`)).status, 409);
      assert.equal((await request(`/projects/project-b/runs/${run.id}`, { user: 'outsider' })).status, 404);
      result = { schemaVersion: 'qa.result/v1', runId: event.runId, attempt: 1, status: 'finished', outcome: 'passed', startedAt: event.timestamp, finishedAt: event.timestamp, artifacts: [{ type: 'screenshot', path: 'proof.png', contentType: 'image/png', sha256: sha256(png), size: png.length }], executed: { engineVersion: plan.engineVersion, platform: 'web', flowSnapshotHash: plan.flowSnapshotHash, blueprintSnapshotHash: plan.blueprintSnapshotHash }, visitedNodes: ['start'], unvisitedNodes: plan.nodeOrder.filter(n => n !== 'start'), cleanupErrors: [] };
      assert.equal((await request(`${project}/runs/${run.id}/result`, { user: 'tester', method: 'PUT', body: { resultJson: JSON.stringify({ ...result, visitedNodes: ['start', 'open'] }) } })).status, 409);
      const extra = result.unvisitedNodes[0];
      assert.equal((await request(`${project}/runs/${run.id}/result`, { user: 'tester', method: 'PUT', body: { resultJson: JSON.stringify({ ...result, visitedNodes: ['start', extra], unvisitedNodes: result.unvisitedNodes.filter(n => n !== extra) }) } })).status, 409);
      assert.equal((await request(`${project}/runs/${run.id}/result`, { user: 'tester', method: 'PUT', body: { resultJson: JSON.stringify({ ...result, status: 'cancelled' }) } })).status, 409);
      assert.equal((await request(`${project}/runs/${run.id}/result`, { user: 'tester', method: 'PUT', body: { resultJson: JSON.stringify({ ...result, artifacts: [{ ...result.artifacts[0], size: 10485761 }] }) } })).status, 400);
      assert.equal((await request(`${project}/runs/${run.id}/result`, { user: 'tester', method: 'PUT', body: { resultJson: JSON.stringify({ ...result, artifacts: Array.from({ length: 7 }, (_, i) => ({ ...result.artifacts[0], path: `proof${i}.png`, size: 10485760 })) }) } })).status, 400);
      result.artifacts.push({ type: 'check-report', path: 'zreport.json', contentType: 'application/json', sha256: sha256(reportBytes), size: reportBytes.length });
      const accepted = await request(`${project}/runs/${run.id}/result`, { user: 'tester', method: 'PUT', body: { resultJson: JSON.stringify(result) } }); assert.equal(accepted.status, 200, JSON.stringify(accepted)); run = accepted.body;
      assert.equal(run.reportedOutcome, 'passed'); assert.equal(run.evidenceStatus, 'missing'); assert.equal(run.workStatus, 'todo');
    });
    await t.test('artifact uploads validate bytes and recover interrupted staging without changing outcome', async () => {
      const artifact = run.artifacts[0]; const path = `${project}/runs/${run.id}/artifacts`;
      const body = { artifactId: artifact.artifactId, sha256: artifact.sha256, mimeType: artifact.mimeType, base64: png.toString('base64') };
      assert.equal((await request(path, { user: 'tester', method: 'PUT', body: { ...body, base64: Buffer.from('tampered').toString('base64') } })).status, 400);
      assert.equal((await request(path, { user: 'author', method: 'PUT', body })).status, 403);
      const finalPath = join(dataDir, 'artifacts', artifact.artifactId);
      await mkdir(finalPath);
      assert.equal((await request(path, { user: 'tester', method: 'PUT', body })).status, 500);
      assert.equal((await readdir(join(dataDir, 'artifacts'))).some(name => name.startsWith('upload-')), false);
      await rm(finalPath, { recursive: true });
      assert.equal((await request(path, { user: 'tester', method: 'PUT', body })).status, 200);
      assert.equal((await request(path, { user: 'tester', method: 'PUT', body })).status, 200);
      assert.equal((await request(`${project}/runs/${run.id}`)).body.evidenceStatus, 'missing');
      const report = run.artifacts.find(a => a.name === 'zreport.json');
      assert.equal((await request(path, { user: 'tester', method: 'PUT', body: { artifactId: report.artifactId, sha256: report.sha256, mimeType: report.mimeType, base64: reportBytes.toString('base64') } })).status, 200);
      assert.equal((await request(`${project}/runs/${run.id}`)).body.evidenceStatus, 'verified');
      const downloaded = await request(`${path}/${artifact.artifactId}`, { user: 'viewer' }); assert.equal(downloaded.body.base64, png.toString('base64'));
      await writeFile(finalPath, 'tampered'); assert.equal((await request(`${project}/runs/${run.id}`)).body.evidenceStatus, 'missing');
      await request(path, { user: 'tester', method: 'PUT', body });
      await writeFile(join(dataDir, 'artifacts', 'upload-11111111-1111-4111-8111-111111111111.tmp'), 'incomplete');
    });
    await t.test('retry events follow the public Engine sequence and reject excess retries', async () => {
      const blueprint = structuredClone(plan.blueprint); blueprint.flow.nodes.find(n => n.id === 'start').retry = { maxRetries: 1 };
      const retryPlan = await server.engine.plan(JSON.stringify(blueprint), 'json');
      const event = { schemaVersion: 'qa.runEvent/v1', runId: 'retry-run', attempt: 1, sequence: 1, type: 'run.started', timestamp: '2026-10-31T00:00:00.000Z', blueprintSnapshotHash: retryPlan.blueprintSnapshotHash };
      const created = await request(`${project}/runs`, { user: 'tester', key: 'retry-run', body: { blueprintJson: JSON.stringify(retryPlan.blueprint), engineRunId: event.runId, attempt: 1, snapshotHash: retryPlan.blueprintSnapshotHash, engineVersion: retryPlan.engineVersion, startedEventJson: JSON.stringify(event) } });
      assert.equal(created.status, 201);
      const start = { ...event, sequence: 2, type: 'step.started', nodeId: 'start' };
      const retry = { ...start, sequence: 3, type: 'step.retrying', failure: { code: 'ASSERTION_FAILED', message: 'Retryable assertion', phase: 'step' } };
      const append = events => request(`${project}/runs/${created.body.id}/events`, { user: 'tester', body: { eventsJson: events.map(e => JSON.stringify(e)) } });
      assert.equal((await append([start, retry, { ...retry, sequence: 4 }])).status, 409);
      assert.equal((await append([start, retry, { ...start, sequence: 4 }])).status, 409);
      assert.equal((await append([start, { ...retry, failure: { ...retry.failure, code: 'SESSION_ERROR' } }])).status, 409);
      const finish = { ...start, sequence: 4, type: 'step.finished', outcome: 'passed' };
      assert.equal((await append([start, retry, finish])).status, 200);
      assert.equal((await append([{ ...start, sequence: 5 }])).status, 409);
      assert.equal((await append([{ ...event, sequence: 5, type: 'run.finished', outcome: 'passed', resultPath: 'result.json' }])).status, 200);
    });
    await t.test('optional screenshot skipped is a completed step, never a terminal run outcome', async () => {
      const blueprint = structuredClone(plan.blueprint);
      blueprint.flow.nodes.find(node => node.id === 'capture').params = { required: false };
      const snapshot = await server.engine.plan(JSON.stringify(blueprint), 'json');
      const started = { schemaVersion: 'qa.runEvent/v1', runId: 'optional-screenshot-run', attempt: 1, sequence: 1, type: 'run.started', timestamp: '2026-10-31T00:00:00.000Z', blueprintSnapshotHash: snapshot.blueprintSnapshotHash };
      const created = await request(`${project}/runs`, { user: 'tester', key: started.runId, body: { blueprintJson: JSON.stringify(snapshot.blueprint), engineRunId: started.runId, attempt: 1, snapshotHash: snapshot.blueprintSnapshotHash, engineVersion: snapshot.engineVersion, startedEventJson: JSON.stringify(started) } });
      assert.equal(created.status, 201, JSON.stringify(created));
      const append = events => request(`${project}/runs/${created.body.id}/events`, { user: 'tester', body: { eventsJson: events.map(e => JSON.stringify(e)) } });
      const step = { ...started, sequence: 2, type: 'step.started', nodeId: 'capture' };
      const skipped = { ...step, sequence: 3, type: 'step.finished', outcome: 'skipped', failure: { code: 'SCREENSHOT_FAILED', message: 'Optional screenshot fixture', phase: 'step' }, artifacts: [] };
      assert.equal((await append([step, skipped])).status, 200);
      assert.equal((await append([{ ...started, sequence: 4, type: 'run.finished', outcome: 'skipped', resultPath: 'result.json' }])).status, 400);
      assert.equal((await append([{ ...started, sequence: 4, type: 'run.finished', outcome: 'passed', resultPath: 'result.json' }])).status, 200);
    });
    await t.test('restart preserves versions/pins/events/results; deletion revokes identity and membership', async () => {
      await server.app.close(); server = await start(config);
      assert.equal((await request(`${project}/registry/versions/${version.id}`, { user: 'viewer' })).body.sha256, version.sha256);
      assert.equal((await request(`${project}/registry/pins`, { user: 'tester' })).body.items[0].versionId, version.id);
      const stored = await request(`${project}/runs/${run.id}`); assert.equal(stored.body.lastSequence, 4); assert.equal(stored.body.evidenceStatus, 'verified');
      assert.equal((await request(`${project}/runs/${run.id}/events?afterSequence=3`)).body.eventsJson.length, 1);
      assert.equal((await readdir(join(dataDir, 'artifacts'))).some(name => name.startsWith('upload-')), false);
      server.repo.exec('DELETE FROM users WHERE id=?', 'viewer'); assert.equal((await request('/me', { user: 'viewer' })).status, 401);
      assert.equal((await request(`${project}/registry/versions?limit=1&limit=2`)).status, 400);
      const tooLarge = await fetch(server.origin + '/api/v1' + project + '/runs/' + run.id + '/artifacts', { method: 'PUT', headers: { authorization: `Bearer ${tokens.tester}`, 'content-type': 'application/json' }, body: JSON.stringify({ huge: 'x'.repeat(16 * 1024 * 1024 + 1) }) });
      assert.equal(tooLarge.status, 413); assert.equal((await tooLarge.json()).code, 'PAYLOAD_TOO_LARGE');
    });
  } finally {
    await server.app.close();
    if (dirname(resolve(dataDir)) !== resolve(tmpdir()) || !dataDir.split(/[\\/]/).at(-1).startsWith('qa-platform-')) throw new Error('Unexpected test data path');
    await rm(dataDir, { recursive: true, force: true });
  }
});
