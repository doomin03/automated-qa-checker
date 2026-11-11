import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {readFile,writeFile,mkdir,mkdtemp} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {join,resolve} from 'node:path';

const root=fileURLToPath(new URL('../',import.meta.url));
const receipt=JSON.parse(await readFile(join(root,'apps/app/assets/desktop-installation.json')));
const manifest=JSON.parse(await readFile(join(root,'apps/app/assets/desktop-engine-runtime.json')));
const bundle=await readFile(join(root,'apps/app/assets/desktop-engine-contract.json'));
const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
assert.equal(receipt.sha256,manifest.sha256);
assert.equal(sha(bundle),manifest.bundleSha256);
for(const [file,hash] of Object.entries(manifest.files)) assert.equal(sha(await readFile(join(receipt.packageRoot,file))),hash,`Installed file changed: ${file}`);
const server=createServer((req,res)=>{
  res.setHeader('Content-Type','text/html; charset=utf-8');
  res.end(`<!doctype html><html lang="ko"><meta charset="utf-8"><title>Automated QA 로컬 데모</title><style>body{font:18px sans-serif;margin:48px}input,button{font:inherit;padding:8px;margin:8px}</style><h1>로컬 QA 테스트 대상</h1><label>이름 <input data-testid="username"></label><button data-testid="submit">인사하기</button><p data-testid="greeting"></p><script>document.querySelector('button').onclick=()=>{document.querySelector('[data-testid=greeting]').textContent='Welcome '+document.querySelector('input').value}</script></html>`);
});
try {await new Promise((ok,bad)=>{server.once('error',bad);server.listen(4339,'127.0.0.1',ok);});}
catch(error){if(error.code==='EADDRINUSE'){console.error('포트4339가 사용 중입니다. 기존 데모 터미널을 확인하세요. 다른 프로세스는 종료하지 않았습니다.');process.exit(1);}throw error;}
try {
 const blueprint=JSON.parse(bundle).example;
 blueprint.target.allowedOrigins=['http://127.0.0.1:4339'];
 for(const key of Object.keys(blueprint.target.launchTargets)) blueprint.target.launchTargets[key]='http://127.0.0.1:4339';
 const output=resolve(root,'.local/desktop-demo');await mkdir(output,{recursive:true});
 const session=await mkdtemp(join(output,'example-'));
 const input=join(session,'source.json'),xml=join(session,'login.xml');
 await writeFile(input,JSON.stringify(blueprint));
 const result=spawnSync(receipt.nodePath,[receipt.cliPath,'export',input,'--format','xml','--out',xml,'--diagnostics','stderr'],{encoding:'utf8',windowsHide:true,timeout:15000,maxBuffer:2*1024*1024});
 assert.equal(result.status,0,`Public Engine export failed: ${result.stderr}`);
 console.log(`로컬 테스트 대상: http://127.0.0.1:4339\n새 앱에서 프로젝트 → QA 만들기 → 가져오기:\n${xml}\n검증 → 실행. AI 변경 요청 예: "기존 동작은 유지하고 end 앞에 required:true인 screenshot을 추가해 주세요."\n이 터미널을 열어 두세요. 종료: Ctrl+C`);
 await writeFile(join(output,'latest.json'),JSON.stringify({url:'http://127.0.0.1:4339',xml,engineVersion:receipt.engineVersion},null,2));
} catch(error) {server.close();throw error;}
for(const signal of ['SIGINT','SIGTERM']) process.once(signal,()=>server.close(()=>process.exit(0)));
