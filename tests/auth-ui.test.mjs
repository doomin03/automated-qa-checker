import test from 'node:test';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import {resolve} from 'node:path';
import {writeFile} from 'node:fs/promises';
import {chromium} from 'playwright';
import {startAuthFixture} from './auth-fixture.mjs';
test('browser organization login cookie, SDK CSRF connection and logout',{timeout:90000},async t=>{
 const webOrigin='http://127.0.0.1:4326',fixture=await startAuthFixture(webOrigin);t.after(()=>fixture.close());
 const vite=spawn(process.execPath,[resolve('apps/web/node_modules/vite/bin/vite.js'),'preview','--host','127.0.0.1','--port','4326','--strictPort'],{cwd:resolve('apps/web'),windowsHide:true,stdio:'ignore'});t.after(()=>vite.kill());
 for(let i=0;i<100;i++){try{if((await fetch(webOrigin)).ok)break;}catch{}await new Promise(r=>setTimeout(r,100));}
 const browser=await chromium.launch({headless:true});t.after(()=>browser.close());const page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.goto(webOrigin);let section=page.getByRole('region',{name:'공용 시나리오 서버'});
 await section.getByLabel('공유 서버 주소',{exact:true}).fill(fixture.origin);
 await section.getByRole('button',{name:'조직 로그인',exact:true}).click();await page.waitForURL(webOrigin+'/');
 section=page.getByRole('region',{name:'공용 시나리오 서버'});await section.getByLabel('공유 서버 주소',{exact:true}).fill(fixture.origin);await section.getByRole('button',{name:'조직 세션 확인'}).click();
 await section.getByRole('status').filter({hasText:'조직 로그인: organization-user'}).waitFor();
 await section.getByRole('button',{name:'공유 연결',exact:true}).click();await section.getByRole('status').filter({hasText:'조직 인증 사용자: organization-user'}).waitFor();
 // A mutation proves cookie+CSRF generated-client transport; no QA is executed.
 await section.getByRole('button',{name:'현재 XML 초안 저장'}).click();await section.getByRole('button',{name:'검수 승인'}).waitFor();
 await section.getByRole('button',{name:'조직 로그아웃'}).click();await section.getByRole('status').filter({hasText:'로그아웃했습니다'}).waitFor();
 await section.getByRole('button',{name:'조직 세션 확인'}).click();await section.getByRole('alert').waitFor();assert.deepEqual(errors,[]);
 await writeFile('artifacts/organization-web-verification.json',JSON.stringify({localProvider:true,realSlack:false,browserLogin:true,cookieSession:true,csrfMutation:true,logoutRevoked:true,qaExecuted:false}));
});
