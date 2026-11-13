import 'reflect-metadata';
import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { resolve, join } from 'node:path';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { NestFactory } from '@nestjs/core';
import { Module } from '@nestjs/common';
import { AppModule } from '../dist/src/app.module.js';
import { PlatformService } from '../dist/src/modules/platform/platform.service.js';
import { PlatformRepository } from '../dist/src/modules/platform/platform.repository.js';
import { EngineContractService } from '../dist/src/modules/platform/engine-contract.service.js';
import { SuiteModule } from '../dist/src/modules/suite/suite.module.js';
import { SuiteService } from '../dist/src/modules/suite/suite.service.js';
import { configureApp } from '../dist/src/config/configure-app.js';

test('product context, Suite pin restoration and project members preserve boundaries', { timeout: 90000 }, async t => {
  const root = resolve('../..');
  const dataDir = await mkdtemp(join(tmpdir(), 'qa-product-context-'));
  const cli = resolve(root, '.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs');
  const manifestPath = resolve(root, 'apps/app/assets/engine-runtime.json');
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  const baseUsers = ['author', 'reviewer', 'tester', 'editor', 'viewer', 'admin', 'outsider', 'disabled'];
  const users = [...baseUsers, ...Array.from({ length: 101 }, (_, i) => `member${i}`)];
  const tokens = Object.fromEntries(users.map(id => [id, `${id}-product-context-fixture-token-32chars`]));
  const role = id => ({ author: 'qa_manager', reviewer: 'qa_manager', tester: 'qa_tester', editor: 'qa_editor', viewer: 'viewer', admin: 'system_admin', outsider: 'qa_manager' })[id] ?? 'viewer';
  const identities = {
    users: users.map(id => ({ id, token: tokens[id], active: id !== 'disabled' })),
    projects: [{ id: 'project', name: 'Project' }, { id: 'other', name: 'Other' }],
    memberships: users.map(id => ({ userId: id, projectId: id === 'outsider' ? 'other' : 'project', role: role(id) })),
  };
  identities.memberships.push({ userId: 'tester', projectId: 'other', role: 'qa_tester' });
  let app, platform, suite, repo, engine, origin;
  async function start(path = manifestPath) {
    class Root {}
    Module({ imports: [AppModule, SuiteModule] })(Root);
    app = await NestFactory.create(Root, { logger: false });
    configureApp(app, () => {});
    platform = app.get(PlatformService);
    await platform.start({ mode: 'test', dataDir, identities, engineCli: cli, engineManifest: path });
    suite = app.get(SuiteService); suite.start();
    repo = app.get(PlatformRepository); engine = app.get(EngineContractService);
    await app.listen(0, '127.0.0.1'); origin = await app.getUrl();
  }
  await start(); t.after(() => app.close());
  const request = async (path, { user = 'author', project = 'project', body, method = body ? 'POST' : 'GET' } = {}) => {
    const response = await fetch(`${origin}/api/v1/projects/${project}${path}`, {
      method, headers: { ...(user ? { authorization: `Bearer ${tokens[user]}` } : {}), ...(body ? { 'content-type': 'application/json' } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
    return { status: response.status, body: await response.json() };
  };
  const allActions = ['readPublished', 'pinVersions', 'publishRuns', 'requestExecutions', 'manageSchedules', 'updateWork', 'createDrafts', 'reviewPublish', 'viewAudit', 'listMembers'];
  await t.test('context matches exact server metadata and role entry permissions without Engine work', async () => {
    const originalPlan = engine.plan;
    engine.plan = async () => { throw new Error('GET must not plan or execute'); };
    try {
      for (const [user, count] of [['viewer', 1], ['tester', 6], ['editor', 7], ['author', 10], ['admin', 10]]) {
        const response = await request('/context', { user });
        assert.equal(response.status, 200);
        assert.deepEqual(response.body, {
          projectId: 'project', role: role(user), allowedActions: allActions.slice(0, count),
          engine: { engineVersion: manifest.engineVersion, contractVersion: engine.contractVersion, contractSha256: engine.contractSha256, archiveSha256: manifest.sha256 },
        });
        assert.doesNotMatch(JSON.stringify(response.body), /token|C:\\\\|node_modules|engineCli|dataDir/);
      }
      const bytes = await readFile(resolve(cli, `../../../contracts/releases/qa-contract-${engine.version}.json`));
      assert.equal(engine.contractSha256, createHash('sha256').update(bytes).digest('hex'));
      assert.equal((await request('/context', { user: null })).status, 401);
      assert.equal((await request('/context', { user: 'disabled' })).status, 401);
      assert.equal((await request('/context', { user: 'outsider' })).status, 403);
      assert.equal((await request('/context', { project: 'missing' })).status, 403);
      assert.equal(repo.get('SELECT count(*) AS n FROM runs').n, 0);
    } finally { engine.plan = originalPlan; }
  });
  await t.test('members are manager-only, minimal, active, scoped and bounded across pages', async () => {
    for (const user of ['viewer', 'tester', 'editor', 'outsider']) assert.equal((await request('/members', { user })).status, 403);
    assert.equal((await request('/members', { user: null })).status, 401);
    const first = await request('/members?limit=100');
    assert.equal(first.status, 200); assert.equal(first.body.items.length, 100); assert.ok(first.body.nextCursor);
    const second = await request(`/members?limit=100&cursor=${first.body.nextCursor}`);
    const items = [...first.body.items, ...second.body.items];
    assert.equal(items.length, users.length - 2); assert.equal(second.body.nextCursor, null);
    assert.equal(new Set(items.map(item => item.userId)).size, items.length);
    assert.ok(!items.some(item => ['outsider', 'disabled'].includes(item.userId)));
    for (const item of items) assert.deepEqual(item, { userId: item.userId, displayName: null, role: role(item.userId) });
    const other = await request('/members?limit=100', { project: 'other', user: 'outsider' });
    assert.deepEqual(other.body.items.map(item => item.userId), ['tester', 'outsider']);
    assert.equal((await request(`/members?cursor=${first.body.nextCursor}`, { project: 'other', user: 'outsider' })).body.items.length, 0);
    repo.exec('UPDATE users SET active=0 WHERE id=?', 'viewer');
    assert.ok(!(await request('/members?limit=100')).body.items.some(item => item.userId === 'viewer'));
    repo.exec('UPDATE users SET active=1 WHERE id=?', 'viewer');
  });
  let pins;
  await t.test('personal Suite pins retain identity, paging, old runtime and scope', async () => {
    const xml = execFileSync(process.execPath, [cli, 'template', '--format', 'xml'], { encoding: 'utf8', windowsHide: true });
    const d = await platform.createDraft('author', 'project', { packageId: 'scenario', title: 'Fixture', xml, dependencies: [] });
    assert.equal((await request(`/registry/drafts/${d.id}/review`, { method: 'POST' })).status, 403);
    platform.review('reviewer', 'project', d.id);
    const v = await platform.publish('author', 'project', d.id, '1.0.0', 'registry');
    pins = [];
    for (const packageId of ['suite-a', 'suite-b']) {
      const draft = suite.create('author', 'project', { packageId, title: packageId, stopOnFailure: true, cases: [{ caseId: 'first', versionId: v.id, sha256: v.sha256 }] });
      suite.review('reviewer', 'project', draft.id);
      const published = suite.publish('author', 'project', draft.id, '1.0.0', packageId);
      pins.push(suite.pin('tester', 'project', published.id, published.sha256));
    }
    assert.equal((await request('/suites/pins', { user: 'viewer', method: 'PUT', body: { versionId: pins[0].versionId, sha256: pins[0].sha256 } })).status, 403);
    const first = await request('/suites/pins?limit=1', { user: 'tester' });
    assert.deepEqual(first.body.items, [pins[0]]); assert.ok(first.body.nextCursor);
    assert.deepEqual((await request(`/suites/pins?limit=1&cursor=${first.body.nextCursor}`, { user: 'tester' })).body, { items: [pins[1]], nextCursor: null });
    for (const user of ['author', 'viewer']) assert.deepEqual((await request('/suites/pins', { user })).body.items, []);
    assert.equal((await request('/suites/pins', { user: 'outsider' })).status, 403);
    assert.deepEqual((await request('/suites/pins', { user: 'tester', project: 'other' })).body.items, []);
    const originalVersion = engine.version;
    engine.version = '0.1.0-alpha.8';
    try {
      assert.deepEqual((await request('/suites/pins', { user: 'tester' })).body.items, pins);
      assert.equal((await request(`/suites/versions/${pins[0].versionId}`)).body.engineVersion, originalVersion);
      assert.equal((await request('/suites/pins', { user: 'tester', method: 'PUT', body: { versionId: pins[0].versionId, sha256: pins[0].sha256 } })).status, 409);
    } finally { engine.version = originalVersion; }
    assert.equal(repo.get('SELECT count(*) AS n FROM runs').n, 0);
  });
  await t.test('new paged endpoints reject malformed cursors and out-of-bounds limits', async () => {
    for (const path of ['/members', '/suites/pins']) {
      for (const query of ['limit=0', 'limit=101', 'limit=-1', 'limit=1.5', 'limit=1&limit=2', 'cursor=!', 'cursor=MA', 'cursor=LTE', 'cursor=MQ==', 'cursor=OTAwNzE5OTI1NDc0MDk5Mg']) {
        assert.equal((await request(`${path}?${query}`)).status, 400, `${path}?${query}`);
      }
      assert.equal((await request(`${path}?limit=1`)).status, 200);
      assert.equal((await request(`${path}?limit=100`)).status, 200);
    }
  });
  await t.test('restart restores exact pins and missing archive metadata is explicit null', async () => {
    await app.close();
    const { sha256: unusedArchivePin, ...withoutArchive } = manifest;
    const noArchivePath = join(dataDir, 'manifest-without-archive.json');
    await writeFile(noArchivePath, JSON.stringify(withoutArchive));
    await start(noArchivePath);
    assert.deepEqual((await request('/suites/pins', { user: 'tester' })).body.items, pins);
    assert.equal((await request('/context')).body.engine.archiveSha256, null);
    assert.equal((await request('/context')).body.engine.contractSha256, engine.contractSha256);
    assert.equal(repo.get('SELECT count(*) AS n FROM runs').n, 0);
  });
});
