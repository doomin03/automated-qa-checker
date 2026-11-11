import {chromium} from 'playwright';
import {mkdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
const dir=fileURLToPath(new URL('./screenshots/',import.meta.url));await mkdir(dir,{recursive:true});
const browser=await chromium.launch({headless:true}),page=await browser.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
for(const [width,height] of [[1440,900],[1024,768]]){await page.setViewportSize({width,height});for(const route of ['map','spec/D03','prototype/W02','prototype/W06','prototype/A02','prototype/A05','prototype/D01','prototype/D05','prototype/E01']){await page.goto(new URL(`./index.html#${route}`,import.meta.url).href);await page.waitForTimeout(150);if(route.includes('D05'))await page.frameLocator('iframe').locator('.node').first().waitFor();await page.screenshot({path:`${dir}/${route.replaceAll('/','-')}-${width}.png`});}}
await browser.close();console.log(JSON.stringify({errors,directory:dir}));if(errors.length)process.exitCode=1;
