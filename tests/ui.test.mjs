import test from 'node:test';
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { readFile,mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { chromium } from 'playwright';
test('Blueprint browser import, real failure replay, validation and live-file updates',async t=>{
 const port=4319,origin='http://127.0.0.1:'+port;
 const server=spawn(process.execPath,[resolve('apps/web/node_modules/vite/bin/vite.js'),'preview','--host','127.0.0.1','--port',String(port),'--strictPort'],{cwd:resolve('apps/web'),windowsHide:true,stdio:'pipe'});
 let stderr='';server.stderr.on('data',c=>stderr+=c);server.stdout.resume();
 t.after(()=>{server.kill();});
 let ready=false;
 for(let i=0;i<100;i++){try{if((await fetch(origin)).ok){ready=true;break;}}catch{}await new Promise(r=>setTimeout(r,100));}
 assert(ready,'Preview server did not start: '+stderr);
 const browser=await chromium.launch({headless:true});t.after(()=>browser.close());
 const page=await browser.newPage({viewport:{width:1280,height:900}});
 const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(origin);
 await page.getByRole('heading',{name:'Automated QA · Blueprint'}).waitFor();
 assert.equal(await page.getByTestId('run-outcome').innerText(),'not_started');
 await page.getByRole('button',{name:'실제 실패 기록 예제'}).click();
 await page.waitForFunction(()=>document.querySelector('[data-testid="run-outcome"]')?.textContent==='failed');
 assert.match(await page.getByTestId('node-home').innerText(),/실패/);
 assert.match(await page.getByTestId('node-end').innerText(),/미실행/);
 await page.getByRole('button',{name:'처음부터 재생'}).click();
 await page.getByRole('button',{name:'일시정지'}).click();
 const range=page.getByRole('slider');
 await range.fill('1');assert.equal(await page.getByTestId('run-outcome').innerText(),'running');
 const blueprint=await readFile('apps/web/public/demo/blueprint.json','utf8');
 const eventText=await readFile('apps/web/public/demo/events.jsonl','utf8');
 await page.getByTestId('blueprint-file').setInputFiles({name:'example.json',mimeType:'application/json',buffer:Buffer.from(blueprint)});
 assert.equal(await page.getByTestId('run-outcome').innerText(),'not_started');
 const invalid=JSON.parse(blueprint);invalid.flow.nodes[1].action='shell';
 await page.getByRole('textbox',{name:'Blueprint JSON 편집'}).fill(JSON.stringify(invalid));
 await page.getByRole('button',{name:'검사 후 화면에 적용'}).click();
 assert.match(await page.getByRole('alert').innerText(),/규격 오류/);
 await page.getByRole('textbox',{name:'Blueprint JSON 편집'}).fill(blueprint);
 await page.getByRole('button',{name:'검사 후 화면에 적용'}).click();
 // Exercise file-follow UI with a deterministic browser FileSystemHandle substitute.
 await page.evaluate(text=>{
   window.qaLiveText=text;
   window.showOpenFilePicker=async()=>[{getFile:async()=>new File([window.qaLiveText],'events.jsonl')}];
 },eventText.split('\n')[0]+'\n');
 await page.getByRole('button',{name:'이벤트 파일 따라가기',exact:true}).click();
 await page.waitForFunction(()=>document.querySelector('[data-testid="run-outcome"]')?.textContent==='running');
 await page.evaluate(text=>{window.qaLiveText=text;},eventText);
 await page.waitForFunction(()=>document.querySelector('[data-testid="run-outcome"]')?.textContent==='failed');
 await page.getByRole('button',{name:'따라가기 중지'}).click();
 const b=JSON.parse(blueprint);b.name='<img src=x onerror=alert(1)>';
 await page.getByTestId('blueprint-file').setInputFiles({name:'escaped.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(b))});
 assert.equal(await page.locator('img').count(),0);
 await page.getByRole('button',{name:'실제 실패 기록 예제'}).click();
 await page.waitForFunction(()=>document.querySelector('[data-testid="run-outcome"]')?.textContent==='failed');
 await mkdir('artifacts',{recursive:true});await page.screenshot({path:'artifacts/blueprint-preview.png',fullPage:true});
 assert.deepEqual(errors,[]);
});

