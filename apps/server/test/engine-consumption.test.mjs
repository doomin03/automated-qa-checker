import 'reflect-metadata';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, writeFile, mkdir } from 'node:fs/promises';
import { resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { EngineContractService } from '../dist/src/modules/platform/engine-contract.service.js';

test('Engine command handles chunked UTF8, output limits, invalid JSON and deadline', {timeout:25000}, async () => {
  const root=fileURLToPath(new URL('../../../',import.meta.url));
  const output=resolve(root,'artifacts/service-audit');await mkdir(output,{recursive:true});
  const temp=await mkdtemp(join(output,'server-'));
  const cli=join(temp,'child.mjs'),pid=join(temp,'child.pid');
  await writeFile(cli,`import {writeFileSync} from 'node:fs';
writeFileSync(${JSON.stringify(pid)},String(process.pid));
const mode=process.argv[2];
if(mode==='large'){const b=Buffer.from(JSON.stringify({value:'한'.repeat(300000)}));for(let i=0;i<b.length;i+=4093)process.stdout.write(b.subarray(i,i+4093));}
if(mode==='stderr'){process.stderr.write('x'.repeat(3*1024*1024));setTimeout(()=>{},60000);}
if(mode==='hang')setTimeout(()=>{},60000);
if(mode==='bad')process.stdout.write('PRIVATE_SENTINEL_INVALID_JSON');
`);
  // Isolate the process boundary; public schema/HTTP tests remain separate.
  const service=new EngineContractService();service.cli=cli;
  const results=[];
  for(const [mode,expected] of [['large',null],['stderr','Engine diagnostics exceeded limit'],['bad','Invalid Engine CLI response'],['hang','Engine validation timed out']]) {
    const start=performance.now();let outcome='accepted';
    if(expected)await assert.rejects(service.command([mode]),error=>{outcome=error.message;return error.message===expected;});
    else assert.equal((await service.command([mode])).value,'한'.repeat(300000));
    const elapsedMs=Math.round(performance.now()-start);
    const childPid=Number(await readFile(pid,'utf8'));let alive=false;try{process.kill(childPid,0);alive=true;}catch{}
    assert.equal(alive,false);assert(elapsedMs<21000);assert(!outcome.includes('PRIVATE_SENTINEL'));
    results.push({mode,outcome,elapsedMs,childAlive:alive});
  }
  await writeFile(join(output,'server-regression.json'),JSON.stringify(results,null,2)+'\n');
});
