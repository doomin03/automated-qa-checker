import assert from 'node:assert/strict';
import {readFile,readdir,writeFile,mkdir,cp,lstat} from 'node:fs/promises';
import {createReadStream} from 'node:fs';
import {resolve,relative,join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../',import.meta.url));
const source=resolve(root,'apps/app/build/windows/x64/runner/Release');
const output=resolve(root,'artifacts/releases/desktop-portable-alpha10');
const release=join(output,'Release');
const digest=b=>createHash('sha256').update(b).digest('hex');
async function hash(path){const h=createHash('sha256');for await(const b of createReadStream(path))h.update(b);return h.digest('hex');}
async function inventory(directory){const files={};async function walk(dir){for(const e of(await readdir(dir,{withFileTypes:true})).sort((a,b)=>a.name.localeCompare(b.name))){const path=resolve(dir,e.name);const stat=await lstat(path);assert(!stat.isSymbolicLink(),'Linked release payload');if(stat.isDirectory())await walk(path);else{assert(stat.isFile());files[relative(directory,path).replaceAll('\\','/')]=await hash(path);}}}await walk(directory);return files;}
const pin=JSON.parse(await readFile(resolve(root,'apps/app/engine-runtime-pin.json')));
assert.equal(pin.engineVersion,'0.1.0-alpha.10');
const latest=JSON.parse(await readFile(resolve(root,'.local/portable-runtime',pin.engineVersion,pin.sha256,'latest.json')));
const receipt=await readFile(join(latest.destination,'portable-runtime.json'));
assert.equal(digest(receipt),latest.manifestSha256);
const runtime=JSON.parse(receipt);
assert.equal(runtime.archiveSha256,pin.sha256);
const before=await inventory(latest.destination+'/runtime');
assert.deepEqual(before,Object.fromEntries(Object.entries(runtime.files).map(([path,data])=>[path.slice('runtime/'.length),data.sha256])));
const files=await inventory(source);
assert(files['automated_qa_desktop.exe']&&files['data/app.so']);
const installation=JSON.parse(await readFile(join(source,'data/flutter_assets/assets/desktop-installation.json')));
assert.deepEqual(Object.keys(installation).sort(),['engineVersion','portable','sha256']);
assert.equal(installation.portable,true,'Portable release must not contain a private installation receipt');
assert.equal(installation.sha256,pin.sha256);
for(const [name,sha] of [['desktop-engine-contract.json',pin.bundleSha256],['desktop-authoring-contract.json',pin.authoringBundleSha256],['desktop-portable-runtime.json',latest.manifestSha256]])assert.equal(files[`data/flutter_assets/assets/${name}`],sha);
// Never reuse an existing release directory or silently append runtime files.
await mkdir(output,{recursive:true});
let releaseExists=false;
try{await lstat(release);releaseExists=true;}catch(error){if(error.code!=='ENOENT')throw error;}
assert(!releaseExists,'Preserve existing Release directory; use a new approved destination');
await cp(source,release,{recursive:true,errorOnExist:true,force:false});
await cp(join(latest.destination,'runtime'),join(release,'runtime'),{recursive:true,errorOnExist:true,force:false});
await writeFile(join(release,'portable-runtime.json'),receipt,{flag:'wx'});
const final=await inventory(release);
for(const [path,sha] of Object.entries(files))assert.equal(final[path],sha);
for(const [path,data] of Object.entries(runtime.files))assert.equal(final[path],data.sha256);
assert.equal(Object.keys(final).length,Object.keys(files).length+Object.keys(runtime.files).length+1);
await writeFile(join(output,'manifest.json'),JSON.stringify({timestamp:new Date().toISOString(),engineVersion:pin.engineVersion,archiveSha256:pin.sha256,sourceDirectory:source,releaseDirectory:release,files:final,manifestSha256:digest(JSON.stringify(final)),runtimeManifestSha256:latest.manifestSha256},null,2)+'\n');
const frozen={};
for(const [name,dir] of [['source','apps/app/lib'],['sdk-source','packages/api_client_dart/lib'],['vendor-source','apps/app/vendor/flutter_pty2']]){
 const sourceFiles=await inventory(resolve(root,dir));await writeFile(join(output,`${name}-manifest.json`),JSON.stringify({directory:resolve(root,dir),files:sourceFiles,manifestSha256:digest(JSON.stringify(sourceFiles))},null,2)+'\n');
 for(const [path,sha] of Object.entries(sourceFiles))frozen[`${dir}/${path}`]=sha;
}
const configuration={};
for(const file of ['pubspec.yaml','pubspec.lock','engine-runtime-pin.json','assets/desktop-engine-runtime.json','assets/desktop-engine-contract.json','assets/desktop-installation.json','assets/desktop-authoring-contract.json','assets/desktop-portable-runtime.json','windows/flutter/generated_plugin_registrant.cc','windows/flutter/generated_plugin_registrant.h','windows/flutter/generated_plugins.cmake','windows/CMakeLists.txt'])configuration[file]=await hash(resolve(root,'apps/app',file));
await writeFile(join(output,'configuration-manifest.json'),JSON.stringify({directory:resolve(root,'apps/app'),files:configuration,sdkConfiguration:{'pubspec.yaml':await hash(resolve(root,'packages/api_client_dart/pubspec.yaml')),'pubspec.lock':await hash(resolve(root,'packages/api_client_dart/pubspec.lock'))}},null,2)+'\n');
for(const [path,sha] of Object.entries(configuration))frozen[`apps/app/${path}`]=sha;
for(const path of ['packages/api_client_dart/pubspec.yaml','packages/api_client_dart/pubspec.lock'])frozen[path]=await hash(resolve(root,path));
await writeFile(join(output,'source-freeze.json'),JSON.stringify({timestamp:new Date().toISOString(),directory:root,files:frozen,manifestSha256:digest(JSON.stringify(frozen))},null,2)+'\n');
console.log(JSON.stringify({release,appFiles:Object.keys(files).length,runtimeFiles:Object.keys(runtime.files).length,totalFiles:Object.keys(final).length,manifestSha256:digest(JSON.stringify(final))}));
