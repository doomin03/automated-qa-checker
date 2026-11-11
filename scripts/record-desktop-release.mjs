import assert from 'node:assert/strict';
import {readFile,readdir,writeFile,mkdir,cp,stat} from 'node:fs/promises';
import {resolve,relative} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../',import.meta.url));
const source=resolve(root,'apps/app/build/windows/x64/runner/Release');
const output=resolve(root,'artifacts/releases/desktop-ai-alpha8');
const release=resolve(output,'Release');
const digest=bytes=>createHash('sha256').update(bytes).digest('hex');
const pin=JSON.parse(await readFile(resolve(root,'apps/app/engine-runtime-pin.json')));
async function inventory(directory){const result={};async function walk(dir){for(const entry of (await readdir(dir,{withFileTypes:true})).sort((a,b)=>a.name.localeCompare(b.name))){assert(!entry.isSymbolicLink());const path=resolve(dir,entry.name);if(entry.isDirectory())await walk(path);else result[relative(directory,path).replaceAll('\\','/')]=digest(await readFile(path));}}await walk(directory);return result;}
const embedded=JSON.parse(await readFile(resolve(source,'data/flutter_assets/assets/desktop-engine-runtime.json')));
assert.equal(embedded.engineVersion,pin.engineVersion);assert.equal(embedded.sha256,pin.sha256);
const original=await inventory(source);
assert.equal(original['data/flutter_assets/assets/desktop-engine-contract.json'],pin.bundleSha256);
assert(original['data/app.so']&&original['automated_qa_desktop.exe']);
await mkdir(output,{recursive:true});
// A separate release directory: existing alpha6 release is never overwritten.
let exists=false;try{exists=(await stat(release)).isDirectory();}catch(error){if(error.code!=='ENOENT')throw error;}
if(exists) assert.deepEqual(await inventory(release),original,'Existing accepted release differs; preserve it and use a separately reviewed destination.');
else await cp(source,release,{recursive:true,errorOnExist:true,force:false});
const files=await inventory(release);assert.deepEqual(files,original);
const manifest={engineVersion:pin.engineVersion,archiveSha256:pin.sha256,sourceDirectory:source,releaseDirectory:release,files,manifestSha256:digest(JSON.stringify(files)),timestamp:new Date().toISOString()};
await writeFile(resolve(output,'manifest.json'),JSON.stringify(manifest,null,2)+'\n');
const sourceFiles=await inventory(resolve(root,'apps/app/lib'));
await writeFile(resolve(output,'source-manifest.json'),JSON.stringify({directory:resolve(root,'apps/app/lib'),files:sourceFiles,manifestSha256:digest(JSON.stringify(sourceFiles))},null,2)+'\n');
console.log(JSON.stringify({release,files:Object.keys(files).length,manifestSha256:manifest.manifestSha256,appSo:files['data/app.so']},null,2));
