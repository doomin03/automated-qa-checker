import assert from 'node:assert/strict';
import {readFile,writeFile,mkdir,open} from 'node:fs/promises';
import {spawn} from 'node:child_process';
import {join,resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const pin=JSON.parse(await readFile(join(root,'apps/app/engine-runtime-pin.json')));
const latest=JSON.parse(await readFile(join(root,'.local/portable-runtime',pin.engineVersion,pin.sha256,'latest.json')));
const expected=await readFile(join(latest.destination,'portable-runtime.json'));
assert.deepEqual(await readFile(join(root,'apps/app/assets/desktop-portable-runtime.json')),expected);
const installation=join(root,'apps/app/assets/desktop-installation.json');
const backup=join(root,'.local/desktop-engine',pin.engineVersion,pin.sha256,'installation.json');
const saved=JSON.parse(await readFile(backup));assert.equal(saved.sha256,pin.sha256);assert(saved.cliPath&&saved.nodePath);
await writeFile(installation,JSON.stringify({portable:true,engineVersion:pin.engineVersion,sha256:pin.sha256},null,2)+'\n');
const dir=join(root,'artifacts/portable-runtime');await mkdir(dir,{recursive:true});
const stamp=new Date().toISOString().replaceAll(':','-').replaceAll('.','-');
const log=join(dir,`build-${stamp}.log`),handle=await open(log,'wx');
const args=['scripts/flutter.mjs','build','windows','--release','--dart-define=QA_PORTABLE=true'];
const started=new Date().toISOString();
const child=spawn(process.execPath,args,{cwd:root,stdio:['ignore',handle.fd,handle.fd],windowsHide:true});
const code=await new Promise((r,j)=>{child.on('error',j);child.on('close',r);});await handle.close();
const receipt={started,finished:new Date().toISOString(),command:[process.execPath,...args],exitCode:code,log,portableRequired:true,sanitizedInstallationSha256:createHash('sha256').update(await readFile(installation)).digest('hex')};
await writeFile(join(dir,`build-${stamp}.json`),JSON.stringify(receipt,null,2)+'\n');console.log(JSON.stringify(receipt));
if(code!==0){process.exitCode=code??1;}else{
 const pack=spawn(process.execPath,['scripts/record-portable-release.mjs'],{cwd:root,stdio:'inherit',windowsHide:true});
 const packed=await new Promise((r,j)=>{pack.on('error',j);pack.on('close',r);});process.exitCode=packed??1;
}
