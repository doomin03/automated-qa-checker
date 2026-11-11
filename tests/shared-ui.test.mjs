import test from 'node:test';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import {readFile,mkdtemp,writeFile} from 'node:fs/promises';
import {resolve,join} from 'node:path';
import {tmpdir} from 'node:os';
import {randomUUID} from 'node:crypto';
import {chromium} from 'playwright';
import {PlatformClient} from '../packages/api-client/dist/platform-client.js';

test('actual web Registry publishing and cursor progress replay consume Desktop evidence', {timeout:120000},async t=>{
 const metadata=JSON.parse(await readFile('artifacts/flutter-shared/verification.json'));
 const report=metadata.resultDirectory;
 const blueprint=JSON.parse(await readFile(join(report,'blueprint.json'))),result=JSON.parse(await readFile(join(report,'result.json'))),events=(await readFile(join(report,'events.jsonl'),'utf8')).trim().split('\n');
 const data=await mkdtemp(join(tmpdir(),'qa-shared-ui-')),port=4324,webOrigin=`http://127.0.0.1:${port}`;
 const ids=['author','reviewer','tester','viewer'],tokens=Object.fromEntries(ids.map(id=>[id,randomUUID()+randomUUID()]));
 const identities={users:ids.map(id=>({id,token:tokens[id],active:true})),projects:[{id:'demo',name:'Demo'}],memberships:ids.map(id=>({userId:id,projectId:'demo',role:id==='tester'?'qa_tester':id==='viewer'?'viewer':'qa_manager'}))};
 const api=spawn(process.execPath,[resolve('apps/server/dist/src/main.js')],{windowsHide:true,stdio:'pipe',env:{...process.env,NODE_ENV:'test',HOST:'127.0.0.1',PORT:'0',QA_AUTH_MODE:'test',QA_DATA_DIR:data,QA_ENGINE_CLI:resolve('.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'),QA_ENGINE_MANIFEST:resolve('apps/app/assets/engine-runtime.json'),QA_LOCAL_IDENTITIES_JSON:JSON.stringify(identities),CORS_ORIGINS:webOrigin}});
 t.after(()=>api.kill());let output='';api.stdout.on('data',c=>output+=c);api.stderr.resume();let origin;
 for(let i=0;i<100;i++){const line=output.split('\n').find(l=>l.startsWith('{"event":"listening"'));if(line){origin=JSON.parse(line).url;break;}await new Promise(r=>setTimeout(r,100));}assert(origin,'Nest startup');
 const vite=spawn(process.execPath,[resolve('apps/web/node_modules/vite/bin/vite.js'),'preview','--host','127.0.0.1','--port',String(port),'--strictPort'],{cwd:resolve('apps/web'),windowsHide:true,stdio:'ignore'});t.after(()=>vite.kill());
 for(let i=0;i<100;i++){try{if((await fetch(webOrigin)).ok)break;}catch{}await new Promise(r=>setTimeout(r,100));}
 const browser=await chromium.launch({headless:true});t.after(()=>browser.close());const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));await page.goto(webOrigin);
 const share=page.getByRole('region',{name:'공용 시나리오 서버'});
 async function login(id){await share.getByLabel('공유 서버 주소',{exact:true}).fill(origin);await share.getByLabel('공유 사용자 token',{exact:true}).fill(tokens[id]);await share.getByLabel('공유 프로젝트',{exact:true}).fill('demo');await share.getByRole('button',{name:'공유 연결',exact:true}).click();await share.getByRole('status').filter({hasText:`identity: ${id}`}).waitFor();await share.getByRole('button',{name:'현재 XML 초안 저장'}).waitFor({state:'visible'});}
 await page.getByRole('textbox',{name:'Blueprint JSON 편집'}).fill(JSON.stringify(blueprint));await login('author');
 await share.getByRole('button',{name:'현재 XML 초안 저장'}).click();await share.getByRole('button',{name:'검수 승인'}).waitFor();
 await login('reviewer');await share.getByRole('button',{name:'검수 승인'}).click();await page.waitForTimeout(300);await share.getByRole('button',{name:'버전 발행',exact:true}).click();await share.getByRole('button',{name:'user-scenario · 1.0.0'}).waitFor();
 await login('tester');await share.getByRole('button',{name:'user-scenario · 1.0.0'}).click();await share.getByRole('button',{name:'변경 확인 후 버전 고정'}).click();
 const client=new PlatformClient(origin,tokens.tester);t.after(()=>client.close());const first=JSON.parse(events[0]);
 const run=await client.createRun('demo',{engineRunId:first.runId,attempt:first.attempt,engineVersion:result.executed.engineVersion,snapshotHash:result.executed.blueprintSnapshotHash,blueprintJson:JSON.stringify(blueprint),startedEventJson:events[0]},'browser-shared');
 await share.getByRole('button',{name:'실행 목록 새로 고침'}).click();await share.getByRole('button',{name:new RegExp(first.runId)}).click();await page.waitForFunction(()=>document.querySelector('[data-testid="run-outcome"]')?.textContent==='running');
 await share.getByRole('button',{name:'진행 수신 중지'}).click();
 await client.appendEvents('demo',run.id,events.slice(1));const remote=await client.result('demo',run.id,JSON.stringify(result));
 for(const a of remote.artifacts){const bytes=await readFile(join(report,a.name));await client.uploadArtifact('demo',run.id,{artifactId:a.artifactId,sha256:a.sha256,mimeType:a.mimeType,base64:bytes.toString('base64')});}
 await share.getByRole('button',{name:'진행 재연결'}).click();
 await page.waitForFunction(()=>document.querySelector('[data-testid="shared-run-status"]')?.textContent.includes('evidence: verified'));
 assert.equal(await page.getByTestId('run-outcome').innerText(),'passed');await share.getByRole('button',{name:'검증된 증거 이미지 보기'}).click();await share.locator('img').first().waitFor();assert(await share.locator('img').first().evaluate(img=>img.complete&&img.naturalWidth>0));
 assert.deepEqual(errors,[]);await writeFile('artifacts/shared-web-verification.json',JSON.stringify({engineVersion:result.executed.engineVersion,sourceRun:first.runId,serverRun:run.id,webRegistry:true,authenticatedCursorReplay:true,verifiedPngRendered:true,realDeviceVerified:false}));
});
