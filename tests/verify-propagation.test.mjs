import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync,readFileSync,writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
test('actual Windows verify command chains stop at each failed stage',{skip:process.platform!=='win32'},()=>{
 const dir=mkdtempSync(join(tmpdir(),'qa-propagation-')),log=join(dir,'calls.jsonl'),stub=join(dir,'stub.cjs');
 writeFileSync(stub,"const fs=require('node:fs');const stage=process.argv.slice(2).join(' ');fs.appendFileSync(process.env.QA_CALL_LOG,JSON.stringify(stage)+'\\n');process.exit(stage===process.env.QA_FAIL_STAGE?17:0);");
 writeFileSync(join(dir,'pnpm.cmd'),`@echo off\r\n"${process.execPath}" "${stub}" %*\r\nexit /b %errorlevel%\r\n`);
 const pkg=JSON.parse(readFileSync(resolve('package.json'),'utf8'));
 for(const name of ['verify','verify:all']){const command=pkg.scripts[name],stages=command.split(/\s*&&\s*/).map(part=>{assert.match(part,/^pnpm run [\w:-]+$/);return part.replace(/^pnpm /,'');});
  for(let i=0;i<stages.length;i++){writeFileSync(log,'');const run=spawnSync(process.env.ComSpec??'cmd.exe',['/d','/s','/c',command],{cwd:dir,env:{...process.env,PATH:dir+';'+process.env.PATH,QA_CALL_LOG:log,QA_FAIL_STAGE:stages[i]},encoding:'utf8',windowsHide:true});assert.notEqual(run.status,0,name+':'+stages[i]);assert.deepEqual(readFileSync(log,'utf8').trim().split('\n').map(JSON.parse),stages.slice(0,i+1));}
 }
});
