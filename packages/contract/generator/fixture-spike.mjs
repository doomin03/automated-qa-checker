import {mkdir,readFile,writeFile,cp} from 'node:fs/promises';
import {resolve,join} from 'node:path';
import {spawn} from 'node:child_process';
import {createInterface} from 'node:readline';
import {createHash} from 'node:crypto';
import {generate,run,root} from './contract-tools.mjs';
const directory=resolve(root,'.local/contract-spike'),dart=process.env.QA_DART??resolve(root,'../.tools/flutter-3.47.5/bin/cache/dart-sdk/bin/dart.exe');
await mkdir(directory,{recursive:true});
const productionHash=createHash('sha256').update(await readFile(resolve(root,'packages/contract/openapi.json'))).digest('hex');
run(process.execPath,['packages/contract/generator/fixture-spike-server.mjs',join(directory,'fixture-source.json'),'--export-only']);
if(!process.argv.includes('--reuse-generated'))await generate(directory,await readFile(join(directory,'fixture-source.json'),'utf8'));
if(!(await readFile(join(directory,'openapi.json'))).equals(await readFile(join(directory,'fixture-source.json'))))throw Error('Generated spike schema is stale');
await mkdir(join(directory,'client/src'),{recursive:true});await cp(join(directory,'ts'),join(directory,'client/src/generated'),{recursive:true});
await cp(resolve(root,'packages/api-client/src/schema-validation.ts'),join(directory,'client/src/schema-validation.ts'));
await writeFile(join(directory,'client/package.json'),' {"type":"module"}\n');
await writeFile(join(directory,'client/tsconfig.json'),JSON.stringify({compilerOptions:{target:'ES2023',module:'NodeNext',moduleResolution:'NodeNext',strict:true,skipLibCheck:true,rootDir:'src',outDir:'dist'},include:['src/**/*.ts']}));
run(process.execPath,[resolve(root,'apps/server/node_modules/typescript/bin/tsc'),'-p',join(directory,'client/tsconfig.json')]);
await cp(resolve(root,'packages/contract/generator/fixture-spike-ts.mjs'),join(directory,'ts-test.mjs'));
await cp(resolve(root,'packages/api_client_dart/lib/health_client.dart'),join(directory,'dart/lib/health_client.dart'));
await mkdir(join(directory,'dart/tool'),{recursive:true});await cp(resolve(root,'packages/contract/generator/fixture-spike-dart.dart'),join(directory,'dart/tool/spike.dart'));
run(dart,['pub','get','--enforce-lockfile'],join(directory,'dart'));run(dart,['format','tool'],join(directory,'dart'));run(dart,['analyze'],join(directory,'dart'));
const child=spawn(process.execPath,['packages/contract/generator/fixture-spike-server.mjs',join(directory,'fixture-live.json')],{cwd:root,windowsHide:true,stdio:['ignore','pipe','pipe']});child.stderr.pipe(process.stderr);
const timeout=setTimeout(()=>child.kill(),45000);
try{
  const origin=await new Promise((done,reject)=>{child.once('error',reject);child.once('exit',code=>reject(Error(`Fixture server exited ${code}`)));createInterface({input:child.stdout}).on('line',line=>{try{const value=JSON.parse(line);if(value.origin)done(value.origin);}catch{}});});clearTimeout(timeout);
  for(const[command,args,cwd]of[[process.execPath,[join(directory,'ts-test.mjs')],directory],[dart,['run','tool/spike.dart'],join(directory,'dart')]])await new Promise((done,reject)=>{const client=spawn(command,args,{cwd,env:{...process.env,QA_TEST_ORIGIN:origin},windowsHide:true,stdio:'inherit'});client.once('error',reject);client.once('exit',code=>code===0?done():reject(Error(`Fixture client exited ${code}`)));});
  const after=createHash('sha256').update(await readFile(resolve(root,'packages/contract/openapi.json'))).digest('hex');if(after!==productionHash)throw Error('Production contract unexpectedly changed');
  await writeFile(join(directory,'report.json'),JSON.stringify({passed:true,productionOpenApiUnchanged:after,fixtureOpenApiSha256:createHash('sha256').update(await readFile(join(directory,'fixture-source.json'))).digest('hex'),generatedSdkCompilation:true,dartAnalyze:true,actualSameServerHttp:['TS','Dart'],fields:['required nullable','optional omitted','enum','safe integer','decimal','large integer string','UTC date-time','list','path / ? % Unicode','repeated query rejection','HTTP400/500 errors','unknown addition','invalid schema guard']},null,2)+'\n');
}finally{clearTimeout(timeout);child.kill();}
