import { chromium } from 'playwright';
import { mkdir, writeFile, readFile } from 'node:fs/promises';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { dirname, join, resolve } from 'node:path';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
const root=dirname(fileURLToPath(import.meta.url));
await mkdir(join(root,'screenshots'),{recursive:true});
const browser=await chromium.launch({headless:true});
const page=await browser.newPage({viewport:{width:1440,height:1000},deviceScaleFactor:1});
const checks=[],errors=[],requests=[];
page.on('pageerror',e=>errors.push(e.message));
page.on('request',r=>{if(/^https?:/.test(r.url()))requests.push(r.url());});
async function shot(name){await page.screenshot({path:join(root,'screenshots',name+'.png'),fullPage:true});}
async function text(s){return page.locator(s).textContent();}
async function check(name,run){await run();checks.push(name);}
async function editor(){await page.locator('[data-route="editor"]').first().click();}
async function runCase(value){await editor();await page.locator('details summary').click();await page.locator('#demo-outcome').selectOption(value);await page.locator('#run').click();if(value==='passed'||value==='failed')await page.waitForFunction(()=>!document.querySelector('#cancel-run'));}
try{
  await page.goto(pathToFileURL(join(root,'index.html')).href);
  await check('Local HTML opens without network or page errors',async()=>{assert.match(await text('h1'),/시나리오/);});
  await shot('01-scenarios');
  await check('Scenario search and empty state',async()=>{await page.locator('#search').fill('없는 이름');assert(await page.locator('#no-match').isVisible());await page.locator('#search').fill('');});
  await page.locator('#open-demo').click();
  await check('Unvalidated draft cannot execute',async()=>assert(await page.locator('#run').isDisabled()));
  await shot('02-flow-unrun');
  await check('Flow selection updates inspector',async()=>{await page.locator('[data-step="1"]').click();assert.match(await text('.inspector'),/username/);await page.locator('[data-step="3"]').click();});
  await page.locator('[data-tab="xml"]').click();
  const fixture=await page.locator('#xml-input').inputValue();
  await shot('03-xml');
  await check('Public alpha6 fixture bytes preserved',async()=>{const expected=await readFile(resolve(root,'../../../.local/engine/node_modules/automated-qa-engine/contracts/releases/qa-blueprint-0.1.0-alpha.6.xml'),'utf8');assert.equal(fixture.replaceAll('\r\n','\n'),expected.replaceAll('\r\n','\n'));});
  await check('Malformed XML blocked without running',async()=>{await page.locator('#xml-input').fill('<blueprint>');await page.locator('#validate').click();assert.match(await text('#validation-title'),/確認|확인/);assert(await page.locator('#run').isDisabled());assert.equal(await text('#run-count'),'00');});
  await shot('04-validation-error');
  await page.locator('#restore').click();
  await page.locator('#validate').click();
  await check('Validation enables but does not start execution',async()=>{assert(await page.locator('#run').isEnabled());assert.equal(await text('#run-count'),'00');});
  await check('Editing invalidates prior validation',async()=>{await page.locator('#xml-input').fill(fixture+'\n');assert(await page.locator('#run').isDisabled());await page.locator('#validate').click();});
  await page.locator('[data-tab="flow"]').click();
  await page.locator('#run').click();
  await shot('05-running');
  await page.waitForFunction(()=>!document.querySelector('#cancel-run'));
  await check('FAIL distinguishes failed assertion and unrun tail',async()=>{assert.match(await text('.result-summary'),/FAIL/);assert.match(await text('.result-detail'),/Welcome guest/);assert.match(await page.locator('.result-step').last().textContent(),/미실행/);});
  await shot('06-failed');
  await runCase('passed');
  await check('PASS includes every demo step',async()=>{assert.equal(await page.locator('.result-step .pill').allTextContents().then(v=>v.filter(t=>t==='PASS').length),5);});
  await shot('07-passed');
  await runCase('infra_error');
  await check('Infrastructure failure does not imply QA failure',async()=>{assert.match(await text('.result-summary'),/환경 오류/);assert.equal(await page.locator('.result-step .pill').allTextContents().then(v=>v.filter(t=>t==='미실행').length),5);});
  await shot('08-environment-error');
  await runCase('unrun');
  await check('Preflight cancellation shows unrun',async()=>assert.match(await text('.result-summary'),/미실행/));
  await shot('09-unrun');
  await editor();await page.locator('details summary').click();await page.locator('#demo-outcome').selectOption('passed');await page.locator('#run').click();await page.locator('#cancel-run').click();
  await check('User can stop demo and no later result overwrites it',async()=>{await page.waitForTimeout(650);assert.match(await text('.result-summary'),/중단/);});
  await check('Share dialog Escape closes and returns focus',async()=>{await page.locator('#share').click();await page.keyboard.press('Escape');assert(!(await page.locator('#share-dialog').isVisible()));assert.equal(await page.evaluate(()=>document.activeElement.id),'share');});
  await page.locator('#share').click();await page.locator('#share-note').fill('로그인 예시의 문구 확인을 검토합니다.');await shot('10-share-draft');await page.locator('#confirm-share').click();
  await check('Draft submission is explicitly simulated',async()=>assert.match(await text('#share-summary'),/실제 전송·버전 발행은 없습니다/));
  await shot('11-sharing');
  await page.locator('[data-route="results"]').first().click();assert.match(await text('.result-summary'),/중단/);
  await check('Sharing does not change QA outcome',async()=>assert.match(await text('.result-summary'),/중단/));
  await editor();
  await check('Desktop has no horizontal overflow at 1440px',async()=>assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)));
  await page.setViewportSize({width:1024,height:900});
  await check('Compact desktop has no horizontal overflow',async()=>assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth)));
  await shot('12-compact');
  assert.deepEqual(errors,[]);assert.deepEqual(requests,[]);
  await writeFile(join(root,'verification.json'),JSON.stringify({status:'passed',scope:'Local HTML interaction mockup, not Engine/product execution',browser:await browser.version(),viewports:[{width:1440,height:1000},{width:1024,height:900}],checks,errors,externalRequests:requests,fixtureSha256:createHash('sha256').update(windowSafe(fixture)).digest('hex'),screenshots:12},null,2)+'\n');
  console.log(JSON.stringify({status:'passed',checks:checks.length,screenshots:12,externalRequests:requests.length}));
}finally{await browser.close();}
function windowSafe(value){return value;}
