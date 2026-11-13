import assert from 'node:assert/strict';
import {readFile, writeFile, mkdir, readdir, realpath} from 'node:fs/promises';
import {dirname, join, resolve, relative, isAbsolute} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {readAuthoringArtifact} from './lib/authoring-artifact.mjs';

const root=resolve(dirname(fileURLToPath(import.meta.url)), '..');
const pin=JSON.parse(await readFile(join(root,'apps/app/engine-runtime-pin.json')));
const [archive, verificationPath]=process.argv.slice(2);
assert(isAbsolute(archive??'')&&isAbsolute(verificationPath??''),'Pass absolute approved archive and verification.json paths');
const sha=b=>createHash('sha256').update(b).digest('hex');
assert.equal(sha(await readFile(archive)),pin.sha256,'Archive SHA mismatch');
const verification=JSON.parse(await readFile(verificationPath));
assert.equal(verification.status,'passed');
assert.equal(verification.engineVersion,pin.engineVersion);
assert.equal(verification.contractVersion,pin.contractVersion);
assert.equal(verification.tgzSha256??verification.sha256,pin.sha256);
const filesExpected=Object.fromEntries(verification.installedFiles.map(f=>[f.path,f.sha256]));
assert(filesExpected&&Object.keys(filesExpected).length>0);
const destination=join(root,'.local/desktop-engine',pin.engineVersion,pin.sha256);
const packageRoot=join(destination,'node_modules',pin.packageName);
let installed=false;try{await readFile(join(packageRoot,'package.json'));installed=true;}catch(e){if(e.code!=='ENOENT')throw e;}
await mkdir(destination,{recursive:true});
if(!installed){
 const npm=join(dirname(process.execPath),'node_modules/npm/bin/npm-cli.js');
 const result=spawnSync(process.execPath,[npm,'install','--prefix',destination,'--ignore-scripts','--no-audit','--no-fund',archive],{windowsHide:true,encoding:'utf8',timeout:180000,maxBuffer:4*1024*1024});
 await writeFile(join(destination,'install.log'),String(result.stdout??'')+String(result.stderr??''));
 assert.equal(result.status,0,'Installation failed');
}
const actual={};
async function walk(dir){for(const entry of (await readdir(dir,{withFileTypes:true})).sort((a,b)=>a.name.localeCompare(b.name))){assert(!entry.isSymbolicLink(),'Package symlink rejected');const file=join(dir,entry.name);if(entry.isDirectory()){if(entry.name!=='node_modules')await walk(file);}else actual[relative(packageRoot,file).replaceAll('\\','/')]=sha(await readFile(file));}}
await walk(packageRoot);
assert.deepEqual(actual,filesExpected,'Public package files differ from approved verification');
const bundlePath=join(packageRoot,`contracts/releases/qa-contract-${pin.engineVersion}.json`);
const bundle=await readFile(bundlePath);assert.equal(sha(bundle),pin.bundleSha256);
let authoringBundle;
if(pin.documentAuthoring){
 authoringBundle=await readAuthoringArtifact(packageRoot,pin,actual);
}
const cliPath=join(await realpath(packageRoot),pin.entrypoint);
const version=spawnSync(process.execPath,[cliPath,'--version'],{encoding:'utf8',timeout:15000,windowsHide:true});
assert.equal(version.status,0);assert.equal(JSON.parse(version.stdout).engineVersion,pin.engineVersion);
const playwright=join(destination,'node_modules/playwright/cli.js');
const browser=spawnSync(process.execPath,[playwright,'install','chromium'],{encoding:'utf8',timeout:240000,windowsHide:true,maxBuffer:4*1024*1024});
await writeFile(join(destination,'browser-install.log'),String(browser.stdout??'')+String(browser.stderr??''));assert.equal(browser.status,0,'Chromium install failed');
const assets=join(root,'apps/app/assets');await mkdir(assets,{recursive:true});
const manifest={...pin,files:actual};
const receipt={engineVersion:pin.engineVersion,sha256:pin.sha256,nodePath:process.execPath,cliPath,packageRoot:await realpath(packageRoot),verificationSha256:sha(await readFile(verificationPath)),files:Object.keys(actual).length};
await writeFile(join(assets,'desktop-engine-runtime.json'),JSON.stringify(manifest,null,2)+'\n');
await writeFile(join(assets,'desktop-engine-contract.json'),bundle);
if(authoringBundle)await writeFile(join(assets,'desktop-authoring-contract.json'),authoringBundle);
await writeFile(join(assets,'desktop-installation.json'),JSON.stringify(receipt,null,2)+'\n');
await writeFile(join(destination,'installation.json'),JSON.stringify(receipt,null,2)+'\n');
console.log(JSON.stringify(receipt,null,2));
