import 'reflect-metadata';
import test from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {mkdtemp,readFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {randomUUID} from 'node:crypto';
import {NestFactory} from '@nestjs/core';
import {Module} from '@nestjs/common';
import {AppModule} from '../dist/src/app.module.js';
import {WorkflowModule} from '../dist/src/modules/workflow/workflow.module.js';
import {WorkflowService} from '../dist/src/modules/workflow/workflow.service.js';
import {PlatformService} from '../dist/src/modules/platform/platform.service.js';
import {PlatformRepository} from '../dist/src/modules/platform/platform.repository.js';
import {configureApp} from '../dist/src/config/configure-app.js';

test('workflow HTTP authorization, optimistic revisions, durable outbox and honest comparison',{timeout:120000},async t=>{
 const dataDir=await mkdtemp(join(tmpdir(),'qa-workflow-')),root=resolve('../..');
 const users=['manager','tester','viewer','outside'],tokens=Object.fromEntries(users.map(id=>[id,`${id}-workflow-test-token-32-characters`]));
 const identities={users:users.map(id=>({id,token:tokens[id],active:true})),projects:[{id:'project',name:'Demo'},{id:'other',name:'Other'}],memberships:users.map(id=>({userId:id,projectId:id==='outside'?'other':'project',role:id==='manager'?'qa_manager':id==='viewer'?'viewer':'qa_tester'}))};
 let accepted=false;const deliveries=[];
 const sink=createServer(async(req,res)=>{let body='';for await(const chunk of req)body+=chunk;deliveries.push({key:req.headers['idempotency-key'],body:JSON.parse(body)});res.writeHead(accepted?200:503);res.end('{}');});await new Promise(r=>sink.listen(0,'127.0.0.1',r));t.after(()=>sink.close());
 const env={NODE_ENV:'test',QA_NOTIFICATION_MODE:'local-test',QA_NOTIFICATION_URL:`http://127.0.0.1:${sink.address().port}/notify`};
 let app,workflow,repo,origin,platform;
 async function start(){class Root{}Module({imports:[AppModule,WorkflowModule]})(Root);app=await NestFactory.create(Root,{logger:false});configureApp(app,()=>{});platform=app.get(PlatformService);await platform.start({mode:'test',dataDir,identities,engineCli:resolve(root,'.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'),engineManifest:resolve(root,'apps/app/assets/engine-runtime.json')});workflow=app.get(WorkflowService);workflow.start(env);repo=app.get(PlatformRepository);await app.listen(0,'127.0.0.1');origin=await app.getUrl();}
 await start();t.after(()=>app.close());
 const request=async(path,{user='tester',body,method=body?'PUT':'GET'}={})=>{const res=await fetch(`${origin}/api/v1/projects/project/runs/${path}`,{method,headers:{authorization:`Bearer ${tokens[user]}`,...(body?{'content-type':'application/json'}:{})},...(body?{body:JSON.stringify(body)}:{})});return{status:res.status,body:await res.json()};};
 // Database fixture isolates workflow semantics; these rows are not reported as real executions.
 function seed(id,outcome='passed',snapshot='same') {repo.exec('INSERT INTO runs(id,project_id,owner_id,engine_run_id,attempt,snapshot_hash,engine_version,blueprint_json,flow_hash,node_ids,last_sequence,terminal,outcome,result_json,evidence_status,created_at) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',id,'project','tester',randomUUID(),1,snapshot,'fixture-engine',JSON.stringify({target:{platform:'web'}}),'fixture-flow','[]',2,1,outcome,JSON.stringify({outcome}),'verified',new Date().toISOString());}
 seed('run-a');seed('run-b','failed');
 await t.test('scope, assignee and concurrent revision; immutable outcome',async()=>{
  assert.equal((await request('run-b/work',{user:'outside'})).status,403);
  assert.equal((await request('run-b/work',{user:'viewer',body:{status:'done',assigneeId:null,revision:0}})).status,403);
  assert.equal((await request('run-b/work',{body:{status:'done',assigneeId:'outside',revision:0}})).status,400);
  assert.equal((await request('run-b/work',{body:{status:'done',revision:0}})).status,400);
  repo.exec('UPDATE users SET active=0 WHERE id=?','viewer');
  assert.equal((await request('run-b/work',{body:{status:'done',assigneeId:'viewer',revision:0}})).status,400);
  repo.exec('UPDATE users SET active=1 WHERE id=?','viewer');
  const updates=await Promise.all([1,2].map(()=>request('run-b/work',{body:{status:'in_progress',assigneeId:'tester',revision:0}})));
  assert.deepEqual(updates.map(r=>r.status).sort(),[200,409]);assert.equal(repo.get('SELECT outcome FROM runs WHERE id=?','run-b').outcome,'failed');
  assert.equal((await request('run-b/work')).body.revision,1);
 });
 await t.test('no profile evidence means incomparable, not invented browser/OS equality',async()=>{
  assert.equal((await request('run-b/comparison')).body.reason,'ENVIRONMENT_EVIDENCE_ABSENT');
  assert.equal((await request('run-b/baseline',{body:{baselineRunId:'run-a'}})).status,409);
 });
 await t.test('verified profile/reference identity and same snapshot bound outcome comparison',async()=>{
  // Exact Platform download results are fixtures for comparison policy, not artifact integrity acceptance.
  const originalGet=platform.getRun.bind(platform),originalDownload=platform.download.bind(platform);
  platform.getRun=async(user,p,id)=>({...await originalGet(user,p,id),artifacts:[{artifactId:'check',mimeType:'application/json'}]});
  let different=false;platform.download=async(_u,_p,id)=>({base64:Buffer.from(JSON.stringify({schemaVersion:'qa.checkReport/v1',nodeId:'check',kind:'image',verdict:'passed',profileHash:'sha256:'+((different&&id==='run-b')?'b':'a').repeat(64),referenceHash:'sha256:'+'c'.repeat(64),reason:'MATCH'})).toString('base64')});
  const compared=await request('run-b/comparison');assert.equal(compared.body.classification,'regression');assert.equal(compared.body.baselineRunId,'run-a');
  assert.equal((await request('run-b/baseline',{body:{baselineRunId:'run-a'}})).status,200);different=true;
  assert.equal((await request('run-b/comparison')).body.reason,'COMPARISON_IDENTITY_MISMATCH');
  const uxBytes=await readFile(new URL('./fixtures/alpha6-ux-profile-report.json',import.meta.url));assert.equal(createHash('sha256').update(uxBytes).digest('hex'),'407707b9e2ab7673b65a63cf65930a32b4f049dc7de693815cdf1b22b0b50b49');
  platform.download=async()=>({base64:uxBytes.toString('base64')});
  assert.equal((await request('run-b/comparison')).body.classification,'regression','actual Engine UX profile report does not require a referenceHash');
  const blocked={...JSON.parse(uxBytes),verdict:'blocked',reason:'PROFILE_MISMATCH'};platform.download=async()=>({base64:Buffer.from(JSON.stringify(blocked)).toString('base64')});
  assert.equal((await request('run-b/comparison')).body.reason,'PROFILE_REFERENCE_UNVERIFIED');
  platform.getRun=originalGet;platform.download=originalDownload;
 });
 let delivery;
 await t.test('manager-only notification identity, failure independent of outcome',async()=>{
  assert.equal((await request('run-b/notifications',{method:'POST'})).status,403);
  delivery=(await request('run-b/notifications',{user:'manager',method:'POST'})).body;
  assert.equal((await request('run-b/notifications',{user:'manager',method:'POST'})).body.id,delivery.id);
  await workflow.drain();assert.equal((await request('run-b/notifications')).body.items[0].state,'retrying');assert.equal(deliveries[0].key,delivery.id);
  assert.equal(repo.get('SELECT outcome FROM runs WHERE id=?','run-b').outcome,'failed');
 });
 await t.test('restart preserves work and same notification retry identity; payload excludes XML/tokens',async()=>{
  await app.close();await start();assert.equal((await request('run-b/work')).body.status,'in_progress');
  accepted=true;repo.exec('UPDATE notification_outbox SET next_at=0,lease_until=0');await workflow.drain();
  const item=(await request('run-b/notifications')).body.items[0];assert.equal(item.state,'delivered');assert.equal(item.attempts,2);assert.equal(deliveries[1].key,delivery.id);assert.deepEqual(deliveries[1].body,deliveries[0].body);
  assert.deepEqual(Object.keys(deliveries[1].body).sort(),['evidenceStatus','projectId','reportedOutcome','runId','schemaVersion','workRevision','workStatus'].sort());
  assert.throws(()=>workflow.start({...env,NODE_ENV:'production'}));
 });
});
