import 'reflect-metadata';
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { spawn, execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { once } from 'node:events';
import { mkdir, mkdtemp, readFile, writeFile } from 'node:fs/promises';
import { join, resolve, dirname } from 'node:path';
import { randomBytes, randomUUID, createHash } from 'node:crypto';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../dist/src/app.module.js';
import { configureApp } from '../dist/src/config/configure-app.js';
import { PlatformService } from '../dist/src/modules/platform/platform.service.js';
import { PlatformRepository } from '../dist/src/modules/platform/platform.repository.js';
import { EngineContractService } from '../dist/src/modules/platform/engine-contract.service.js';
import { AgentService } from '../dist/src/modules/agent/agent.service.js';
import { SuiteService } from '../dist/src/modules/suite/suite.service.js';
import { SchedulerService } from '../dist/src/modules/scheduler/scheduler.service.js';
import { root, runtimePaths } from './server-runtime.mjs';

if (process.env.NODE_ENV === 'production') throw new Error('Local runtime acceptance only');
const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const exec = promisify(execFile), sleep = ms => new Promise(done => setTimeout(done, ms));
const outputRoot = join(root, 'artifacts/runtime-alpha10'); await mkdir(outputRoot, { recursive: true });
const directory = await mkdtemp(join(outputRoot, 'run-')), dataDir = join(directory, 'server-data');
const historyOnly = process.argv.includes('--history-only');
const receipt = { status: 'running', scope: historyOnly ? 'history-only; no new browser execution' : 'actual-browser-and-Agent', directory, startedAt: new Date().toISOString(), runtime: JSON.parse(await readFile(join(root, 'packages/contract/runtime/engine-runtime.json'))).engineVersion, checks: [], children: [] };
const current = runtimePaths({}), legacy = { engineCli: join(root, '.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'), engineManifest: join(root, 'apps/app/assets/engine-runtime.json') };
const secrets = Object.fromEntries(['author', 'reviewer', 'tester', 'viewer'].map(id => [id, randomBytes(32).toString('base64url')]));
const identities = { users: Object.entries(secrets).map(([id, token]) => ({ id, token, active: true })), projects: [{ id: 'demo', name: 'Runtime acceptance' }], memberships: Object.keys(secrets).map(userId => ({ userId, projectId: 'demo', role: userId === 'viewer' ? 'viewer' : userId === 'tester' ? 'qa_tester' : 'qa_manager' })) };
const actions = ['launch', 'input', 'tap', 'assertText', 'assertValue', 'captureText', 'screenshot'], capabilities = { platforms: ['web'], actions };
let app, platform, db, engine, agents, suites, scheduler, origin;
const activeChildren = new Set();

async function snapshot() {
  if (process.platform !== 'win32') return [];
  const { stdout } = await exec('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', 'Get-CimInstance Win32_Process | Select-Object ProcessId,ParentProcessId,CreationDate | ConvertTo-Json -Compress'], { cwd: root, windowsHide: true, timeout: 8000, maxBuffer: 2 * 1048576 });
  const rows = JSON.parse(stdout || '[]'); return Array.isArray(rows) ? rows : [rows];
}
function child(cli, args, env = {}, name = 'cli', timeout = 60000, observe = false) {
  const processChild = spawn(process.execPath, [cli, ...args], { cwd: root, env: { ...process.env, ...env }, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
  activeChildren.add(processChild);
  let stdout = '', stderr = '', timedOut = false;
  processChild.stdout.on('data', bytes => { if (stdout.length < 2 * 1048576) stdout += bytes.toString(); });
  processChild.stderr.on('data', bytes => { if (stderr.length < 65536) stderr += bytes.toString(); });
  const owned = new Map(), controller = { stopped: false };
  const watcher = observe ? (async () => {
    while (!controller.stopped) {
      const rows = await snapshot();
      const main = rows.find(row => row.ProcessId === processChild.pid); if (main) owned.set(main.ProcessId, main.CreationDate);
      let changed = true;
      while (changed) { changed = false; for (const row of rows) if (owned.has(row.ParentProcessId) && !owned.has(row.ProcessId)) { owned.set(row.ProcessId, row.CreationDate); changed = true; } }
      if (!controller.stopped) await sleep(300);
    }
  })() : Promise.resolve();
  const timer = setTimeout(() => { timedOut = true; if (process.platform === 'win32') execFile('taskkill.exe', ['/PID', String(processChild.pid), '/T', '/F'], { windowsHide: true }, () => {}); else processChild.kill(); }, timeout);
  const done = (async () => {
    try {
      const [code] = await once(processChild, 'close');
      clearTimeout(timer); controller.stopped = true; await watcher;
      const after = observe ? await snapshot() : [];
      const remaining = after.filter(row => owned.get(row.ProcessId) === row.CreationDate).map(row => row.ProcessId);
      receipt.children.push({ name, pid: processChild.pid, exitCode: code, timedOut, observedOwnedPids: [...owned.keys()], remaining, scope: observe ? 'sampled descendant PID and creation time; not a global leak proof' : 'main process close only' });
      await writeFile(join(directory, `${name}.stdout.log`), stdout);
      await writeFile(join(directory, `${name}.stderr.log`), stderr);
      assert.equal(timedOut, false, `${name} exceeded deadline`); assert.equal(remaining.length, 0, `${name} has observed surviving children`);
      return { code, stdout, stderr };
    } finally { clearTimeout(timer); controller.stopped = true; activeChildren.delete(processChild); }
  })();
  return { process: processChild, done };
}
async function command(cli, args, name) { const result = await child(cli, args, {}, name, 30000).done; assert.equal(result.code, 0, `${name}: ${result.stderr}`); return result.stdout; }
async function start(runtime) {
  app = await NestFactory.create(AppModule, { logger: false }); configureApp(app, () => {});
  platform = app.get(PlatformService); await platform.start({ mode: 'test', dataDir, identities, ...runtime });
  db = app.get(PlatformRepository); engine = app.get(EngineContractService);
  agents = app.get(AgentService); agents.start(); suites = app.get(SuiteService); suites.start(); agents.registerSuiteResolver(suites.resolvePublished.bind(suites));
  scheduler = app.get(SchedulerService); scheduler.clock = () => Date.parse('2026-11-16T00:00:00Z'); scheduler.start(false);
  await app.listen(0, '127.0.0.1'); origin = await app.getUrl();
}
async function request(path, { body, method = body === undefined ? 'GET' : 'POST', user = 'author', token, status = 200 } = {}) {
  const response = await fetch(`${origin}/api/v1/${path}`, { method, headers: { authorization: `Bearer ${token ?? secrets[user]}`, ...(body !== undefined ? { 'content-type': 'application/json' } : {}), 'idempotency-key': `acceptance-${randomUUID()}` }, ...(body !== undefined ? { body: JSON.stringify(body) } : {}), signal: AbortSignal.timeout(20000) });
  const result = response.status === 204 ? null : await response.json();
  assert.equal(response.status, status, `HTTP ${path}: ${JSON.stringify(result)}`); return result;
}
const project = 'projects/demo';
async function publish(xml, name) {
  const draft = await request(`${project}/registry/drafts`, { body: { packageId: name, title: name, xml, dependencies: [] }, status: 201 });
  await request(`${project}/registry/drafts/${draft.id}/review`, { method: 'POST', user: 'reviewer' });
  return request(`${project}/registry/drafts/${draft.id}/publish`, { body: { version: '1.0.0' }, status: 201 });
}
async function ingest({ blueprintJson, events, resultJson, versionId, reportDir }) {
  const first = JSON.parse(events[0]), result = JSON.parse(resultJson);
  const run = await request(`${project}/runs`, { user: 'tester', body: { blueprintJson, engineRunId: first.runId, attempt: first.attempt, snapshotHash: result.executed.blueprintSnapshotHash, engineVersion: result.executed.engineVersion, startedEventJson: events[0], versionId }, status: 201 });
  await request(`${project}/runs/${run.id}/events`, { body: { eventsJson: events.slice(1) }, user: 'tester' });
  let response = await request(`${project}/runs/${run.id}/result`, { method: 'PUT', body: { resultJson }, user: 'tester' });
  for (const artifact of response.artifacts) {
    const bytes = await readFile(join(reportDir, artifact.name));
    assert.equal(sha(bytes), artifact.sha256);
    await request(`${project}/runs/${run.id}/artifacts`, { method: 'PUT', user: 'viewer', body: { artifactId: artifact.artifactId, sha256: artifact.sha256, mimeType: artifact.mimeType, base64: bytes.toString('base64') }, status: 403 });
    await request(`${project}/runs/${run.id}/artifacts`, { method: 'PUT', user: 'tester', body: { artifactId: artifact.artifactId, sha256: artifact.sha256, mimeType: artifact.mimeType, base64: bytes.toString('base64') } });
    const download = await request(`${project}/runs/${run.id}/artifacts/${artifact.artifactId}`, { user: 'viewer' });
    assert.equal(sha(Buffer.from(download.base64, 'base64')), sha(bytes));
  }
  response = await request(`${project}/runs/${run.id}`);
  assert.equal(response.evidenceStatus, 'verified'); assert.equal(response.reportedOutcome, result.outcome);
  return response;
}
async function waitFor(check, message, timeout = 30000) { const end = Date.now() + timeout; do { const value = check(); if (value) return value; await sleep(100); } while (Date.now() < end); throw new Error(message); }
function historySnapshot(old) {
  return { version: { ...db.get('SELECT * FROM versions WHERE id=?', old.version.id) }, run: { ...db.get('SELECT * FROM runs WHERE id=?', old.run.id) }, events: db.all('SELECT * FROM events WHERE run_id=? ORDER BY sequence', old.run.id).map(row => ({ ...row })), agent: { ...db.get('SELECT * FROM agents WHERE id=?', old.agentId) }, job: { ...db.get('SELECT * FROM agent_jobs WHERE id=?', old.job) }, lease: { ...db.get('SELECT * FROM agent_leases WHERE id=?', old.lease.leaseId) } };
}
const target = createServer((_req, res) => { res.setHeader('Content-Type', 'text/html; charset=utf-8'); res.end('<!doctype html><meta charset="utf-8"><input data-testid="username"><button data-testid="submit">Submit</button><p data-testid="greeting"></p><script>document.querySelector("button").onclick=()=>document.querySelector("p").textContent="Welcome "+document.querySelector("input").value;</script>'); });
try {
  await new Promise(done => target.listen(0, '127.0.0.1', done)); const targetOrigin = `http://127.0.0.1:${target.address().port}`;
  await start(legacy);
  const fixture = join(root, 'apps/server/test/fixtures/administration-alpha6-run');
  const oldBlueprint = await readFile(join(fixture, 'blueprint.json'), 'utf8'), oldEvents = (await readFile(join(fixture, 'events.jsonl'), 'utf8')).trim().split(/\r?\n/), oldResult = await readFile(join(fixture, 'result.json'), 'utf8');
  const oldXml = await command(legacy.engineCli, ['export', join(fixture, 'blueprint.json'), '--format', 'xml'], 'old-export');
  const old = { version: await publish(oldXml, 'old-published'), agentId: 'old-agent' };
  old.run = await ingest({ blueprintJson: oldBlueprint, events: oldEvents, resultJson: oldResult, versionId: old.version.id });
  old.credential = agents.provision('author', { agentId: old.agentId, projectIds: ['demo'], resourceKeys: ['old-slot'], capabilities }).token;
  old.job = await agents.enqueue('author', { projectId: 'demo', caseId: 'old-case', blueprintJson: oldBlueprint, executionPolicy: { resourceKey: 'old-slot', platform: 'web', allowedOrigins: JSON.parse(oldBlueprint).target.allowedOrigins, nativeApps: [], secretRefs: [], allowProduction: false } });
  const oldInstance = randomUUID();
  const oldClaim = { agentId: old.agentId, instanceId: oldInstance, claimRequestId: randomUUID(), protocolVersion: '0.1.0-draft.1', engineVersion: engine.version, engineContractVersion: engine.contractVersion, engineContractSha256: engine.contractSha256, projectIds: ['demo'], resourceKeys: ['old-slot'], capabilities };
  old.lease = (await request('agent/claims', { token: old.credential, body: oldClaim })).lease;
  const completed = await request(`agent/leases/${old.lease.leaseId}/complete`, { token: old.credential, method: 'PUT', body: { agentId: old.agentId, instanceId: oldInstance, fence: old.lease.fence, caseResults: [], executionStatus: 'blocked', reason: 'Historical protocol fixture: no device execution claimed', cleanupState: 'confirmed', artifactManifest: [] } });
  assert.equal(completed.deliveryClosed, true);
  await request('agent/instances/release', { token: old.credential, body: { agentId: old.agentId, reportingInstanceId: oldInstance, ownerInstanceId: oldInstance, ownerStopped: true, receipts: [{ leaseId: old.lease.leaseId, completionReceipt: completed.completionReceipt, acceptedThrough: 0 }] } });
  const before = historySnapshot(old); await app.close(); await start(current);
  assert.deepEqual(historySnapshot(old), before); assert.deepEqual(await request(`${project}/runs/${old.run.id}`), old.run);
  assert.deepEqual(await request(`${project}/registry/versions/${old.version.id}`), old.version);
  await request('agent/claims', { token: old.credential, body: { ...oldClaim, instanceId: randomUUID(), claimRequestId: randomUUID(), engineVersion: engine.version, engineContractVersion: engine.contractVersion, engineContractSha256: engine.contractSha256 }, status: 409 });
  const first = JSON.parse(oldEvents[0]), result = JSON.parse(oldResult);
  const newOldRuntimeStart = { ...first, runId: `old-runtime-new-${randomUUID()}` };
  await request(`${project}/runs`, { user: 'tester', body: { blueprintJson: oldBlueprint, engineRunId: newOldRuntimeStart.runId, attempt: first.attempt, snapshotHash: result.executed.blueprintSnapshotHash, engineVersion: result.executed.engineVersion, startedEventJson: JSON.stringify(newOldRuntimeStart) }, status: 409 });
  assert.deepEqual(historySnapshot(old), before);
  receipt.checks.push({ name: 'alpha6-history-and-exact-rejection', status: 'passed', storedHistorySha256: sha(JSON.stringify(before)), note: 'Run is recorded real Chromium; closed old lease is explicitly blocked protocol fixture, not an executed device test.' }); console.log('history/exact pin PASS');

  if (!historyOnly) {
  const bundle = JSON.parse(await readFile(resolve(dirname(current.engineCli), '../..', `contracts/releases/qa-contract-${engine.version}.json`))), blueprint = structuredClone(bundle.example);
  blueprint.target.allowedOrigins = [targetOrigin]; blueprint.target.launchTargets.login = targetOrigin;
  const source = join(directory, 'source.json'); await writeFile(source, JSON.stringify(blueprint));
  const xml = await command(current.engineCli, ['export', source, '--format', 'xml'], 'current-export');
  const version = await publish(xml, 'current-published');
  const run = await child(current.engineCli, ['run', source, '--report', join(directory, 'local-run'), '--timeout', '30000'], {}, 'local-run', 60000, true).done;
  assert.equal(run.code, 0, run.stderr); const summary = JSON.parse(run.stdout.trim());
  const actualResult = await readFile(join(summary.reportDir, 'result.json'), 'utf8'), actualEvents = (await readFile(join(summary.reportDir, 'events.jsonl'), 'utf8')).trim().split(/\r?\n/);
  const shared = await ingest({ blueprintJson: JSON.stringify(blueprint), events: actualEvents, resultJson: actualResult, versionId: version.id, reportDir: summary.reportDir });
  assert(shared.artifacts.some(artifact => artifact.mimeType === 'image/png'));
  receipt.checks.push({ name: 'real-alpha10-shared-result-PNG', status: 'passed', runId: shared.id, artifacts: shared.artifacts.map(({ artifactId, sha256, size, mimeType }) => ({ artifactId, sha256, size, mimeType })) }); console.log('real local result/PNG sharing PASS');

  const provisioned = agents.provision('author', { agentId: 'alpha10-worker', projectIds: ['demo'], resourceKeys: ['alpha10-slot'], capabilities });
  const policy = { resourceKey: 'alpha10-slot', platform: 'web', allowedOrigins: [targetOrigin], nativeApps: [], secretRefs: [], allowProduction: false };
  const config = { schemaVersion: 'qa.agentConfig/v1', agentId: provisioned.agentId, serverUrl: origin, tokenEnv: 'AQA_ACCEPTANCE_AGENT_TOKEN', stateDir: join(directory, 'agent-state'), allowInsecureLocal: true, projectIds: ['demo'], resources: { 'alpha10-slot': { platform: 'web', allowedOrigins: [targetOrigin], nativeApps: [], secretRefs: [], actions, allowProduction: false } }, credentials: {}, maxRunMs: 45000 };
  const configFile = join(directory, 'agent-config.json'); await writeFile(configFile, JSON.stringify(config));
  const launchAgent = name => child(current.engineCli, ['agent', '--config', configFile, '--once'], { AQA_ACCEPTANCE_AGENT_TOKEN: provisioned.token }, name, 90000, true);
  function assertSettledLease(execution) {
    const lease = db.get('SELECT * FROM agent_leases WHERE id=?', execution.leaseId);
    assert(lease.completion_receipt); assert.equal(lease.state, 'closed'); assert.equal(lease.receipt_acked, 1);
    assert.equal(db.get('SELECT lease_id FROM agent_resources WHERE resource_key=?', execution.resourceKey).lease_id, null);
    const owner = db.get('SELECT state FROM agent_instances WHERE agent_id=? AND instance_id=?', lease.agent_id, lease.instance_id);
    assert.equal(owner.state, 'retired');
    return lease;
  }
  async function completeExecution(executionId, name, requestMode = 'Published execution HTTP') {
    const worker = await launchAgent(name).done; assert.equal(worker.code, 0, `${name}: ${worker.stderr}`);
    const execution = await request(`${project}/executions/${executionId}`);
    assert.equal(execution.state, 'completed'); assert.equal(execution.cleanupState, 'confirmed'); assert.equal(execution.evidenceStatus, 'verified');
    const runs = []; for (const entry of execution.caseRuns) runs.push(await request(`${project}/runs/${entry.runId}`));
    const lease = assertSettledLease(execution);
    receipt.checks.push({ name, status: 'passed', requestMode, executionId, reportedExecutionStatus: execution.reportedExecutionStatus, caseResults: runs.map(r => ({ id: r.id, outcome: r.reportedOutcome, evidence: r.evidenceStatus })), cleanupState: execution.cleanupState, completionReceipt: lease.completion_receipt, receiptAcknowledged: true, resourceReleased: true, ownerRetired: true });
    return { execution, runs };
  }
  const draft = suites.create('author', 'demo', { packageId: 'current-suite', title: 'Actual two case suite', stopOnFailure: true, cases: ['first', 'second'].map(caseId => ({ caseId, versionId: version.id, sha256: version.sha256 })) });
  suites.review('reviewer', 'demo', draft.id); const suite = suites.publish('author', 'demo', draft.id, '1.0.0', 'suite-acceptance');
  const requested = await request(`${project}/executions`, { body: { versionId: null, suiteVersionId: suite.id, sha256: suite.sha256, executionPolicy: policy }, status: 201 });
  const suiteResult = await completeExecution(requested.id, 'actual-suite'); assert.deepEqual(suiteResult.execution.caseRuns.map(c => c.caseId), ['first', 'second']); assert(suiteResult.runs.every(r => r.reportedOutcome === 'passed'));
  console.log('actual ordered Suite PASS');

  const schedule = await scheduler.create('author', 'demo', { versionId: null, suiteVersionId: suite.id, sha256: suite.sha256, executionPolicy: policy, timezone: 'UTC', weekdays: [1], localTime: '00:01', latenessSeconds: 300, enabled: true });
  scheduler.clock = () => Date.parse('2026-11-16T00:01:00Z'); scheduler.tick(); scheduler.tick();
  let occurrences = db.all('SELECT * FROM schedule_occurrences WHERE schedule_id=?', schedule.id); assert.equal(occurrences.length, 1);
  const scheduled = await completeExecution(occurrences[0].execution_id, 'actual-scheduled-suite', 'Scheduler service controlled clock; actual Agent HTTP delivery'); assert.equal(scheduled.runs.length, 2);
  scheduler.tick(); assert.equal(db.all('SELECT * FROM schedule_occurrences WHERE schedule_id=?', schedule.id).length, 1);
  const originalOccurrence = { ...db.get('SELECT * FROM schedule_occurrences WHERE id=?', occurrences[0].id) };
  const executionCount = db.get('SELECT COUNT(*) AS n FROM agent_jobs').n;
  await app.close(); await start(current);
  scheduler.clock = () => Date.parse('2026-11-16T00:01:00Z'); scheduler.tick(); scheduler.tick();
  assert.deepEqual({ ...db.get('SELECT * FROM schedule_occurrences WHERE id=?', occurrences[0].id) }, originalOccurrence);
  assert.equal(db.all('SELECT * FROM schedule_occurrences WHERE schedule_id=?', schedule.id).length, 1);
  assert.equal(db.get('SELECT COUNT(*) AS n FROM agent_jobs').n, executionCount);
  config.serverUrl = origin; await writeFile(configFile, JSON.stringify(config));
  receipt.checks.push({ name: 'controlled-clock-occurrence', status: 'passed', occurrenceId: occurrences[0].id, executionId: originalOccurrence.execution_id, executions: 1, restartAndRetick: true, clock: '2026-11-16T00:01:00Z', note: 'Controlled Scheduler clock; actual Agent/Chromium execution, no real week-long wait.' }); console.log('actual scheduled Suite/restart PASS');

  const failure = structuredClone(blueprint); failure.flow.nodes.find(n => n.id === 'home').params.expected = 'deliberate mismatch'; failure.flow.nodes.find(n => n.id === 'home').timeoutMs = 250;
  const stopped = await agents.enqueueFixtureCases('author', { projectId: 'demo', cases: [{ caseId: 'first-fails', blueprintJson: JSON.stringify(failure) }, { caseId: 'must-not-run', blueprintJson: JSON.stringify(blueprint) }], stopOnFailure: true, executionPolicy: policy });
  const stoppedResult = await completeExecution(stopped, 'actual-stop-on-failure', 'Trusted fixture enqueue; actual Agent HTTP delivery'); assert.equal(stoppedResult.runs.length, 1); assert.equal(stoppedResult.runs[0].reportedOutcome, 'failed'); assert.equal(stoppedResult.execution.cases.length, 2);

  const slow = structuredClone(failure); slow.flow.nodes.find(n => n.id === 'home').timeoutMs = 30000;
  const cancelledId = await agents.enqueue('author', { projectId: 'demo', caseId: 'cancelled-case', blueprintJson: JSON.stringify(slow), executionPolicy: policy });
  const cancellingWorker = launchAgent('actual-cancel');
  await waitFor(() => db.get("SELECT 1 FROM events e JOIN agent_case_runs c ON e.run_id=c.run_id JOIN agent_leases l ON c.lease_id=l.id WHERE l.execution_id=? AND e.payload LIKE '%\"type\":\"step.started\"%' AND e.payload LIKE '%\"nodeId\":\"home\"%'", cancelledId), 'Cancel fixture never reached actual assertion');
  const cancelAck = await request(`${project}/executions/${cancelledId}/cancel`, { method: 'POST' }); assert.equal(cancelAck.cancelRequested, true); assert.notEqual(cancelAck.state, 'completed');
  const cancelExit = await cancellingWorker.done; assert.equal(cancelExit.code, 0, cancelExit.stderr);
  const cancelled = await request(`${project}/executions/${cancelledId}`); assert.equal(cancelled.state, 'completed'); assert.equal(cancelled.reportedExecutionStatus, 'cancelled'); assert.equal(cancelled.cleanupState, 'confirmed');
  const cancelledRun = await request(`${project}/runs/${cancelled.caseRuns[0].runId}`); assert.equal(cancelledRun.reportedOutcome, 'cancelled');
  assert.equal(cancelled.evidenceStatus, 'verified'); assert.equal(cancelledRun.evidenceStatus, 'verified'); assert.equal(cancelledRun.terminal, true);
  const cancelledResult = JSON.parse(cancelledRun.resultJson); assert.deepEqual(cancelledResult.cleanupErrors ?? [], []);
  const terminal = JSON.parse(db.get('SELECT payload FROM events WHERE run_id=? ORDER BY sequence DESC LIMIT 1', cancelledRun.id).payload);
  assert.equal(terminal.type, 'run.finished'); assert.equal(terminal.outcome, 'cancelled');
  const cancelledLease = assertSettledLease(cancelled);
  receipt.checks.push({ name: 'actual-cancel-after-assertion-start', status: 'passed', requestMode: 'Trusted fixture enqueue; HTTP cancel and actual Agent delivery', executionId: cancelledId, requestState: cancelAck.state, result: cancelledRun.reportedOutcome, executionStatus: cancelled.reportedExecutionStatus, cleanupState: cancelled.cleanupState, cleanupErrors: cancelledResult.cleanupErrors ?? [], terminalEvent: terminal.type, evidenceStatus: cancelled.evidenceStatus, completionReceipt: cancelledLease.completion_receipt, receiptAcknowledged: true, resourceReleased: true, ownerRetired: true }); console.log('actual cancellation/cleanup PASS');
  assert.deepEqual(historySnapshot(old), before);
  const context = await request(`${project}/context`); assert.equal(context.engine.engineVersion, '0.1.0-alpha.10');
  receipt.context = context.engine;
  }
  receipt.status = 'passed';
} catch (error) {
  receipt.status = 'failed'; receipt.error = error.message; console.error(error.stack); process.exitCode = 1;
} finally {
  for (const owned of activeChildren) { if (process.platform === 'win32') await exec('taskkill.exe', ['/PID', String(owned.pid), '/T', '/F'], { windowsHide: true }).catch(() => {}); else owned.kill(); }
  await app?.close(); await new Promise(done => target.close(done));
  receipt.finishedAt = new Date().toISOString(); await writeFile(join(directory, 'verification.json'), JSON.stringify(receipt, null, 2) + '\n');
  await writeFile(join(outputRoot, 'latest.json'), JSON.stringify({ directory, status: receipt.status }, null, 2) + '\n');
  console.log(JSON.stringify({ status: receipt.status, directory }));
}
