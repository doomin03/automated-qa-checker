import {execFileSync,spawn} from 'node:child_process';
import {readFile,writeFile,mkdir,copyFile,cp,lstat} from 'node:fs/promises';
import {appendFileSync} from 'node:fs';
import {resolve,relative,isAbsolute,dirname,join} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const root=fileURLToPath(new URL('../',import.meta.url));
if(!process.argv[2])throw Error('Usage: node scripts/verify-fresh.mjs <pinned Engine tgz>');
const artifact=resolve(process.argv[2]),destination=resolve(root,'.local',`fresh-${Date.now()}`);
const within=(base,path)=>{const rel=relative(base,path);return !isAbsolute(rel)&&rel!=='..'&&!rel.startsWith('../')&&!rel.startsWith('..\\');};
if(!within(resolve(root,'.local'),destination))throw Error('Fresh checkout must remain under ignored .local');
const sdk=resolve(process.env.FLUTTER_SDK??resolve(root,'../.tools/flutter-3.47.5'));
const dart=resolve(sdk,'bin/cache/dart-sdk/bin/dart.exe');
const pnpm=resolve(dirname(process.execPath),'node_modules/corepack/dist/pnpm.js');
const corepack=resolve(dirname(process.execPath),'node_modules/corepack/dist/corepack.js');
const env={...process.env,FLUTTER_SDK:sdk,QA_DART:dart,QA_AUTH_MODE:'disabled',OPENSPEC_TELEMETRY:'0',TURBO_TELEMETRY_DISABLED:'1'};
const inheritedPath=Object.entries(process.env).find(([key])=>key.toLowerCase()==='path')?.[1]??'';
for(const key of Object.keys(env))if(key.toLowerCase()==='path')delete env[key];
env.PATH=dirname(process.execPath)+';'+inheritedPath;
const report={sourceRoot:root,destination,sourceFiles:0,sourceManifestSha256:'',steps:[],fullVerification:false,environment:{cleanDependencies:true,reusedBuildOutputs:false,flutterSdk:sdk,sharedOsToolchain:true,sharedBrowserDownloadCache:true,generatorCache:'reused with checksum validation'}};
await mkdir(destination,{recursive:false});
const files=[...new Set(execFileSync('git',['ls-files','-c','-o','--exclude-standard','-z'],{cwd:root,encoding:'utf8',maxBuffer:32*1024*1024}).split('\0').filter(Boolean))].sort();const inventory=[];
for(const name of files){const from=resolve(root,name),to=resolve(destination,name);if(!within(root,from)||!within(destination,to))throw Error('Invalid source path');let stat;try{stat=await lstat(from);}catch(error){if(error.code==='ENOENT')continue;throw error;}if(!stat.isFile())throw Error(`Unsupported source item: ${name}`);await mkdir(dirname(to),{recursive:true});await copyFile(from,to);inventory.push({name,size:stat.size,sha256:createHash('sha256').update(await readFile(from)).digest('hex')});}
report.sourceFiles=inventory.length;report.sourceManifestSha256=createHash('sha256').update(JSON.stringify(inventory)).digest('hex');
await mkdir(resolve(root,'artifacts'),{recursive:true});
await writeFile(resolve(root,'artifacts/fresh-source-manifest.json'),JSON.stringify(inventory,null,2));
async function run(label,command,args,cwd=destination){console.log(`Fresh verification: ${label}`);const began=Date.now(),log=resolve(root,'artifacts',`fresh-${report.steps.length+1}.log`);await writeFile(log,'');const code=await new Promise((done,reject)=>{const child=spawn(command,args,{cwd,env,stdio:['inherit','pipe','pipe'],windowsHide:true});for(const stream of [child.stdout,child.stderr])stream.on('data',bytes=>{appendFileSync(log,bytes);process.stdout.write(bytes);});child.once('error',reject);child.once('close',value=>done(value??1));});report.steps.push({label,exitCode:code,elapsedMs:Date.now()-began,log});if(code!==0)throw Error(`Fresh step failed: ${label} (${code})`);}
async function start(command,args,extraEnv){const child=spawn(command,args,{cwd:destination,env:{...env,...extraEnv},stdio:['ignore','pipe','pipe'],windowsHide:true});let output='';child.stdout.on('data',b=>output+=b);child.stderr.on('data',()=>{});try{for(let i=0;i<200;i++){const line=output.split('\n').find(l=>l.startsWith('{"event":"listening"'));if(line)return{child,origin:JSON.parse(line).url};if(child.exitCode!==null)throw Error('Fresh service startup failed');await new Promise(r=>setTimeout(r,100));}throw Error('Fresh service startup timeout');}catch(error){child.kill();throw error;}}
try{
 await run('frozen pnpm install',process.execPath,[pnpm,'install','--frozen-lockfile','--ignore-scripts']);
 const bin=resolve(destination,'.local/toolbin');await mkdir(bin,{recursive:true});await run('local pnpm shim',process.execPath,[corepack,'enable','--install-directory',bin,'pnpm']);env.PATH=bin+';'+env.PATH;
 await run('independent Engine hash/install',process.execPath,['scripts/install-engine-runtime.mjs',artifact]);
 const checkerPlaywright=JSON.parse(await readFile(resolve(destination,'node_modules/playwright/package.json'),'utf8')).version;
 const enginePlaywright=JSON.parse(await readFile(resolve(destination,'.local/engine/node_modules/playwright/package.json'),'utf8')).version;
 if(checkerPlaywright!==enginePlaywright)throw Error('Different Playwright versions require separate browser installation');
 report.environment.playwrightVersion=checkerPlaywright;
 await run('pinned Playwright Chromium install (shared download cache)',process.execPath,[pnpm,'exec','playwright','install','chromium']);
 // A verified download cache is reusable; generated app/SDK outputs and dependencies are not copied.
 await cp(resolve(root,'.local/server-tools'),resolve(destination,'.local/server-tools'),{recursive:true});
 await run('verify generator/JRE download checksums','powershell.exe',['-NoProfile','-ExecutionPolicy','Bypass','-File','packages/contract/generator/setup.ps1']);
 await run('frozen Flutter pub get',process.execPath,['scripts/flutter.mjs','pub','get','--enforce-lockfile']);
 await run('frozen Dart SDK pub get',dart,['pub','get','--enforce-lockfile'],resolve(destination,'packages/api_client_dart'));
 await run('build all JS apps',process.execPath,[pnpm,'run','build']);
 await run('offline deterministic SDK generate',process.execPath,[pnpm,'run','contract:generate']);
 await run('documented app dev commands on isolated ports',process.execPath,['scripts/dev-smoke.mjs']);
 await run('local identity bootstrap without token output',process.execPath,['apps/server/scripts/local-identities.mjs']);
 const identities=await readFile(resolve(destination,'.local/platform-identities.json'),'utf8');
 const api=await start(process.execPath,['apps/server/dist/src/main.js'],{NODE_ENV:'development',HOST:'127.0.0.1',PORT:'0',QA_AUTH_MODE:'local',QA_DATA_DIR:resolve(destination,'.local/platform-data'),QA_ENGINE_CLI:resolve(destination,'.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'),QA_ENGINE_MANIFEST:resolve(destination,'apps/app/assets/engine-runtime.json'),QA_LOCAL_IDENTITIES_JSON:identities});
 const web=await start(process.execPath,['apps/web/scripts/serve.mjs'],{PORT:'0'});
 try{const health=await fetch(api.origin+'/api/v1/health?client=app');if(health.status!==200)throw Error('Fresh API health failed');const page=await fetch(web.origin+'/qa/shared');if(page.status!==200)throw Error('Fresh production deep-link failed');report.startup={apiOrigin:api.origin,webOrigin:web.origin,health:await health.json(),webStatus:page.status,ports:'isolated dynamic ports; documented defaults 4319/4318',tokensPrinted:false};}finally{api.child.kill();web.child.kill();}
 await run('verify:all from clean dependency installation',process.execPath,[pnpm,'run','verify:all']);
 const changed=[];for(const item of inventory){for(const base of [root,destination]){let bytes;try{bytes=await readFile(resolve(base,item.name));}catch{changed.push({base,name:item.name,reason:'missing'});continue;}if(createHash('sha256').update(bytes).digest('hex')!==item.sha256)changed.push({base,name:item.name,reason:'bytes changed'});}}
 const now=execFileSync('git',['ls-files','-c','-o','--exclude-standard','-z'],{cwd:root,encoding:'utf8',maxBuffer:32*1024*1024}).split('\0').filter(Boolean);const known=new Set(inventory.map(i=>i.name));for(const name of now)if(!known.has(name))changed.push({base:root,name,reason:'new source file'});
 report.sourceDrift=changed;if(changed.length)throw Error('Source drift occurred during clean verification; see report');report.fullVerification=true;
}finally{await writeFile(resolve(root,'artifacts/fresh-install-verification.json'),JSON.stringify(report,null,2)+'\n');console.log(`Fresh evidence: ${resolve(root,'artifacts/fresh-install-verification.json')}`);}
