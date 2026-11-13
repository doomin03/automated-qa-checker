// Execute unchanged assertions with separate output destinations.
import {readFile,writeFile,unlink,mkdir} from 'node:fs/promises';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
const root=new URL('./',import.meta.url),checks=[];
for(const [relative,kind] of [['verify-home.mjs','home'],['verify.mjs','editor'],['../product-planning/verify.mjs','portal']]){
 const original=new URL(relative,root),temporary=new URL(`verify-terminal-${kind}.temporary.mjs`,original);
 let source=await readFile(original,'utf8');
 source=source.replaceAll('./screenshots/home/','./screenshots/multi-terminal/regression-home/').replaceAll('./screenshots/editor-regression/','./screenshots/multi-terminal/regression-editor/');
 source=source.replaceAll('verification-home.json','verification-terminal-home.json').replaceAll('verification-editor.json','verification-terminal-editor.json');
 if(kind==='portal')source=source.replaceAll("'verification.json'","'verification-terminal-portal.json'");
 await writeFile(temporary,source,'utf8');
 try{const result=spawnSync(process.execPath,[fileURLToPath(temporary)],{cwd:fileURLToPath(new URL('../../../',root)),encoding:'utf8'});const output=result.stdout+result.stderr;console.log(output.trim());checks.push({kind,exitCode:result.status,output});if(result.status!==0)throw new Error(`${kind} regression failed`);}finally{await unlink(temporary);await writeFile(new URL('verification-terminal-regressions.json',root),JSON.stringify({scope:'Existing assertions, new artifact destinations only',status:checks.every(c=>c.exitCode===0)?'passed':'failed',checks},null,2));}
}
