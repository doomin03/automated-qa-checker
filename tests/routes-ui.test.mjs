import test from 'node:test';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {chromium} from 'playwright';
test('production route/404 and development StrictMode route/observer/stale I/O lifecycle',{timeout:90000},async t=>{
 const prod=spawn(process.execPath,[resolve('apps/web/scripts/serve.mjs')],{env:{...process.env,PORT:'4334'},stdio:'pipe',windowsHide:true});
 const dev=spawn(process.execPath,[resolve('apps/web/node_modules/vite/bin/vite.js'),'--host','127.0.0.1','--port','4335','--strictPort'],{cwd:resolve('apps/web'),stdio:'pipe',windowsHide:true});
 let logs='';for(const child of [prod,dev]){child.stdout.resume();child.stderr.on('data',b=>logs+=b);t.after(()=>child.kill());}
 for(const port of [4334,4335]){let ready=false;for(let i=0;i<100;i++){try{if((await fetch(`http://127.0.0.1:${port}/`)).ok){ready=true;break;}}catch{}await new Promise(r=>setTimeout(r,100));}assert(ready,logs);}
 const http=[];for(const [path,status] of [['/',200],['/qa/blueprints',200],['/qa/shared',200],['/api/v1/missing',404],['/assets/missing.js',404],['/qa/missing',404],['/%2e%2e/%2e%2e/package.json',404]]){const response=await fetch('http://127.0.0.1:4334'+path);assert.equal(response.status,status,path);if(status===404)assert.doesNotMatch(await response.text(),/<html/i);http.push({path,status});}
 const browser=await chromium.launch({headless:true});t.after(()=>browser.close());const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.addInitScript(()=>{const intervals=new Set(),pop=new Set();const si=window.setInterval.bind(window),ci=window.clearInterval.bind(window),add=window.addEventListener.bind(window),remove=window.removeEventListener.bind(window);window.setInterval=(fn,ms,...args)=>{const id=si(fn,ms,...args);intervals.add(id);return id;};window.clearInterval=id=>{intervals.delete(id);ci(id);};window.addEventListener=(name,fn,options)=>{if(name==='popstate')pop.add(fn);add(name,fn,options);};window.removeEventListener=(name,fn,options)=>{if(name==='popstate')pop.delete(fn);remove(name,fn,options);};window.qaResources=()=>({intervals:intervals.size,popstate:pop.size});const original=File.prototype.text;File.prototype.text=function(){if(this.name==='slow.json')return new Promise(resolve=>window.qaResolveFile=()=>original.call(this).then(resolve));return original.call(this);};});
 await page.goto('http://127.0.0.1:4335/qa/blueprints');await page.getByRole('heading',{name:'Automated QA · Blueprint',exact:true}).waitFor();
 const baselineResources=await page.evaluate(()=>window.qaResources());
 const base=JSON.parse(await readFile('apps/web/public/demo/blueprint.json','utf8')),events=await readFile('apps/web/public/demo/events.jsonl','utf8');const fresh={...base,name:'latest-user-document'};
 let releaseFetch;const pending=new Promise(r=>releaseFetch=r);await page.route('**/demo/blueprint.json',async route=>{await pending;await route.fulfill({contentType:'application/json',body:JSON.stringify(base)}).catch(()=>{});});
 await page.getByRole('button',{name:'실제 실패 기록 예제'}).click();await page.getByRole('textbox',{name:'Blueprint JSON 편집'}).fill(JSON.stringify(fresh));await page.getByRole('button',{name:'검사 후 화면에 적용'}).click();releaseFetch();await page.waitForTimeout(200);assert.equal(JSON.parse(await page.getByRole('textbox',{name:'Blueprint JSON 편집'}).inputValue()).name,fresh.name);await page.unroute('**/demo/blueprint.json');
 await page.getByTestId('blueprint-file').setInputFiles({name:'slow.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(base))});await page.waitForFunction(()=>!!window.qaResolveFile);await page.getByRole('textbox',{name:'Blueprint JSON 편집'}).fill(JSON.stringify(fresh));await page.getByRole('button',{name:'검사 후 화면에 적용'}).click();await page.evaluate(()=>window.qaResolveFile());assert.equal(JSON.parse(await page.getByRole('textbox',{name:'Blueprint JSON 편집'}).inputValue()).name,fresh.name);
 const samples=[];for(let i=0;i<3;i++){
  await page.getByTestId('blueprint-file').setInputFiles({name:'current.json',mimeType:'application/json',buffer:Buffer.from(JSON.stringify(base))});await page.evaluate(text=>{window.showOpenFilePicker=async()=>[{getFile:async()=>new File([text],'events.jsonl')}];},events);
  await page.getByRole('button',{name:'이벤트 파일 따라가기',exact:true}).click();await page.waitForFunction(()=>document.querySelector('[data-testid="run-outcome"]')?.textContent==='failed');assert.equal((await page.evaluate(()=>window.qaResources())).intervals,baselineResources.intervals+1);
  await page.getByRole('link',{name:'공용 시나리오·실행',exact:true}).click();await page.getByRole('heading',{name:'Automated QA · 공용 시나리오',exact:true}).waitFor();assert.deepEqual(await page.evaluate(()=>window.qaResources()),baselineResources);
  await page.goBack();await page.getByRole('heading',{name:'Automated QA · Blueprint',exact:true}).waitFor();await page.setViewportSize({width:1000+i*50,height:800});samples.push(await page.evaluate(()=>window.qaResources()));
 }
 assert(samples.every(s=>s.intervals===baselineResources.intervals&&s.popstate===baselineResources.popstate));assert.equal(baselineResources.popstate,1);assert.deepEqual(errors,[]);
 await page.goto('http://127.0.0.1:4334/qa/shared');await page.getByRole('heading',{name:'Automated QA · 공용 시나리오',exact:true}).waitFor();await page.reload();await page.getByRole('heading',{name:'Automated QA · 공용 시나리오',exact:true}).waitFor();
 await mkdir('artifacts',{recursive:true});await writeFile('artifacts/web-route-verification.json',JSON.stringify({http,strictModeDevelopment:true,staleFetchPreserved:true,staleFilePreserved:true,baselineResources,routeResourceSamples:samples,productionRefresh:true},null,2));
});
