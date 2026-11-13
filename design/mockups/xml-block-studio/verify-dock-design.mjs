// Preserve prior evidence while exercising the existing interaction suites.
import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import {readFile,writeFile,mkdir,unlink} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const root=new URL('./',import.meta.url),out=new URL('screenshots/dock-design/',root);
await mkdir(out,{recursive:true});
const regressions=[];
for(const [file,kind] of [['verify-terminal.mjs','terminal'],['verify-home.mjs','home'],['verify.mjs','editor'],['../product-planning/verify.mjs','portal']]){
  const original=new URL(file,root),temporary=new URL(`verify-dock-design-${kind}.temporary.mjs`,original);
  let source=await readFile(original,'utf8');
  source=source.replaceAll('./screenshots/multi-terminal/','./screenshots/dock-design/terminal/').replaceAll('./screenshots/home/','./screenshots/dock-design/home/').replaceAll('./screenshots/editor-regression/','./screenshots/dock-design/editor/');
  source=source.replaceAll('verification-terminal.json','verification-dock-design-terminal.json').replaceAll('verification-terminal-failure.json','verification-dock-design-terminal-failure.json').replaceAll('verification-home.json','verification-dock-design-home.json').replaceAll('verification-editor.json','verification-dock-design-editor.json');
  if(kind==='portal')source=source.replaceAll("'verification.json'","'verification-dock-design-portal.json'");
  await writeFile(temporary,source);
  try{
    const result=spawnSync(process.execPath,[fileURLToPath(temporary)],{encoding:'utf8'});
    regressions.push({kind,exitCode:result.status,output:(result.stdout+result.stderr).trim()});
    console.log(regressions.at(-1).output);
    assert.equal(result.status,0,`${kind} regression`);
  }finally{
    await unlink(temporary);
    await writeFile(new URL('verification-dock-design-regressions.json',root),JSON.stringify(regressions,null,2));
  }
}

const browser=await chromium.launch({headless:true}),page=await browser.newPage(),checks=[],errors=[];
page.on('pageerror',e=>errors.push(e.message));
const check=(name,ok)=>{assert(ok,name);checks.push(name);};
try{
  for(const [width,height] of [[1440,900],[1024,768],[800,600]]){
    await page.setViewportSize({width,height});
    await page.goto(new URL('index.html?planning=1&screen=D08',root).href);
    await page.locator('.td-pane').first().waitFor();
    check(`${width}: toolbar fits without overlapping tabs`,await page.evaluate(()=>{
      const tabs=document.querySelector('.td-tabs').getBoundingClientRect(),tools=document.querySelector('.td-tools').getBoundingClientRect();
      return tabs.right<=tools.left&&tools.right<=innerWidth;
    }));
    await page.locator('[data-td=collapse]').click();
    check(`${width}: collapsed strip is 44px and content inert`,await page.evaluate(()=>document.querySelector('#terminal-dock').offsetHeight===44&&document.querySelector('.td-content').inert));
    await page.screenshot({path:fileURLToPath(new URL(`collapsed-${width}.png`,out))});
    await page.locator('[data-tab=terminal]').focus();await page.keyboard.press('ArrowRight');
    check(`${width}: arrow opens output and moves focus`,await page.evaluate(()=>document.activeElement.dataset.tab==='output'&&document.querySelector('#log').checkVisibility()));
    await page.keyboard.press('End');
    check(`${width}: End selects results`,await page.locator('[data-tab=results]').getAttribute('aria-selected')==='true');
    await page.keyboard.press('Home');
    check(`${width}: Home restores terminal`,await page.locator('[data-tab=terminal]').getAttribute('aria-selected')==='true');
    const input=page.locator('.td-pane').first().locator('input');await input.fill('유지할 입력');
    await page.locator('.td-session[aria-selected=true]').focus();await page.keyboard.press('ArrowRight');await page.keyboard.press('ArrowLeft');
    check(`${width}: session keys preserve unsent input`,await input.inputValue()==='유지할 입력');
    await page.screenshot({path:fileURLToPath(new URL(`dock-${width}.png`,out))});
    await page.locator('.td-tools [data-td=new]').click();
    check(`${width}: provider menu fits viewport`,await page.locator('.td-popover').evaluate(e=>{const r=e.getBoundingClientRect();return r.top>=0&&r.bottom<=innerHeight&&r.left>=0&&r.right<=innerWidth;}));
    await page.screenshot({path:fileURLToPath(new URL(`providers-${width}.png`,out))});
    await page.keyboard.press('Escape');
    check(`${width}: Escape restores add button`,await page.evaluate(()=>document.activeElement.matches('.td-tools [data-td=new]')));
  }
  check('no browser errors',errors.length===0);
  console.log(`PASS ${checks.length} dock design checks`);
}finally{
  await writeFile(new URL('verification-dock-design.json',root),JSON.stringify({status:checks.length===25?'passed':'failed',scope:'HTML prototype only',checks,errors},null,2));
  await browser.close();
}
