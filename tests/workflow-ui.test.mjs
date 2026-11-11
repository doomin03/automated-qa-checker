import test from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {spawn} from 'node:child_process';
import {readFile,mkdtemp,writeFile} from 'node:fs/promises';
import {resolve,join} from 'node:path';
import {tmpdir} from 'node:os';
import {randomUUID} from 'node:crypto';
import {chromium} from 'playwright';
import {PlatformClient} from '../packages/api-client/dist/platform-client.js';
test('web work state and baseline consume actual design run evidence without changing outcomes',{timeout:120000},async t=>{
 const meta=JSON.parse(await readFile('artifacts/flutter-design/verification.json')),token=randomUUID()+randomUUID(),webOrigin='http://127.0.0.1:4327';
 const identities={users:[{id:'manager',token,active:true}],projects:[{id:'demo',name:'Demo'}],memberships:[{userId:'manager',projectId:'demo',role:'qa_manager'}]};
 const deliveries=[];const sink=createServer(async(req,res)=>{let raw='';for await(const c of req)raw+=c;deliveries.push(JSON.parse(raw));res.end('{}');});await new Promise(r=>sink.listen(0,'127.0.0.1',r));t.after(()=>sink.close());
 const data=await mkdtemp(join(tmpdir(),'qa-work-ui-'));
 const api=spawn(process.execPath,[resolve('apps/server/dist/src/main.js')],{windowsHide:true,stdio:'pipe',env:{...process.env,NODE_ENV:'test',HOST:'127.0.0.1',PORT:'0',QA_AUTH_MODE:'test',QA_DATA_DIR:data,QA_ENGINE_CLI:resolve('.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'),QA_ENGINE_MANIFEST:resolve('apps/app/assets/engine-runtime.json'),QA_LOCAL_IDENTITIES_JSON:JSON.stringify(identities),CORS_ORIGINS:webOrigin,QA_NOTIFICATION_MODE:'local-test',QA_NOTIFICATION_URL:`http://127.0.0.1:${sink.address().port}/fixture`}});t.after(()=>api.kill());api.stderr.resume();let output='';api.stdout.on('data',c=>output+=c);let origin;
 for(let i=0;i<100;i++){const line=output.split('\n').find(l=>l.startsWith('{"event":"listening"'));if(line){origin=JSON.parse(line).url;break;}await new Promise(r=>setTimeout(r,100));}assert(origin);
 const client=new PlatformClient(origin,token);t.after(()=>client.close());const runs={};
 for(const kind of ['pass','fail']){
  const dir=meta[kind],blueprint=JSON.parse(await readFile(join(dir,'blueprint.json'))),result=JSON.parse(await readFile(join(dir,'result.json'))),events=(await readFile(join(dir,'events.jsonl'),'utf8')).trim().split('\n'),start=JSON.parse(events[0]);
  const run=await client.createRun('demo',{engineRunId:start.runId,attempt:start.attempt,engineVersion:result.executed.engineVersion,snapshotHash:result.executed.blueprintSnapshotHash,blueprintJson:JSON.stringify(blueprint),startedEventJson:events[0]},`workflow-${kind}`);
  await client.appendEvents('demo',run.id,events.slice(1));const received=await client.result('demo',run.id,JSON.stringify(result));for(const artifact of received.artifacts)await client.uploadArtifact('demo',run.id,{artifactId:artifact.artifactId,sha256:artifact.sha256,mimeType:artifact.mimeType,base64:(await readFile(join(dir,artifact.name))).toString('base64')});
  runs[kind]=await client.run('demo',run.id);assert.equal(runs[kind].evidenceStatus,'verified');
 }
 const vite=spawn(process.execPath,[resolve('apps/web/node_modules/vite/bin/vite.js'),'preview','--host','127.0.0.1','--port','4327','--strictPort'],{cwd:resolve('apps/web'),windowsHide:true,stdio:'ignore'});t.after(()=>vite.kill());for(let i=0;i<100;i++){try{if((await fetch(webOrigin)).ok)break;}catch{}await new Promise(r=>setTimeout(r,100));}
 const browser=await chromium.launch({headless:true});t.after(()=>browser.close());const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto(webOrigin);
 const shared=page.getByRole('region',{name:'공용 시나리오 서버'});await shared.getByLabel('공유 서버 주소',{exact:true}).fill(origin);await shared.getByLabel('공유 사용자 token',{exact:true}).fill(token);await shared.getByLabel('공유 프로젝트',{exact:true}).fill('demo');await shared.getByRole('button',{name:'공유 연결',exact:true}).click();await shared.getByRole('button',{name:new RegExp(runs.fail.engineRunId)}).click();
 const work=page.getByRole('region',{name:'실행 업무와 비교'});await work.getByLabel('업무 상태',{exact:true}).selectOption('done');await work.getByLabel('담당 사용자 ID').fill('manager');await work.getByRole('button',{name:'업무 변경 저장'}).click();await work.getByText('업무 revision: 1').waitFor();
 assert.equal((await client.run('demo',runs.fail.id)).reportedOutcome,'failed');assert.equal((await client.run('demo',runs.fail.id)).workStatus,'done');
 await work.getByRole('button',{name:'결과 비교',exact:true}).click();await work.getByTestId('run-comparison').filter({hasText:'regression'}).waitFor();
 await work.getByLabel('기준 실행 ID').fill(runs.pass.id);await work.getByRole('button',{name:'기준 실행 명시 선택'}).click();await page.waitForTimeout(200);
 await work.getByRole('button',{name:'로컬 검증 알림 요청 (관리 권한)'}).click();for(let i=0;i<50&&!deliveries.length;i++)await page.waitForTimeout(100);assert.equal(deliveries.length,1);assert.equal(deliveries[0].reportedOutcome,'failed');assert.equal(deliveries[0].workStatus,'done');
 await work.getByRole('button',{name:'알림 상태 조회'}).click();await work.getByText(/"state": "delivered"/).waitFor();assert.deepEqual(errors,[]);
 await writeFile('artifacts/workflow-web-verification.json',JSON.stringify({engineVersion:meta.engineVersion,pass:runs.pass.id,fail:runs.fail.id,sourcePass:meta.pass,sourceFail:meta.fail,artifactIntegrity:'verified',comparison:'regression',workStatus:'done',outcome:'failed',localNotification:true,externalNotification:false}));
});
