import 'reflect-metadata';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../dist/src/app.module.js';
import { configureApp } from '../dist/src/config/configure-app.js';
import { PlatformService } from '../dist/src/modules/platform/platform.service.js';
import { PlatformRepository, sha256 } from '../dist/src/modules/platform/platform.repository.js';
import { AgentService } from '../dist/src/modules/agent/agent.service.js';
import { EngineContractService } from '../dist/src/modules/platform/engine-contract.service.js';
const root = resolve(import.meta.dirname, '../../..');
const example = JSON.parse(await readFile(resolve(root, 'packages/contract/agent-protocol/v0.1.0-draft.1/examples/claim-response.json'), 'utf8'));
const managerToken = 'local-manager-token-for-agent-tests-only';
const identities = { users: [{ id: 'manager', token: managerToken, active: true }], projects: [{ id: 'demo', name: 'Demo' }], memberships: [{ userId: 'manager', projectId: 'demo', role: 'qa_manager' }] };
const capabilities = { platforms: ['web'], actions: ['launch', 'input', 'tap', 'assertText', 'screenshot'] };
async function server(dataDir) {
  const app = await NestFactory.create(AppModule, { logger: false }); configureApp(app, () => {});
  await app.get(PlatformService).start({ mode: 'test', dataDir, identities, engineCli: resolve(root,'.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'), engineManifest: resolve(root,'apps/app/assets/engine-runtime.json') });
  const engine=app.get(EngineContractService); Object.assign(example.lease,{engineVersion:engine.version,engineContractVersion:engine.contractVersion,engineContractSha256:engine.contractSha256});
  const service = app.get(AgentService); service.start(); await app.listen(0, '127.0.0.1');
  const origin = await app.getUrl();
  return { app, service, origin, db: app.get(PlatformRepository), request: async (route, body, token, method='POST') => {
    const response = await fetch(origin + '/api/v1/agent' + route, { method, headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` }, body: JSON.stringify(body) });
    return { status: response.status, body: response.status === 204 ? null : await response.json() };
  } };
}
test('Agent live HTTP durable claims, loss recovery, fenced quarantine and retired owners', { timeout: 120000 }, async t => {
  const dataDir = await mkdtemp(join(tmpdir(), 'qa-agent-')); let s = await server(dataDir);
  try {
    const { token } = s.service.provision('manager', { agentId: 'agent-demo', projectIds: ['demo'], resourceKeys: ['browser-slot-demo', 'second-slot'], capabilities });
    const owner = randomUUID(), reporter = randomUUID();
    const leaseExample = example.lease;
    const claim = { agentId: 'agent-demo', instanceId: owner, claimRequestId: randomUUID(), protocolVersion: leaseExample.protocolVersion, engineVersion: leaseExample.engineVersion, engineContractVersion: leaseExample.engineContractVersion, engineContractSha256: leaseExample.engineContractSha256, resourceKeys: ['browser-slot-demo'], projectIds: ['demo'], capabilities };
    const enqueue = () => s.service.enqueue('manager', { projectId: 'demo', caseId: 'case-1', blueprintJson: leaseExample.cases[0].blueprintJson, executionPolicy: leaseExample.executionPolicy });
    await enqueue();
    assert.equal((await s.request('/claims', claim, managerToken)).status, 401);
    let clock = 1000; s.service.monotonic = () => clock;
    const claimed = await s.request('/claims', claim, token); assert.equal(claimed.status, 200, JSON.stringify(claimed)); const lease = claimed.body.lease;
    const other=s.service.provision('manager',{agentId:'other-agent',projectIds:['demo'],resourceKeys:['browser-slot-demo'],capabilities});
    assert.equal((await s.request('/claims',{...claim,agentId:'other-agent',instanceId:randomUUID(),claimRequestId:randomUUID()},other.token)).status,204);
    assert.equal((await s.request(`/leases/${lease.leaseId}/heartbeat`,{agentId:'agent-demo',instanceId:owner,fence:lease.fence,lastAcknowledgedSequence:0,cleanupState:'unknown'},other.token)).status,403);
    await s.service.enqueue('manager', { projectId: 'demo', caseId: 'case-1', blueprintJson: leaseExample.cases[0].blueprintJson, executionPolicy: { ...leaseExample.executionPolicy, resourceKey: 'second-slot' } });
    assert.equal((await s.request('/claims', { ...claim, claimRequestId: randomUUID(), resourceKeys: ['second-slot'] }, token)).status, 409);
    clock += 1000; const replay = await s.request('/claims', claim, token); assert.equal(replay.body.lease.leaseId, lease.leaseId); assert.equal(replay.body.lease.validForMs, 29000);
    const actualNow=Date.now;
    try{for(const delta of [86400000,-86400000]){Date.now=()=>actualNow()+delta;const adjusted=await s.request('/claims',claim,token);assert.equal(adjusted.body.lease.validForMs,29000);assert.equal(adjusted.body.lease.state,'active');}}finally{Date.now=actualNow;}
    assert.equal((await s.request('/claims', { ...claim, instanceId: reporter }, token)).status, 409);
    assert.equal((await s.request('/claims', { ...claim, resourceKeys: [] }, token)).status, 409);
    const held = { agentId: claim.agentId, instanceId: owner, fence: lease.fence };
    const observed = await s.request('/reconcile', { agentId: claim.agentId, instanceId: reporter, knownLeases: [] }, token);
    assert.equal(observed.body.decisions[0].directive, 'quarantine'); assert.equal(observed.body.decisions[0].lease.leaseId, lease.leaseId);
    const completion = { ...held, caseResults: [], executionStatus: 'blocked', reason: 'preflight denied', cleanupState: 'confirmed', artifactManifest: [] };
    const completed = await s.request(`/leases/${lease.leaseId}/complete`, completion, token, 'PUT'); assert.equal(completed.status, 200, JSON.stringify(completed)); assert.equal(completed.body.deliveryClosed, true);
    const recovered = await s.request('/reconcile', { agentId: claim.agentId, instanceId: reporter, knownLeases: [] }, token);
    assert.equal(recovered.body.decisions[0].completionReceipt, completed.body.completionReceipt); assert.equal(recovered.body.decisions[0].directive, 'observe');
    const release = await s.request('/instances/release', { agentId: claim.agentId, reportingInstanceId: reporter, ownerInstanceId: owner, ownerStopped: true, receipts: [{ leaseId: lease.leaseId, completionReceipt: completed.body.completionReceipt, acceptedThrough: 0 }] }, token);
    assert.equal(release.status, 200, JSON.stringify(release)); assert.equal(release.body.released, true);
    assert.equal((await s.request('/claims', { ...claim, claimRequestId: randomUUID() }, token)).status, 409);
    await enqueue(); const nextClaim = { ...claim, instanceId: reporter, claimRequestId: randomUUID() }; const next = await s.request('/claims', nextClaim, token); assert.equal(next.status, 200); assert.equal(next.body.lease.fence, 2);
    const id = next.body.lease.leaseId; const nextHeld = { agentId: claim.agentId, instanceId: reporter, fence: 2 };
    const event = { schemaVersion: 'qa.runEvent/v1', runId: 'actual-agent-run', attempt: 1, sequence: 1, type: 'run.started', timestamp: '2026-10-31T00:00:00.000Z', blueprintSnapshotHash: next.body.lease.cases[0].blueprintSnapshotHash };
    const eventBody = { ...nextHeld, events: [{ deliverySequence: 1, caseId: 'case-1', engineEventJson: JSON.stringify(event) }] };
    assert.equal((await s.request(`/leases/${id}/events`, { ...eventBody, events: [{ ...eventBody.events[0], caseId: 'unassigned' }] }, token)).status, 409);
    const accepted = await s.request(`/leases/${id}/events`, eventBody, token); assert.equal(accepted.status, 200, JSON.stringify(accepted)); assert.equal(accepted.body.acceptedThrough, 1);
    assert.equal((await s.request(`/leases/${id}/events`, eventBody, token)).body.acceptedThrough, 1);
    assert.equal((await s.request(`/leases/${id}/events`, { ...eventBody, events: [{ ...eventBody.events[0], engineEventJson: JSON.stringify({ ...event, runId: 'wrong' }) }] }, token)).status, 409);
    let clockCalls = 0; const deadline = clock + 30000;
    s.service.monotonic = () => ++clockCalls <= 2 ? clock : deadline + 1;
    assert.equal((await s.request(`/leases/${id}/events`, eventBody, token)).status, 409);
    assert.equal(s.db.get('SELECT accepted_through FROM agent_leases WHERE id=?', id).accepted_through, 1);
    clock += 30001; s.service.monotonic = () => clock;
    assert.equal((await s.request(`/leases/${id}/heartbeat`, { ...nextHeld, lastAcknowledgedSequence: 1, cleanupState: 'confirmed' }, token)).status, 409);
    assert.equal(s.db.get('SELECT lease_id FROM agent_resources WHERE resource_key=?', 'browser-slot-demo').lease_id, id);
    const history = { agentId: claim.agentId, reportingInstanceId: owner, ownerInstanceId: reporter, fence: 2, evidenceRequestId: randomUUID(), events: eventBody.events, caseResults: [], cleanupState: 'confirmed' };
    const recorded = await s.request(`/leases/${id}/historical-evidence`, history, token); assert.equal(recorded.status, 200, JSON.stringify(recorded)); assert.equal(recorded.body.resourceReleased, false);
    assert.equal((await s.request(`/leases/${id}/historical-evidence`, history, token)).body.receiptId, recorded.body.receiptId);
    const historyBytes=Buffer.from('89504e470d0a1a0a00000000','hex'),historyArtifact={caseId:'case-1',path:'history.png',sha256:sha256(historyBytes),size:historyBytes.length,mimeType:'image/png',base64:historyBytes.toString('base64')};
    for(let i=0;i<2;i++)assert.equal((await s.request(`/leases/${id}/historical-evidence`,{...history,evidenceRequestId:randomUUID(),artifact:historyArtifact},token)).status,200);
    assert.equal(s.db.get('SELECT COUNT(*) AS count FROM agent_history_artifacts WHERE lease_id=?',id).count,1);
    assert.equal(s.db.get("SELECT COUNT(*) AS count FROM agent_history WHERE lease_id=? AND payload LIKE '%base64%'",id).count,0);
    assert.equal((await s.request(`/leases/${id}/historical-evidence`,{...history,evidenceRequestId:randomUUID(),artifact:{...historyArtifact,caseId:'constructor'}},token)).status,400);
    assert.equal((await s.request(`/leases/${id}/historical-evidence`,{...history,evidenceRequestId:randomUUID(),events:[{deliverySequence:2,caseId:'case-1',engineEventJson:JSON.stringify({...event,type:'step.started',sequence:2,nodeId:'start',runId:'wrong-history-run'})}]},token)).status,409);
    await s.app.close(); s = await server(dataDir);
    const restart = await s.request('/reconcile', { agentId: claim.agentId, instanceId: owner, knownLeases: [] }, token); assert.equal(restart.body.decisions[0].directive, 'quarantine');
    assert.equal((await s.request('/claims', { ...nextClaim, claimRequestId: randomUUID() }, token)).status, 409);
    const idle = s.service.provision('manager', { agentId: 'idle-agent', projectIds: ['demo'], resourceKeys: ['idle-slot'], capabilities });
    const idleOwner=randomUUID(),idleReporter=randomUUID(),idleClaim={...claim,agentId:'idle-agent',instanceId:idleOwner,claimRequestId:randomUUID(),resourceKeys:['idle-slot']};
    assert.equal((await s.request('/claims',idleClaim,idle.token)).status,204);
    const idleObserved=await s.request('/reconcile',{agentId:'idle-agent',instanceId:idleReporter,knownLeases:[]},idle.token);assert.equal(idleObserved.body.instanceState,'observer');assert.deepEqual(idleObserved.body.decisions,[]);
    assert.equal((await s.request('/instances/release',{agentId:'idle-agent',reportingInstanceId:idleReporter,ownerInstanceId:idleOwner,ownerStopped:true,receipts:[]},idle.token)).body.released,true);
    assert.equal((await s.request('/claims',{...idleClaim,claimRequestId:randomUUID()},idle.token)).status,409);
    assert.equal((await s.request('/claims',{...idleClaim,instanceId:idleReporter,claimRequestId:randomUUID()},idle.token)).status,204);
  } finally { await s.app.close(); await rm(dataDir, { recursive: true, force: true }); }
});
test('opaque resource downloads and reserved case IDs preserve exact data and capability checks',{timeout:90000},async()=>{
  const dataDir=await mkdtemp(join(tmpdir(),'qa-agent-resources-'));const s=await server(dataDir);
  try{
    const {token}=s.service.provision('manager',{agentId:'agent-demo',projectIds:['demo'],resourceKeys:['browser-slot-demo'],capabilities});const fixture=example.lease;
    const bytes=Buffer.from('local-font-fixture');
    await assert.rejects(s.service.enqueue('manager',{projectId:'demo',caseId:'one',blueprintJson:fixture.cases[0].blueprintJson,executionPolicy:fixture.executionPolicy,resources:[{name:'../escape.woff2',bytes,sha256:sha256(bytes),mimeType:'font/woff2'}]}));
    const job=await s.service.enqueue('manager',{projectId:'demo',caseId:'one',blueprintJson:fixture.cases[0].blueprintJson,executionPolicy:fixture.executionPolicy,resources:[{name:'fonts/local.woff2',bytes,sha256:sha256(bytes),mimeType:'font/woff2'}]});
    const instanceId=randomUUID();const claim={agentId:'agent-demo',instanceId,claimRequestId:randomUUID(),protocolVersion:fixture.protocolVersion,engineVersion:fixture.engineVersion,engineContractVersion:fixture.engineContractVersion,engineContractSha256:fixture.engineContractSha256,capabilities,projectIds:['demo'],resourceKeys:['browser-slot-demo']};
    const assigned=await s.request('/claims',claim,token);const lease=assigned.body.lease,resource=lease.cases[0].resources[0];
    const response=await fetch(s.origin+`/api/v1/agent/leases/${lease.leaseId}/resources/${resource.resourceId}?agentId=agent-demo&instanceId=${instanceId}&fence=${lease.fence}`,{headers:{authorization:`Bearer ${token}`}});assert.equal(response.status,200);const downloaded=await response.json();assert.equal(downloaded.base64,bytes.toString('base64'));assert.equal(downloaded.name,'fonts/local.woff2');
    const done=await s.request(`/leases/${lease.leaseId}/complete`,{agentId:'agent-demo',instanceId,fence:lease.fence,caseResults:[],executionStatus:'blocked',reason:'fixture complete',cleanupState:'confirmed',artifactManifest:[]},token,'PUT');assert.equal(done.status,200);
    const ids=['__proto__','constructor','toString'];const nextJob=await s.service.enqueueFixtureCases('manager',{projectId:'demo',cases:ids.map(caseId=>({caseId,blueprintJson:fixture.cases[0].blueprintJson})),stopOnFailure:false,executionPolicy:fixture.executionPolicy});
    const plans=JSON.parse(s.db.get('SELECT plans_json FROM agent_jobs WHERE id=?',nextJob).plans_json);assert.deepEqual(Object.keys(plans).sort(),[...ids].sort());for(const id of ids)assert.equal(plans[id].blueprintSnapshotHash,fixture.cases[0].blueprintSnapshotHash);
    assert.equal((await s.request('/claims',{...claim,claimRequestId:randomUUID(),capabilities:{platforms:['web'],actions:[]}},token)).status,204);
    const next=await s.request('/claims',{...claim,claimRequestId:randomUUID()},token);assert.equal(next.status,200);assert.deepEqual(next.body.lease.cases.map(item=>item.caseId),ids);
    const event={schemaVersion:'qa.runEvent/v1',runId:'reserved-case-run',attempt:1,sequence:1,type:'run.started',timestamp:'2026-10-31T00:00:00.000Z',blueprintSnapshotHash:fixture.cases[0].blueprintSnapshotHash};
    const accepted=await s.request(`/leases/${next.body.lease.leaseId}/events`,{agentId:'agent-demo',instanceId,fence:next.body.lease.fence,events:[{caseId:'__proto__',deliverySequence:1,engineEventJson:JSON.stringify(event)}]},token);assert.equal(accepted.status,200,JSON.stringify(accepted));
  }finally{await s.app.close();await rm(dataDir,{recursive:true,force:true});}
});
test('concurrent identical completion preserves one immutable receipt and late deliveries cannot reopen it', { timeout: 60000 }, async () => {
  const dataDir = await mkdtemp(join(tmpdir(), 'qa-agent-complete-')); const s = await server(dataDir);
  try {
    const { token } = s.service.provision('manager', { agentId: 'agent-demo', projectIds: ['demo'], resourceKeys: ['browser-slot-demo'], capabilities });
    const fixture = example.lease;
    await s.service.enqueue('manager', { projectId: 'demo', caseId: 'case-1', blueprintJson: fixture.cases[0].blueprintJson, executionPolicy: fixture.executionPolicy });
    const instanceId = randomUUID();
    const claimed = await s.request('/claims', { agentId: 'agent-demo', instanceId, claimRequestId: randomUUID(), protocolVersion: fixture.protocolVersion, engineVersion: fixture.engineVersion, engineContractVersion: fixture.engineContractVersion, engineContractSha256: fixture.engineContractSha256, capabilities, projectIds: ['demo'], resourceKeys: ['browser-slot-demo'] }, token);
    const lease = claimed.body.lease, held = { agentId: 'agent-demo', instanceId, fence: lease.fence };
    const plan = JSON.parse(s.db.get('SELECT plans_json FROM agent_jobs WHERE id=?', lease.executionId).plans_json)['case-1'];
    const start = { schemaVersion: 'qa.runEvent/v1', runId: 'completed-agent-run', attempt: 1, sequence: 1, type: 'run.started', timestamp: '2026-10-31T00:00:00.000Z', blueprintSnapshotHash: plan.blueprintSnapshotHash };
    const terminal = { ...start, sequence: 2, type: 'run.finished', outcome: 'blocked', resultPath: 'result.json' };
    const deliveries = [start,terminal].map(event => ({ deliverySequence: event.sequence, caseId: 'case-1', engineEventJson: JSON.stringify(event) }));
    assert.equal((await s.request(`/leases/${lease.leaseId}/events`, { ...held, events: deliveries }, token)).status, 200);
    const result = { schemaVersion: 'qa.result/v1', runId: start.runId, attempt: 1, status: 'finished', outcome: 'blocked', startedAt: start.timestamp, finishedAt: start.timestamp, artifacts: [], executed: { engineVersion: plan.engineVersion, platform: 'web', flowSnapshotHash: plan.flowSnapshotHash, blueprintSnapshotHash: plan.blueprintSnapshotHash }, visitedNodes: [], unvisitedNodes: plan.nodeOrder, cleanupErrors: [] };
    const body = { ...held, caseResults: [{ caseId: 'case-1', resultJson: JSON.stringify(result) }], executionStatus: 'finished', reason: null, cleanupState: 'confirmed', artifactManifest: [] };
    // Synchronize the evidence IO boundary to ensure both requests observe reporting before one closes.
    const platform = s.app.get(PlatformService), refresh = platform.refreshEvidence.bind(platform); let arrivals = 0; let release;
    const barrier = new Promise(resolve => { release = resolve; });
    platform.refreshEvidence = async id => { await refresh(id); if (++arrivals === 2) release(); await barrier; };
    const responses = await Promise.all([s.request(`/leases/${lease.leaseId}/complete`, body, token, 'PUT'), s.request(`/leases/${lease.leaseId}/complete`, body, token, 'PUT')]);
    for (const response of responses) assert.equal(response.status, 200, JSON.stringify(response));
    assert.equal(responses[0].body.completionReceipt, responses[1].body.completionReceipt); assert.equal(responses[0].body.deliveryClosed, true);
    assert.equal((await s.request(`/leases/${lease.leaseId}/events`, { ...held, events: deliveries }, token)).status, 409);
    const originalResult=s.db.get('SELECT result_json FROM runs WHERE engine_run_id=?',start.runId).result_json;
    await s.service.enqueue('manager',{projectId:'demo',caseId:'case-1',blueprintJson:fixture.cases[0].blueprintJson,executionPolicy:fixture.executionPolicy});
    let time=1000;s.service.monotonic=()=>time;
    const next=await s.request('/claims',{agentId:'agent-demo',instanceId,claimRequestId:randomUUID(),protocolVersion:fixture.protocolVersion,engineVersion:fixture.engineVersion,engineContractVersion:fixture.engineContractVersion,engineContractSha256:fixture.engineContractSha256,capabilities,projectIds:['demo'],resourceKeys:['browser-slot-demo']},token);
    assert.equal(next.status,200);const pending=next.body.lease;
    const recoveryInput={requestId:randomUUID(),resourceKey:pending.resourceKey,fence:pending.fence,reason:'Local fixture child and browser confirmed stopped',ownerProcessesStopped:true,externalSessionsStopped:true};
    const recover=async body=>{const response=await fetch(s.origin+`/api/v1/projects/demo/executions/${pending.executionId}/recovery`,{method:'POST',headers:{authorization:`Bearer ${managerToken}`,'content-type':'application/json'},body:JSON.stringify(body)});return{status:response.status,body:await response.json()};};
    assert.equal((await recover(recoveryInput)).status,409);time+=30001;
    const recovered=await recover(recoveryInput);assert.equal(recovered.status,200,JSON.stringify(recovered));assert.equal(recovered.body.recovery.priorFence,pending.fence);assert.equal(recovered.body.recovery.newFence,pending.fence+1);
    assert.deepEqual((await recover(recoveryInput)).body,recovered.body);assert.equal((await recover({...recoveryInput,reason:'changed'})).status,409);
    const reporter=randomUUID();const observed=await s.request('/reconcile',{agentId:'agent-demo',instanceId:reporter,knownLeases:[]},token);const decision=observed.body.decisions.find(d=>d.lease.leaseId===pending.leaseId);
    assert.equal(decision.lease.state,'recovered');assert.equal(decision.directive,'observe');assert.equal(decision.deliveryClosed,false);assert.equal(decision.completionReceipt,null);assert.equal(decision.cleanupState,'unknown');assert.equal(decision.evidenceStatus,'pending');
    assert.deepEqual(decision.operatorRecovery,recovered.body.recovery);assert.equal(s.db.get('SELECT result_json FROM runs WHERE engine_run_id=?',start.runId).result_json,originalResult);
    const released=await s.request('/instances/release',{agentId:'agent-demo',reportingInstanceId:reporter,ownerInstanceId:instanceId,ownerStopped:true,receipts:[{leaseId:lease.leaseId,completionReceipt:responses[0].body.completionReceipt,acceptedThrough:2}]},token);assert.equal(released.status,200);assert.equal(released.body.released,true);assert.equal(released.body.remainingReceipts,0);
  } finally { await s.app.close(); await rm(dataDir, { recursive: true, force: true }); }
});

test('more than one hundred completed leases reconcile in pages and release by cumulative receipt subsets', {timeout:90000}, async()=>{
  const dataDir=await mkdtemp(join(tmpdir(),'qa-agent-history-')),s=await server(dataDir);
  try{
    const {token}=s.service.provision('manager',{agentId:'agent-demo',projectIds:['demo'],resourceKeys:['browser-slot-demo'],capabilities});
    const fixture=example.lease,id=await s.service.enqueue('manager',{projectId:'demo',caseId:'case-1',blueprintJson:fixture.cases[0].blueprintJson,executionPolicy:fixture.executionPolicy});
    const row=s.db.get('SELECT * FROM agent_jobs WHERE id=?',id),prepared={projectId:'demo',policy:JSON.parse(row.policy),cases:JSON.parse(row.cases_json),plans:JSON.parse(row.plans_json),suitePolicy:JSON.parse(row.suite_policy),engineVersion:row.engine_version,engineContractVersion:row.contract_version,engineContractSha256:row.contract_hash};
    const instanceId=randomUUID(),claim={agentId:'agent-demo',instanceId,protocolVersion:fixture.protocolVersion,engineVersion:fixture.engineVersion,engineContractVersion:fixture.engineContractVersion,engineContractSha256:fixture.engineContractSha256,capabilities,projectIds:['demo'],resourceKeys:['browser-slot-demo']},receipts=[];
    for(let index=0;index<101;index++){
      if(index)s.db.transaction(()=>s.service.queuePrepared('manager',prepared));
      const response=await s.request('/claims',{...claim,claimRequestId:randomUUID()},token);assert.equal(response.status,200);const lease=response.body.lease;
      const done=await s.request(`/leases/${lease.leaseId}/complete`,{agentId:'agent-demo',instanceId,fence:lease.fence,caseResults:[],executionStatus:'blocked',reason:'Local preflight fixture',cleanupState:'confirmed',artifactManifest:[]},token,'PUT');assert.equal(done.status,200);assert.equal(done.body.deliveryClosed,true);
      receipts.push({leaseId:lease.leaseId,completionReceipt:done.body.completionReceipt,acceptedThrough:0});
    }
    const reportingInstanceId=randomUUID(),query={agentId:'agent-demo',instanceId:reportingInstanceId,knownLeases:[]};
    const first=await s.request('/reconcile',query,token);assert.equal(first.body.decisions.length,100);assert.equal(first.body.hasMore,true);
    const second=await s.request(`/reconcile?cursor=${encodeURIComponent(first.body.nextCursor)}`,query,token);assert.equal(second.body.decisions.length,1);assert.equal(second.body.hasMore,false);
    const release={agentId:'agent-demo',reportingInstanceId,ownerInstanceId:instanceId,ownerStopped:true};
    const partial=await s.request('/instances/release',{...release,receipts:receipts.slice(0,100)},token);assert.equal(partial.body.released,false);assert.equal(partial.body.remainingReceipts,1);
    const final=await s.request('/instances/release',{...release,receipts:receipts.slice(100)},token);assert.equal(final.body.released,true);assert.equal(final.body.remainingReceipts,0);
    assert.equal((await s.request('/claims',{...claim,claimRequestId:randomUUID()},token)).status,409);
  }finally{await s.app.close();await rm(dataDir,{recursive:true,force:true});}
});

test('an upgraded Agent never receives a job frozen for an older Engine pin',{timeout:30000},async()=>{
  const dataDir=await mkdtemp(join(tmpdir(),'qa-agent-upgrade-')),s=await server(dataDir);
  try{
    const fixture=example.lease;s.service.provision('manager',{agentId:'old-worker',projectIds:['demo'],resourceKeys:['browser-slot-demo'],capabilities});
    const job=await s.service.enqueue('manager',{projectId:'demo',caseId:'case-1',blueprintJson:fixture.cases[0].blueprintJson,executionPolicy:fixture.executionPolicy});
    const engine=s.app.get(EngineContractService),oldVersion=engine.version;engine.version='0.1.0-upgrade-fixture';
    try{
      const {token}=s.service.provision('manager',{agentId:'new-worker',projectIds:['demo'],resourceKeys:['browser-slot-demo'],capabilities});
      const response=await s.request('/claims',{agentId:'new-worker',instanceId:randomUUID(),claimRequestId:randomUUID(),protocolVersion:fixture.protocolVersion,engineVersion:engine.version,engineContractVersion:engine.contractVersion,engineContractSha256:engine.contractSha256,capabilities,projectIds:['demo'],resourceKeys:['browser-slot-demo']},token);
      assert.equal(response.status,204);const row=s.db.get('SELECT state,block_reason,engine_version FROM agent_jobs WHERE id=?',job);assert.equal(row.state,'blocked');assert.equal(row.block_reason,'engine_pin_incompatible');assert.equal(row.engine_version,oldVersion);assert.equal(s.db.get('SELECT COUNT(*) AS count FROM runs').count,0);
    }finally{engine.version=oldVersion;}
  }finally{await s.app.close();await rm(dataDir,{recursive:true,force:true});}
});

test('reconcile enforces its byte budget before the count limit without losing outstanding leases',{timeout:90000},async()=>{
  const dataDir=await mkdtemp(join(tmpdir(),'qa-agent-byte-page-')),s=await server(dataDir);
  try{
    const fixture=example.lease,{token}=s.service.provision('manager',{agentId:'agent-demo',projectIds:['demo'],resourceKeys:['browser-slot-demo'],capabilities});
    const seed=await s.service.enqueue('manager',{projectId:'demo',caseId:'case-1',blueprintJson:fixture.cases[0].blueprintJson,executionPolicy:fixture.executionPolicy});
    const row=s.db.get('SELECT * FROM agent_jobs WHERE id=?',seed),original=JSON.parse(row.cases_json)[0],plan=JSON.parse(row.plans_json)['case-1'];
    s.service.cancel('manager','demo',seed);
    // Valid JSON whitespace changes wire bytes, never the parsed Blueprint or its canonical hash.
    const cases=Array.from({length:8},(_,index)=>({...original,caseId:`case-${index}`,blueprintJson:' '.repeat(780000)+original.blueprintJson}));
    for(const item of cases)assert.deepEqual(JSON.parse(item.blueprintJson),plan.blueprint);
    const prepared={projectId:'demo',policy:JSON.parse(row.policy),cases,plans:Object.fromEntries(cases.map(item=>[item.caseId,plan])),suitePolicy:JSON.parse(row.suite_policy),engineVersion:row.engine_version,engineContractVersion:row.contract_version,engineContractSha256:row.contract_hash};
    const instanceId=randomUUID(),ids=[];
    for(let index=0;index<2;index++){
      s.db.transaction(()=>s.service.queuePrepared('manager',prepared));
      const claimed=await s.request('/claims',{agentId:'agent-demo',instanceId,claimRequestId:randomUUID(),protocolVersion:fixture.protocolVersion,engineVersion:fixture.engineVersion,engineContractVersion:fixture.engineContractVersion,engineContractSha256:fixture.engineContractSha256,capabilities,projectIds:['demo'],resourceKeys:['browser-slot-demo']},token);
      assert.equal(claimed.status,200);const lease=claimed.body.lease;ids.push(lease.leaseId);assert.ok(Buffer.byteLength(JSON.stringify(claimed.body))<8*1024*1024);
      assert.equal((await s.request(`/leases/${lease.leaseId}/complete`,{agentId:'agent-demo',instanceId,fence:lease.fence,caseResults:[],executionStatus:'blocked',reason:'Byte budget fixture; no Engine execution',cleanupState:'confirmed',artifactManifest:[]},token,'PUT')).status,200);
    }
    const input={agentId:'agent-demo',instanceId:randomUUID(),knownLeases:[]};
    const first=await s.request('/reconcile',input,token);assert.equal(first.body.decisions.length,1);assert.equal(first.body.hasMore,true);assert.ok(Buffer.byteLength(JSON.stringify(first.body))<8*1024*1024);
    const second=await s.request(`/reconcile?cursor=${encodeURIComponent(first.body.nextCursor)}`,input,token);assert.equal(second.body.decisions.length,1);assert.equal(second.body.hasMore,false);assert.ok(Buffer.byteLength(JSON.stringify(second.body))<8*1024*1024);
    assert.deepEqual([...first.body.decisions,...second.body.decisions].map(item=>item.lease.leaseId),ids);
  }finally{await s.app.close();await rm(dataDir,{recursive:true,force:true});}
});
