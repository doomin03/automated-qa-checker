import {readFile,readdir,writeFile,mkdir} from 'node:fs/promises';
import {resolve,relative} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../',import.meta.url)),release=resolve(root,'apps/app/build/windows/x64/runner/Release');
const runtime=JSON.parse(await readFile(resolve(root,'packages/contract/engine-runtime.json'))),contract=JSON.parse(await readFile(resolve(root,'packages/contract/engine-dependency.json')));
const digest=bytes=>createHash('sha256').update(bytes).digest('hex');const files={};
async function walk(directory){for(const item of (await readdir(directory,{withFileTypes:true})).sort((a,b)=>a.name.localeCompare(b.name))){const file=resolve(directory,item.name);if(item.isSymbolicLink())throw Error('Release cannot contain symlinks');if(item.isDirectory())await walk(file);else files[relative(release,file).replaceAll('\\','/')]=digest(await readFile(file));}}
await walk(release);
const embedded=JSON.parse(await readFile(resolve(release,'data/flutter_assets/assets/engine-runtime.json')));
if(embedded.engineVersion!==runtime.engineVersion||embedded.sha256!==runtime.sha256||files['data/flutter_assets/assets/engine-contract.json']!==contract.release.sha256||!files['data/app.so']||!files['automated_qa_desktop.exe'])throw Error('Release embedded pin or required binaries mismatch');
const manifest={engineVersion:runtime.engineVersion,releaseDirectory:release,files,manifestSha256:digest(JSON.stringify(files))};await mkdir(resolve(root,'artifacts'),{recursive:true});
const path=resolve(root,'artifacts/flutter-release-current.json');await writeFile(path,JSON.stringify(manifest,null,2)+'\n');console.log(`Release manifest ${path}: ${manifest.manifestSha256}; app.so ${files['data/app.so']}`);
