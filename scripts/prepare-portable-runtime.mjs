import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {createReadStream} from 'node:fs';
import {mkdir, mkdtemp, readFile, writeFile, copyFile, readdir, lstat, realpath, rm} from 'node:fs/promises';
import {join, resolve, dirname, relative, isAbsolute} from 'node:path';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const pin = JSON.parse(await readFile(join(root,'apps/app/engine-runtime-pin.json')));
const installationRoot = join(root,'.local/desktop-engine',pin.engineVersion,pin.sha256);
const receipt = JSON.parse(await readFile(join(installationRoot,'installation.json')));
assert.equal(receipt.sha256,pin.sha256);
const candidates = join(root,'.local/portable-runtime',pin.engineVersion,pin.sha256);
await mkdir(candidates,{recursive:true});
const destination = await mkdtemp(join(candidates,'candidate-'));
const runtime = join(destination,'runtime');
await mkdir(runtime,{recursive:true});
const nodeVersion='24.18.0';
const archiveName=`node-v${nodeVersion}-win-x64.zip`;
const archiveSha='0ae68406b42d7725661da979b1403ec9926da205c6770827f33aac9d8f26e821';
const nodeSha='9a4eb5f1c29c6a2e93852ead46b999e284a6a5ca8bab4d4e241d587d025a52de';
const source=`https://nodejs.org/dist/v${nodeVersion}/`;
const cache=join(root,'.local/portable-downloads');await mkdir(cache,{recursive:true});
async function hash(path){const h=createHash('sha256');for await(const b of createReadStream(path))h.update(b);return h.digest('hex');}
async function download(name){const path=join(cache,name);try{await lstat(path);}catch(e){if(e.code!=='ENOENT')throw e;const r=await fetch(source+name);assert(r.ok,`Download failed ${r.status}`);await writeFile(path,Buffer.from(await r.arrayBuffer()));}return path;}
const sums=await download('SHASUMS256.txt');
assert((await readFile(sums,'utf8')).split(/\r?\n/).includes(`${archiveSha}  ${archiveName}`),'Official Node archive checksum mismatch');
const zip=await download(archiveName);assert.equal(await hash(zip),archiveSha);
const extract=join(cache,`node-${nodeVersion}`);await mkdir(extract,{recursive:true});
const unpack=spawnSync('tar.exe',['-xf',zip,'-C',extract],{windowsHide:true,encoding:'utf8',timeout:60000});assert.equal(unpack.status,0,unpack.stderr);
const nodeDir=join(runtime,'node');await mkdir(nodeDir,{recursive:true});
const upstream=join(extract,`node-v${nodeVersion}-win-x64`);
assert.equal(await hash(join(upstream,'node.exe')),nodeSha);
for(const file of ['node.exe','LICENSE'])await copyFile(join(upstream,file),join(nodeDir,file));

// npm's complete installed dependency tree, never pnpm/cache links. Reject all
// reparse points instead of silently copying a target outside the payload.
async function copyTree(from,to){
 const canonical=await realpath(from);await mkdir(to,{recursive:true});
 for(const e of await readdir(from,{withFileTypes:true})){
  const src=join(from,e.name),dst=join(to,e.name),stat=await lstat(src);
  assert(!stat.isSymbolicLink(),`Linked payload rejected: ${e.name}`);
  const rel=relative(canonical,await realpath(src));assert(rel&&!rel.startsWith('..')&&!isAbsolute(rel),'Payload escapes source');
  if(stat.isDirectory())await copyTree(src,dst);else {assert(stat.isFile(),'Non-regular payload');await copyFile(src,dst);}
 }
}
const approved = JSON.parse(await readFile(join(root,'apps/app/assets/desktop-engine-runtime.json')));
assert.equal(approved.sha256,pin.sha256);
async function verifyEngine(base){
 const found={};
 async function visit(dir){for(const e of await readdir(dir,{withFileTypes:true})){const p=join(dir,e.name);assert(!(await lstat(p)).isSymbolicLink());if(e.isDirectory()){if(e.name!=='node_modules')await visit(p);}else found[relative(base,p).replaceAll('\\','/')]=await hash(p);}}
 await visit(base);assert.deepEqual(found,approved.files,'Installed package differs from approved files');
}
await verifyEngine(join(installationRoot,'node_modules',pin.packageName));
await copyTree(join(installationRoot,'node_modules'),join(runtime,'engine/node_modules'));
await verifyEngine(join(runtime,'engine/node_modules',pin.packageName));
await rm(join(runtime,'engine/node_modules/.package-lock.json'),{force:true});
const browserRoot=join(runtime,'browsers');await mkdir(browserRoot,{recursive:true});
const node=join(nodeDir,'node.exe');
const browser=spawnSync(node,[join(runtime,'engine/node_modules/playwright/cli.js'),'install','chromium'],{
 env:{...process.env,PLAYWRIGHT_BROWSERS_PATH:browserRoot},windowsHide:true,encoding:'utf8',timeout:300000,maxBuffer:4*1024*1024});
await writeFile(join(destination,'browser-install.log'),String(browser.stdout??'')+String(browser.stderr??''));assert.equal(browser.status,0,'Portable browser install failed');
// Installer bookkeeping is not used by launch and contains absolute paths.
const links=resolve(browserRoot,'.links');
assert.equal(dirname(links),resolve(browserRoot));
await rm(links,{recursive:true,force:true});
const files={};
async function inventory(dir){for(const e of(await readdir(dir,{withFileTypes:true})).sort((a,b)=>a.name.localeCompare(b.name))){const p=join(dir,e.name);assert(!(await lstat(p)).isSymbolicLink(),'Linked payload rejected');if(e.isDirectory())await inventory(p);else{assert(e.isFile());files[relative(destination,p).replaceAll('\\','/')]={sha256:await hash(p),size:(await lstat(p)).size};}}}
await inventory(runtime);
const manifest={schemaVersion:'qa.desktopPortable/v1',engineVersion:pin.engineVersion,archiveSha256:pin.sha256,bundleSha256:pin.bundleSha256,authoringBundleSha256:pin.authoringBundleSha256,
 nodePath:'runtime/node/node.exe',cliPath:`runtime/engine/node_modules/${pin.packageName}/${pin.entrypoint}`,browserRoot:'runtime/browsers',files,
 provenance:{node:{version:nodeVersion,source:source+archiveName,checksumSource:source+'SHASUMS256.txt',archiveSha256:archiveSha,executableSha256:nodeSha,license:'runtime/node/LICENSE'},engineVerificationSha256:receipt.verificationSha256,playwright:JSON.parse(await readFile(join(runtime,'engine/node_modules/playwright/package.json'))).version,excludedInstallerMetadata:['runtime/browsers/.links','runtime/engine/node_modules/.package-lock.json']}};
const bytes=JSON.stringify(manifest,null,2)+'\n';
await writeFile(join(destination,'portable-runtime.json'),bytes);
await writeFile(join(root,'apps/app/assets/desktop-portable-runtime.json'),bytes);
await writeFile(join(candidates,'latest.json'),JSON.stringify({destination,manifestSha256:createHash('sha256').update(bytes).digest('hex')},null,2)+'\n');
console.log(JSON.stringify({destination,files:Object.keys(files).length,manifestSha256:createHash('sha256').update(bytes).digest('hex'),nodeVersion,engineVersion:pin.engineVersion}));
