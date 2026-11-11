// Test-only baseline capture; product code never captures or replaces a reference.
import {chromium} from 'playwright';
import {mkdir,writeFile} from 'node:fs/promises';
import {resolve} from 'node:path';
const [url,root]=process.argv.slice(2);
await mkdir(root,{recursive:true});
const browser=await chromium.launch();
try {
 const page=await browser.newPage({viewport:{width:320,height:200},deviceScaleFactor:1,locale:'en-US',colorScheme:'light'});
 await page.goto(url);await page.locator('[data-testid="entry"]').waitFor();
 await page.screenshot({path:resolve(root,'baseline.png')});
 const profile={viewport:{width:320,height:200},dpr:1,browserVersion:browser.version(),os:process.platform,locale:'en-US',colorScheme:'light',fonts:[],readiness:{selector:'entry',timeoutMs:5000}};
 await writeFile(resolve(root,'profile.json'),JSON.stringify(profile));
 await writeFile(resolve(root,'measurements.json'),JSON.stringify([{id:'entry-width',selectorId:'entry',metric:'bbox.width',expected:100,tolerance:0}]));
 console.log(JSON.stringify(profile));
}finally{await browser.close();}
