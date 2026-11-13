import {spawn,spawnSync} from 'node:child_process';
import {createServer} from 'node:net';
import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {dirname,resolve} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url));
const pnpm=resolve(dirname(process.execPath),'node_modules/corepack/dist/pnpm.js');
const port=()=>new Promise((done,reject)=>{const socket=createServer();socket.on('error',reject);socket.listen(0,'127.0.0.1',()=>{const value=socket.address().port;socket.close(()=>done(value));});});
const webPort=await port(),apiPort=await port(),children=[];let output='';
const turbo=JSON.parse(await readFile(resolve(root,'turbo.json')));if(turbo.tasks.dev.cache!==false||turbo.tasks.dev.persistent!==true)throw Error('Dev must be persistent and uncached');
function start(args,env){const child=spawn(process.execPath,[pnpm,...args],{cwd:root,env:{...process.env,QA_AUTH_MODE:'disabled',...env},windowsHide:true,stdio:'pipe'});children.push(child);for(const stream of [child.stdout,child.stderr])stream.on('data',bytes=>{output=(output+bytes).slice(-65536);});return child;}
try{
 start(['run','dev:web','--port',String(webPort),'--strictPort'],{});
 start(['run','dev:server'],{PORT:String(apiPort),HOST:'127.0.0.1'});
 async function ready(url){for(let i=0;i<300;i++){try{const response=await fetch(url);if(response.ok)return response;}catch{}if(children.some(child=>child.exitCode!==null))throw Error('Dev child exited before readiness');await new Promise(r=>setTimeout(r,100));}throw Error('Dev startup timed out');}
 const health=await (await ready(`http://127.0.0.1:${apiPort}/api/v1/health?client=web`)).json();await ready(`http://127.0.0.1:${webPort}/qa/blueprints`);
 if(health.client!=='web')throw Error('Dev SDK health identity mismatch');
 await mkdir(resolve(root,'artifacts'),{recursive:true});await writeFile(resolve(root,'artifacts/dev-startup-verification.json'),JSON.stringify({commands:['pnpm dev:web --port <isolated> --strictPort','pnpm dev:server'],webPort,apiPort,health,serverAuthMode:'disabled',persistent:true,cache:false,flutterNeeded:false},null,2));console.log('Web/server dev commands started on isolated ports; Flutter was not used.');
}catch(error){console.error(output);throw error;}finally{for(const child of children){if(process.platform==='win32'&&child.pid)spawnSync('taskkill.exe',['/PID',String(child.pid),'/T','/F'],{windowsHide:true,stdio:'ignore'});else child.kill();}}
