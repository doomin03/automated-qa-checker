import assert from 'node:assert/strict';
import {readFile,readdir,writeFile,mkdir,cp,stat} from 'node:fs/promises';
import {resolve,relative} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../',import.meta.url));
const source=resolve(root,'apps/app/build/windows/x64/runner/Release'),output=resolve(root,'artifacts/releases/desktop-project-home-alpha8'),release=resolve(output,'Release');
const digest=b=>createHash('sha256').update(b).digest('hex');
async function inventory(directory){const files={};async function walk(dir){for(const e of(await readdir(dir,{withFileTypes:true})).sort((a,b)=>a.name.localeCompare(b.name))){assert(!e.isSymbolicLink());const path=resolve(dir,e.name);if(e.isDirectory())await walk(path);else files[relative(directory,path).replaceAll('\\','/')]=digest(await readFile(path));}}await walk(directory);return files;}
const pin=JSON.parse(await readFile(resolve(root,'apps/app/engine-runtime-pin.json'))),files=await inventory(source);
assert(files['automated_qa_desktop.exe']&&files['data/app.so']);
assert(Object.keys(files).some(f=>f.includes('file_selector_windows')&&f.endsWith('.dll')),'native file picker DLL required');
assert(Object.keys(files).some(f=>f.includes('flutter_pty')&&f.endsWith('.dll')),'PTY native DLL required');
assert.equal(files['data/flutter_assets/assets/desktop-engine-contract.json'],pin.bundleSha256);
for(const name of ['desktop-engine-runtime.json','desktop-engine-contract.json','desktop-installation.json'])assert.equal(files[`data/flutter_assets/assets/${name}`],digest(await readFile(resolve(root,'apps/app/assets',name))));
await mkdir(output,{recursive:true});let exists=false;try{exists=(await stat(release)).isDirectory();}catch(e){if(e.code!=='ENOENT')throw e;}
if(exists)assert.deepEqual(await inventory(release),files,'Preserve the existing release; do not overwrite different bytes.');else await cp(source,release,{recursive:true,errorOnExist:true,force:false});
assert.deepEqual(await inventory(release),files);
const manifest={engineVersion:pin.engineVersion,archiveSha256:pin.sha256,sourceDirectory:source,releaseDirectory:release,files,manifestSha256:digest(JSON.stringify(files)),timestamp:new Date().toISOString()};
await writeFile(resolve(output,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
const sourceFiles=await inventory(resolve(root,'apps/app/lib')),configuration={};
for(const file of ['pubspec.yaml','pubspec.lock','windows/flutter/generated_plugin_registrant.cc','windows/flutter/generated_plugin_registrant.h','windows/flutter/generated_plugins.cmake','windows/CMakeLists.txt','vendor/flutter_pty2/pubspec.yaml'])configuration[file]=digest(await readFile(resolve(root,'apps/app',file)));
await writeFile(resolve(output,'source-manifest.json'),JSON.stringify({directory:resolve(root,'apps/app/lib'),files:sourceFiles,manifestSha256:digest(JSON.stringify(sourceFiles)),configurationDirectory:resolve(root,'apps/app'),configuration},null,2)+'\n');
console.log(JSON.stringify({release,files:Object.keys(files).length,manifestSha256:manifest.manifestSha256},null,2));
