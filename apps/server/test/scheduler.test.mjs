import 'reflect-metadata';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm } from 'node:fs/promises';
import { randomUUID } from 'node:crypto';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../dist/src/app.module.js';
import { configureApp } from '../dist/src/config/configure-app.js';
import { PlatformService } from '../dist/src/modules/platform/platform.service.js';
import { EngineContractService } from '../dist/src/modules/platform/engine-contract.service.js';
import { PlatformRepository } from '../dist/src/modules/platform/platform.repository.js';
import { AgentService } from '../dist/src/modules/agent/agent.service.js';
import { SchedulerService } from '../dist/src/modules/scheduler/scheduler.service.js';
import { SuiteService } from '../dist/src/modules/suite/suite.service.js';
import { localInstants } from '../dist/src/modules/scheduler/weekly-time.js';
const root = resolve(import.meta.dirname,'../../..');
test('IANA weekly time resolves gaps, earliest overlap and half-hour offsets exactly',()=>{
  assert.deepEqual(localInstants('2026-03-08','02:30','America/New_York'),[]);
  assert.deepEqual(localInstants('2026-11-01','01:30','America/New_York').map(time=>new Date(time).toISOString()),['2026-11-01T05:30:00.000Z','2026-11-01T06:30:00.000Z']);
  assert.deepEqual(localInstants('2026-11-02','12:00','Asia/Kolkata').map(time=>new Date(time).toISOString()),['2026-11-02T06:30:00.000Z']);
});
test('published schedule occurrence is unique across double tick/restart and preserves missed/cancel semantics',{timeout:120000},async()=>{
  const dataDir=await mkdtemp(join(tmpdir(),'qa-scheduler-'));
  const users=['author','reviewer','viewer','tester'],tokens=Object.fromEntries(users.map(id=>[id,`${id}-scheduler-fixture-token-for-tests`]));
  const identities={users:users.map(id=>({id,token:tokens[id],active:true})),projects:[{id:'demo',name:'Demo'}],memberships:users.map(id=>({userId:id,projectId:'demo',role:id==='viewer'?'viewer':id==='tester'?'qa_tester':'qa_manager'}))};
  let time=Date.parse('2026-11-02T00:00:00Z'),app,platform,agents,scheduler,db,origin;
  async function start(){app=await NestFactory.create(AppModule,{logger:false});configureApp(app,()=>{});platform=app.get(PlatformService);await platform.start({mode:'test',dataDir,identities,engineCli:resolve(root,'.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'),engineManifest:resolve(root,'apps/app/assets/engine-runtime.json')});agents=app.get(AgentService);agents.start();const suites=app.get(SuiteService);suites.start();agents.registerSuiteResolver(suites.resolvePublished.bind(suites));scheduler=app.get(SchedulerService);scheduler.clock=()=>time;scheduler.start(false);db=app.get(PlatformRepository);await app.listen(0,'127.0.0.1');origin=await app.getUrl();}
  await start();
  const request=async(path,{body,user='author',method=body?'POST':'GET'}={})=>{const response=await fetch(origin+'/api/v1/projects/demo'+path,{method,headers:{authorization:`Bearer ${tokens[user]}`,...(body?{'content-type':'application/json'}:{})},...(body?{body:JSON.stringify(body)}:{})});return{status:response.status,body:await response.json()};};
  try{
    agents.provision('author',{agentId:'scheduler-worker',projectIds:['demo'],resourceKeys:['web-slot'],capabilities:{platforms:['web'],actions:['launch','tap','input','assertText','screenshot']}});
    const engineVersion=app.get(EngineContractService).version;
    const xml=await readFile(resolve(root,`.local/engine/node_modules/automated-qa-engine/contracts/releases/qa-blueprint-${engineVersion}.xml`),'utf8');
    const draft=await platform.createDraft('author','demo',{packageId:'scheduled-case',title:'Scheduled case',xml,dependencies:[]});platform.review('reviewer','demo',draft.id);const version=await platform.publish('author','demo',draft.id,'1.0.0','schedule-case-1');
    const input={versionId:version.id,suiteVersionId:null,sha256:version.sha256,executionPolicy:{resourceKey:'web-slot',platform:'web',allowedOrigins:['http://127.0.0.1:4317'],nativeApps:[],secretRefs:[],allowProduction:false},timezone:'UTC',weekdays:[1],localTime:'00:01',latenessSeconds:120,enabled:true};
    assert.equal((await request('/schedules',{body:input,user:'viewer'})).status,403);
    assert.equal((await request('/schedules',{body:{...input,timezone:'Not/AZone'}})).status,400);
    const created=await request('/schedules',{body:input});assert.equal(created.status,201,JSON.stringify(created));const id=created.body.id;
    time+=60000;await request(`/schedules/${id}/enabled`,{method:'PUT',body:{enabled:true}});scheduler.tick();scheduler.tick();assert.equal(db.get('SELECT COUNT(*) AS total FROM schedule_occurrences WHERE schedule_id=?',id).total,1);assert.equal(db.get('SELECT COUNT(*) AS total FROM agent_jobs').total,1);
    await app.close();await start();scheduler.tick();assert.equal(db.get('SELECT COUNT(*) AS total FROM agent_jobs').total,1);
    const occurrence=(await request(`/schedules/${id}/occurrences`)).body.items[0];assert.equal(occurrence.state,'queued');assert.equal(occurrence.occurrenceAt,'2026-11-02T00:01:00.000Z');
    time+=120001;scheduler.tick();const missed=(await request(`/schedules/${id}/occurrences`)).body.items[0];assert.equal(missed.state,'missed');assert.equal(missed.reason,'no_eligible_agent_or_resource');
    const prepared=await agents.preparePublished('author','demo',input);assert.equal(prepared.cases[0].publishedVersion.sha256,version.sha256);
    const job=db.transaction(()=>agents.queuePrepared('author',prepared));
    const managerView=(await request(`/executions/${job}`)).body;assert.equal(managerView.resourceKey,'web-slot');assert.equal(managerView.fence,null);assert.equal(managerView.operatorRecovery,null);
    let monotonic=1000;agents.monotonic=()=>monotonic;
    const owner=randomUUID(),claimed=agents.claim('scheduler-worker',{agentId:'scheduler-worker',instanceId:owner,claimRequestId:randomUUID(),protocolVersion:'0.1.0-draft.1',engineVersion:prepared.engineVersion,engineContractVersion:prepared.engineContractVersion,engineContractSha256:prepared.engineContractSha256,projectIds:['demo'],resourceKeys:['web-slot'],capabilities:{platforms:['web'],actions:['launch','tap','input','assertText','screenshot']}});
    assert.equal(claimed.lease.executionId,job);
    const active=(await request(`/executions/${job}`)).body;assert.equal(active.fence,claimed.lease.fence);assert.equal(active.cleanupState,'unknown');
    const recovery={requestId:randomUUID(),resourceKey:'web-slot',fence:active.fence,reason:'Local test confirms stopped child and browser',ownerProcessesStopped:true,externalSessionsStopped:true};
    for(const user of ['viewer','tester']) { const view=(await request(`/executions/${job}`,{user})).body;for(const key of ['resourceKey','fence','cleanupState','operatorRecovery'])assert.equal(view[key],null);assert.equal((await request(`/executions/${job}/recovery`,{user,body:recovery})).status,403); }
    assert.equal((await request(`/executions/${job}/recovery`,{body:recovery})).status,409);
    monotonic+=30001;const recovered=await request(`/executions/${job}/recovery`,{body:recovery});assert.equal(recovered.status,200,JSON.stringify(recovered));
    assert.deepEqual((await request(`/executions/${job}/recovery`,{body:recovery})).body,recovered.body);
    const recoveredView=(await request(`/executions/${job}`)).body;assert.equal(recoveredView.state,'recovered');assert.equal(recoveredView.cleanupState,'unknown');assert.equal(recoveredView.operatorRecovery.priorFence,active.fence);assert.equal(recoveredView.operatorRecovery.newFence,active.fence+1);assert.equal(recoveredView.reportedExecutionStatus,null);
    assert.equal((await request(`/schedules/${id}/enabled`,{method:'PUT',body:{enabled:false}})).status,200);
    time+=7*86400000;scheduler.tick();assert.equal(db.get('SELECT COUNT(*) AS total FROM schedule_occurrences WHERE schedule_id=?',id).total,1);
    await request(`/schedules/${id}/enabled`,{method:'PUT',body:{enabled:true}});scheduler.tick();assert.equal(db.get('SELECT COUNT(*) AS total FROM schedule_occurrences WHERE schedule_id=?',id).total,1);
    // Independent schedules retain progress when one stored configuration is invalid.
    const source=db.get('SELECT * FROM schedules WHERE id=?',id),base=Date.parse('2026-11-16T00:00:00Z');time=base+60000;
    const insert=(key,config,pin=prepared)=>db.exec('INSERT INTO schedules VALUES(?,?,?,?,?,?,?,?)',key,'demo','author',JSON.stringify(config),JSON.stringify(pin),1,base,base);
    insert('bad-zone',{...input,timezone:'Invalid/StoredZone'});insert('good-after-bad',input);insert('old-engine',input,{...prepared,engineVersion:'old-engine'});insert('exact-deadline',{...input,localTime:'00:00',latenessSeconds:60});
    // Exact midnight occurrence needs the scan cursor just before midnight.
    db.exec('UPDATE schedules SET last_scanned_at=? WHERE id=?',base-1,'exact-deadline');
    scheduler.tick();
    assert.equal(db.get('SELECT state FROM schedule_occurrences WHERE schedule_id=?','good-after-bad').state,'queued');
    assert.equal(db.get('SELECT reason FROM schedule_occurrences WHERE schedule_id=?','old-engine').reason,'engine_pin_incompatible');
    assert.equal(db.get('SELECT reason FROM schedule_occurrences WHERE schedule_id=?','exact-deadline').reason,'scheduler_late');
    assert.equal(db.get('SELECT last_scanned_at FROM schedules WHERE id=?','bad-zone').last_scanned_at,base);
    assert.ok(db.get("SELECT id FROM audit WHERE action='schedule.tick.failed' AND resource_id='bad-zone'"));
    assert.throws(()=>db.transaction(()=>agents.queuePrepared('author',{...prepared,engineContractSha256:'0'.repeat(64)})),/incompatible/);
  }finally{await app.close();await rm(dataDir,{recursive:true,force:true});}
});
