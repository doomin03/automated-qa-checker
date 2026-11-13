import 'reflect-metadata';
import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { randomBytes, createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../dist/src/app.module.js';
import { PlatformRepository } from '../dist/src/modules/platform/platform.repository.js';
import { PlatformService } from '../dist/src/modules/platform/platform.service.js';
import { platformConfig } from '../dist/src/modules/platform/platform.config.js';
import { AuthRepository } from '../dist/src/modules/auth/auth.repository.js';
import { AuthService } from '../dist/src/modules/auth/auth.service.js';
import { authConfig } from '../dist/src/modules/auth/auth.config.js';
import { configureApp } from '../dist/src/config/configure-app.js';

const token = () => randomBytes(32).toString('base64url');
function identities() {
  const users = ['admin', 'limited', 'replayAdmin', 'manager', 'reviewer', 'viewer', 'worker', 'shared', 'outsider', 'disabled'];
  const secrets = Object.fromEntries(users.map(id => [id, token()]));
  const roles = { admin: 'system_admin', limited: 'system_admin', replayAdmin: 'system_admin', manager: 'qa_manager', reviewer: 'qa_manager', viewer: 'viewer', worker: 'qa_tester', shared: 'qa_editor', outsider: 'qa_manager', disabled: 'viewer' };
  const value = {
    users: users.map(id => ({ id, token: secrets[id], active: id !== 'disabled' })),
    projects: [{ id: 'project', name: 'Project' }, { id: 'other', name: 'Other' }],
    memberships: users.map(id => ({ userId: id, projectId: id === 'outsider' ? 'other' : 'project', role: roles[id] })),
  };
  value.memberships.push({ userId: 'admin', projectId: 'other', role: 'system_admin' }, { userId: 'shared', projectId: 'other', role: 'qa_editor' });
  return { value, secrets };
}

test('identity storage migration preserves provisioning and explicitly adopts existing state', async () => {
  const { value } = identities(), folder = await mkdtemp(join(tmpdir(), 'qa-admin-storage-'));
  const db = new PlatformRepository();
  db.start(folder, value);
  assert.equal(db.identityStorage, 'provisioned');
  assert.equal(db.get('SELECT COUNT(*) AS n FROM migrations WHERE version=10').n, 1);
  db.onModuleDestroy();
  const changed = structuredClone(value);
  changed.memberships = changed.memberships.filter(m => m.userId !== 'worker');
  changed.users.find(u => u.id === 'viewer').active = false;
  db.start(folder, changed);
  assert.equal(db.get('SELECT active FROM users WHERE id=?', 'viewer').active, 0);
  assert.equal(db.get('SELECT * FROM memberships WHERE user_id=?', 'worker'), undefined);
  db.onModuleDestroy();
  // Adoption does not restore removed memberships or changed activation from the supplied original seed.
  db.start(folder, value, 'managed');
  assert.equal(db.identityStorage, 'managed');
  assert.equal(db.get('SELECT active FROM users WHERE id=?', 'viewer').active, 0);
  assert.equal(db.get('SELECT * FROM memberships WHERE user_id=?', 'worker'), undefined);
  db.exec('UPDATE managed_users SET display_name=?,revision=4 WHERE user_id=?', '저장된 이름', 'manager');
  db.onModuleDestroy();
  db.start(folder, { users: [], projects: [], memberships: [] }, 'managed');
  assert.equal(db.get('SELECT display_name,revision FROM managed_users WHERE user_id=?', 'manager').revision, 4);
  assert.equal(db.get('SELECT COUNT(*) AS n FROM users').n, value.users.length);
  db.onModuleDestroy();
  assert.throws(() => db.start(folder, value), /cannot be reconciled/);
  db.start(folder, value, 'managed');
  assert.equal(db.get('SELECT display_name FROM managed_users WHERE user_id=?', 'manager').display_name, '저장된 이름');
  db.onModuleDestroy();

  const missingAdmin = await mkdtemp(join(tmpdir(), 'qa-admin-empty-'));
  const noAdmin = { users: [value.users.find(u => u.id === 'worker')], projects: [value.projects[0]], memberships: [{ userId: 'worker', projectId: 'project', role: 'qa_tester' }] };
  assert.throws(() => db.start(missingAdmin, noAdmin, 'managed'), /system administrator/);
  db.start(missingAdmin, noAdmin);
  db.onModuleDestroy();
  // Adding an admin only to the seed cannot silently repair an already populated database.
  assert.throws(() => db.start(missingAdmin, value, 'managed'), /system administrator/);
  db.start(missingAdmin, noAdmin);
  assert.equal(db.get('SELECT COUNT(*) AS n FROM users').n, 1);
  db.onModuleDestroy();
  const env = { QA_AUTH_MODE: 'test', NODE_ENV: 'test', QA_DATA_DIR: folder, QA_ENGINE_CLI: resolve('engine.mjs'), QA_ENGINE_MANIFEST: resolve('manifest.json'), QA_LOCAL_IDENTITIES_JSON: JSON.stringify(value) };
  assert.equal(platformConfig(env).identityStorage, 'provisioned');
  assert.equal(platformConfig({ ...env, QA_IDENTITY_STORAGE: 'managed' }).identityStorage, 'managed');
  assert.throws(() => platformConfig({ ...env, QA_IDENTITY_STORAGE: 'typo' }), /identity storage/);
});

test('managed project administration actual HTTP, RBAC, session revocation and restart', { timeout: 90000 }, async t => {
  const { value, secrets } = identities(), root = resolve('../..');
  const folder = await mkdtemp(join(tmpdir(), 'qa-admin-http-'));
  let app, repo, authRepo, origin, preserved, reviewDraft;
  async function start(storage = 'managed', seed = value, seedSessions = false) {
    app = await NestFactory.create(AppModule, { logger: false });
    configureApp(app, () => {});
    const platform = app.get(PlatformService);
    await platform.start({ mode: 'oidc-test', identityStorage: storage, dataDir: folder, identities: seed, engineCli: resolve(root, '.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'), engineManifest: resolve(root, 'apps/app/assets/engine-runtime.json') });
    repo = app.get(PlatformRepository); authRepo = app.get(AuthRepository);
    const auth = app.get(AuthService);
    auth.start(authConfig({ NODE_ENV: 'test', QA_AUTH_MODE: 'oidc-test', QA_OIDC_TEST_ISSUER: 'http://127.0.0.1:4319', QA_OIDC_CLIENT_ID: 'fixture', QA_OIDC_CLIENT_SECRET: 'fixture-only-not-production', QA_OIDC_CALLBACK_URL: 'http://127.0.0.1:4320/api/v1/auth/callback', QA_OIDC_WEB_ORIGIN: 'http://127.0.0.1:4321', QA_OIDC_ALLOWED_WORKSPACES: 'TLOCAL', QA_OIDC_BINDINGS_JSON: '[]' }));
    platform.registerIdentityResolver(auth.resolveIdentity.bind(auth));
    if (seedSessions) for (const u of value.users) authRepo.session(secrets[u.id], u.id, 'desktop');
    await app.listen(0, '127.0.0.1'); origin = await app.getUrl();
  }
  await start('managed', value, true);
  t.after(async () => app?.close());
  async function request(path = '', { user = 'admin', project = 'project', method = 'GET', body, key, credential } = {}) {
    const res = await fetch(`${origin}/api/v1/projects/${project}/administration${path}`, { method, headers: { ...(user ? { authorization: `Bearer ${credential ?? secrets[user]}` } : {}), ...(body !== undefined ? { 'content-type': 'application/json' } : {}), ...(key ? { 'idempotency-key': key } : {}) }, ...(body !== undefined ? { body: JSON.stringify(body) } : {}) });
    return { status: res.status, body: await res.json() };
  }
  const userRow = async id => (await request('/users?limit=100')).body.items.find(u => u.userId === id);
  async function platformRequest(path, { user = 'admin', method = 'GET', body, key } = {}) {
    const res = await fetch(`${origin}/api/v1/projects/project${path}`, { method, headers: { authorization: `Bearer ${secrets[user]}`, ...(body !== undefined ? { 'content-type': 'application/json' } : {}), ...(key ? { 'idempotency-key': key } : {}) }, ...(body !== undefined ? { body: JSON.stringify(body) } : {}) });
    return { status: res.status, body: await res.json() };
  }
  async function preservedState() {
    const version = await platformRequest(`/registry/versions/${preserved.versionId}`);
    const run = await platformRequest(`/runs/${preserved.runId}`);
    assert.equal(version.status, 200); assert.equal(run.status, 200);
    return { version: version.body, run: run.body, versionRow: { ...repo.get('SELECT * FROM versions WHERE id=?', preserved.versionId) }, runRow: { ...repo.get('SELECT * FROM runs WHERE id=?', preserved.runId) }, events: repo.all('SELECT sequence,payload,hash FROM events WHERE run_id=? ORDER BY sequence', preserved.runId).map(row => ({ ...row })) };
  }

  await t.test('actual recorded Chromium bytes can be published and ingested before administration', async () => {
    const fixture = resolve('test/fixtures/administration-alpha6-run');
    const provenance = JSON.parse((await readFile(join(fixture, 'provenance.json'), 'utf8')).replace(/^\uFEFF/, ''));
    for (const file of provenance.files) assert.equal(createHash('sha256').update(await readFile(join(fixture, file.path))).digest('hex'), file.sha256);
    const cli = resolve(root, '.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs');
    const xml = execFileSync(process.execPath, [cli, 'export', join(fixture, 'blueprint.json'), '--format', 'xml'], { encoding: 'utf8', windowsHide: true, timeout: 15000, maxBuffer: 1048576 });
    const created = await platformRequest('/registry/drafts', { user: 'manager', method: 'POST', body: { packageId: 'admin-preserved', title: 'Actual recorded run', xml, dependencies: [] } });
    assert.equal(created.status, 201);
    assert.equal((await platformRequest(`/registry/drafts/${created.body.id}/review`, { user: 'reviewer', method: 'POST' })).status, 200);
    const published = await platformRequest(`/registry/drafts/${created.body.id}/publish`, { user: 'manager', method: 'POST', body: { version: '1.0.0' }, key: 'preserve-version' });
    assert.equal(published.status, 201);
    const blueprintJson = await readFile(join(fixture, 'blueprint.json'), 'utf8');
    const events = (await readFile(join(fixture, 'events.jsonl'), 'utf8')).trim().split(/\r?\n/);
    const resultJson = await readFile(join(fixture, 'result.json'), 'utf8'), result = JSON.parse(resultJson), first = JSON.parse(events[0]);
    const start = await platformRequest('/runs', { user: 'worker', method: 'POST', key: 'preserve-run', body: { blueprintJson, engineRunId: first.runId, attempt: first.attempt, snapshotHash: result.executed.blueprintSnapshotHash, engineVersion: result.executed.engineVersion, startedEventJson: events[0], versionId: published.body.id } });
    assert.equal(start.status, 201);
    assert.equal((await platformRequest(`/runs/${start.body.id}/events`, { user: 'worker', method: 'POST', body: { eventsJson: events.slice(1) } })).status, 200);
    const finish = await platformRequest(`/runs/${start.body.id}/result`, { user: 'worker', method: 'PUT', body: { resultJson } });
    assert.equal(finish.status, 200); assert.equal(finish.body.reportedOutcome, 'passed'); assert.equal(finish.body.evidenceStatus, 'verified');
    assert.deepEqual(JSON.parse(finish.body.resultJson), result);
    preserved = { versionId: published.body.id, runId: start.body.id };
    preserved.state = await preservedState();
    preserved.hash = createHash('sha256').update(JSON.stringify(preserved.state)).digest('hex');
    const draft = await platformRequest('/registry/drafts', { user: 'manager', method: 'POST', body: { packageId: 'review-revocation', title: 'Review gate', xml, dependencies: [] } });
    assert.equal(draft.status, 201); reviewDraft = draft.body.id;
    assert.equal((await platformRequest(`/registry/drafts/${reviewDraft}/review`, { user: 'reviewer', method: 'POST' })).status, 200);
  });

  await t.test('scoped bounded directory keeps credentials private and nullable metadata explicit', async () => {
    assert.deepEqual((await request()).body, { identityStorage: 'managed', mutationSupported: true });
    for (const user of [null, 'disabled']) assert.equal((await request('/users', { user })).status, 401);
    for (const user of ['viewer', 'worker', 'outsider']) assert.equal((await request('/users', { user })).status, 403);
    const first = await request('/users?limit=2');
    assert.equal(first.status, 200); assert.equal(first.body.items.length, 2); assert.ok(first.body.nextCursor);
    const second = await request(`/users?limit=100&cursor=${first.body.nextCursor}`);
    const rows = [...first.body.items, ...second.body.items];
    assert.equal(rows.length, value.users.length - 1); assert.equal(new Set(rows.map(u => u.userId)).size, rows.length);
    assert.ok(rows.some(u => u.userId === 'disabled' && !u.active));
    for (const row of rows) assert.deepEqual(Object.keys(row).sort(), ['active', 'displayName', 'membershipRevision', 'role', 'userId', 'userRevision']);
    assert.ok(rows.every(u => u.displayName === null));
    const serialized = JSON.stringify(rows); for (const secret of Object.values(secrets)) assert.ok(!serialized.includes(secret));
    for (const query of ['limit=0', 'limit=101', 'limit=1.5', 'limit=1&limit=2', 'cursor=MA', 'cursor=MQ==', 'cursor=!']) assert.equal((await request(`/users?${query}`)).status, 400);
    assert.equal((await request('/members/outsider')).status, 404);
  });
  await t.test('creation is idempotent and cannot grant system administration or mint credentials', async () => {
    const input = { userId: 'created', displayName: null, role: 'qa_tester' };
    for (const user of ['manager', 'reviewer']) assert.equal((await request('/users', { user, method: 'POST', body: input, key: 'create' })).status, 403);
    assert.equal((await request('/users', { method: 'POST', body: input })).status, 409);
    assert.equal((await request('/users', { method: 'POST', body: { ...input, role: 'system_admin' }, key: 'bad' })).status, 400);
    assert.equal((await request('/users', { method: 'POST', body: { ...input, token: 'not-allowed' }, key: 'bad' })).status, 400);
    const first = await request('/users', { user: 'replayAdmin', method: 'POST', body: input, key: 'create' });
    assert.equal(first.status, 201); assert.equal(first.body.active, true); assert.equal(first.body.displayName, null);
    assert.deepEqual((await request('/users', { user: 'replayAdmin', method: 'POST', body: input, key: 'create' })).body, first.body);
    assert.equal((await request('/users', { user: 'replayAdmin', method: 'POST', body: { ...input, displayName: 'different' }, key: 'create' })).status, 409);
    assert.equal((await request('/users', { method: 'POST', body: { ...input, userId: 'outsider' }, key: 'collision' })).status, 409);
    assert.equal((await request('/members/replayAdmin?membershipRevision=0', { method: 'DELETE' })).status, 200);
    assert.equal((await request('/users', { user: 'replayAdmin', method: 'POST', body: input, key: 'create' })).status, 403);
    assert.equal(repo.get('SELECT COUNT(*) AS n FROM users WHERE id=?', 'created').n, 1);
  });
  await t.test('membership changes enforce hierarchy and reject stale and ABA revisions', async () => {
    for (const target of ['manager', 'reviewer', 'admin']) assert.equal((await request(`/members/${target}`, { user: 'manager', method: 'PUT', body: { role: 'viewer', membershipRevision: 0 } })).status, 403);
    assert.equal((await request('/members/worker', { user: 'manager', method: 'PUT', body: { role: 'qa_manager', membershipRevision: 0 } })).status, 403);
    const updated = await request('/members/worker', { user: 'manager', method: 'PUT', body: { role: 'qa_editor', membershipRevision: 0 } });
    assert.equal(updated.status, 200); assert.equal(updated.body.membershipRevision, 1);
    assert.equal((await request('/members/worker', { user: 'manager', method: 'PUT', body: { role: 'viewer', membershipRevision: 0 } })).status, 409);
    const removed = await request('/members/worker?membershipRevision=1', { user: 'manager', method: 'DELETE' });
    assert.deepEqual(removed.body, { userId: 'worker', role: null, membershipRevision: 2 });
    assert.deepEqual((await request('/members/worker')).body, removed.body);
    assert.equal((await request('/members/worker', { user: 'manager', method: 'PUT', body: { role: 'viewer', membershipRevision: 2 } })).status, 403);
    assert.equal((await request('/members/worker', { method: 'PUT', body: { role: 'qa_tester', membershipRevision: 0 } })).status, 409);
    assert.equal((await request('/members/worker', { method: 'PUT', body: { role: 'qa_tester', membershipRevision: 2 } })).body.membershipRevision, 3);
    assert.equal((await request('/members/worker?membershipRevision=1', { method: 'DELETE' })).status, 409);
    assert.equal((await request('/members/admin?membershipRevision=0', { method: 'DELETE' })).status, 403);
    // Project 'other' has only admin as active system administrator; self removal remains forbidden.
    assert.equal((await request('/members/admin?membershipRevision=0', { project: 'other', method: 'DELETE' })).status, 403);
  });
  await t.test('global edits require every affected project and revoke all previous sessions on the same database', async () => {
    const patch = { active: false, userRevision: 0 };
    const session = token(), code = token(), webSession = token();
    authRepo.session(session, 'shared', 'desktop'); authRepo.session(webSession, 'shared', 'web');
    authRepo.desktop(code, 'shared', 'challenge', 'http://127.0.0.1:4311/qa/callback');
    assert.equal((await request('/users/shared', { user: 'limited', method: 'PATCH', body: patch })).status, 403);
    assert.equal(authRepo.lookup(session, 'desktop'), 'shared');
    const beforeAudit = repo.get("SELECT COUNT(*) AS n FROM audit WHERE action LIKE 'administration.user.updated.%'").n;
    assert.equal((await request('/users/shared', { method: 'PATCH', body: patch })).status, 200);
    assert.equal(authRepo.lookup(session, 'desktop'), undefined); assert.equal(authRepo.lookup(webSession, 'web'), undefined);
    assert.equal(repo.get('SELECT COUNT(*) AS n FROM desktop_codes WHERE user_id=?', 'shared').n, 0);
    assert.equal((await request('/users', { user: 'shared', credential: session })).status, 401);
    assert.equal((await request('/users/shared', { method: 'PATCH', body: { active: true, displayName: '공유 사용자', userRevision: 1 } })).status, 200);
    assert.equal(authRepo.lookup(session, 'desktop'), undefined);
    assert.equal((await request('/users', { user: 'shared', credential: session })).status, 401);
    assert.equal((await request('/users/shared', { method: 'PATCH', body: { active: false, userRevision: 0 } })).status, 409);
    assert.equal(repo.get("SELECT COUNT(*) AS n FROM audit WHERE action LIKE 'administration.user.updated.%'").n - beforeAudit, 4);
    assert.equal((await userRow('shared')).displayName, '공유 사용자');
    assert.equal((await request('/users/admin', { method: 'PATCH', body: { active: false, userRevision: 0 } })).status, 403);
    assert.equal((await request('/users/viewer', { method: 'PATCH', body: { userRevision: 0 } })).status, 400);
    for (const body of [{ userRevision: 2, displayName: null }, { userRevision: 2, clearDisplayName: false }, { userRevision: 2, displayName: 'name', clearDisplayName: true }, { userRevision: 2, displayName: 'name', clearDisplayName: false }]) assert.equal((await request('/users/shared', { method: 'PATCH', body })).status, 400);
    const cleared = await request('/users/shared', { method: 'PATCH', body: { userRevision: 2, clearDisplayName: true } });
    assert.equal(cleared.status, 200); assert.equal(cleared.body.displayName, null); assert.equal(cleared.body.userRevision, 3);
  });
  await t.test('active HTTP session sees membership revocation immediately and failed transaction leaves no mutation', async () => {
    assert.equal((await request('/users', { user: 'reviewer' })).status, 200);
    const before = await userRow('reviewer');
    assert.equal((await request('/members/reviewer', { method: 'PUT', body: { role: 'viewer', membershipRevision: before.membershipRevision } })).status, 200);
    assert.equal((await request('/users', { user: 'reviewer' })).status, 403);
    assert.equal((await request('/members/reviewer', { user: 'manager', method: 'PUT', body: { role: 'qa_manager', membershipRevision: 1 } })).status, 403);
    assert.equal((await userRow('reviewer')).role, 'viewer');
    assert.equal((await platformRequest(`/registry/drafts/${reviewDraft}/review`, { user: 'reviewer', method: 'POST' })).status, 403);
    assert.equal((await platformRequest(`/registry/drafts/${reviewDraft}/publish`, { user: 'reviewer', method: 'POST', body: { version: '1.0.0' }, key: 'forbidden-reviewer' })).status, 403);
    // An authorized publisher must also reject the previously approved, now unauthorized reviewer.
    assert.equal((await platformRequest(`/registry/drafts/${reviewDraft}/publish`, { user: 'manager', method: 'POST', body: { version: '1.0.0' }, key: 'revoked-review' })).status, 409);
    assert.equal(repo.get('SELECT COUNT(*) AS n FROM runs').n, 1);
    assert.equal(repo.get('SELECT COUNT(*) AS n FROM versions').n, 1);
    assert.deepEqual(await preservedState(), preserved.state);
  });
  await t.test('restart preserves edits and mode while original seed cannot restore privileges', async () => {
    const before = (await request('/users?limit=100')).body;
    await app.close();
    await start('managed', value, false);
    assert.deepEqual((await request('/users?limit=100')).body, before);
    assert.equal((await request('/users', { user: 'reviewer' })).status, 403);
    assert.equal((await request('/users', { user: 'shared' })).status, 401);
    assert.equal((await request('/members/worker')).body.membershipRevision, 3);
    assert.equal(repo.get('SELECT COUNT(*) AS n FROM migrations WHERE version=10').n, 1);
    assert.deepEqual(await preservedState(), preserved.state);
    assert.equal(createHash('sha256').update(JSON.stringify(await preservedState())).digest('hex'), preserved.hash);
  });
});

test('provisioned server exposes unsupported administration and refuses mutations', { timeout: 30000 }, async t => {
  const { value, secrets } = identities(), root = resolve('../..');
  const app = await NestFactory.create(AppModule, { logger: false });
  t.after(() => app.close()); configureApp(app, () => {});
  await app.get(PlatformService).start({ mode: 'test', dataDir: await mkdtemp(join(tmpdir(), 'qa-admin-provisioned-')), identities: value, engineCli: resolve(root, '.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'), engineManifest: resolve(root, 'apps/app/assets/engine-runtime.json') });
  await app.listen(0, '127.0.0.1'); const origin = await app.getUrl();
  const headers = { authorization: `Bearer ${secrets.admin}`, 'content-type': 'application/json', 'idempotency-key': 'new' };
  const status = await fetch(`${origin}/api/v1/projects/project/administration`, { headers });
  assert.deepEqual(await status.json(), { identityStorage: 'provisioned', mutationSupported: false });
  const response = await fetch(`${origin}/api/v1/projects/project/administration/users`, { method: 'POST', headers, body: JSON.stringify({ userId: 'new', displayName: null, role: 'viewer' }) });
  assert.equal(response.status, 409);
  assert.equal((await response.json()).details[0].code, 'IDENTITY_STORAGE_NOT_MANAGED');
  assert.equal(app.get(PlatformRepository).get('SELECT id FROM users WHERE id=?', 'new'), undefined);
});
