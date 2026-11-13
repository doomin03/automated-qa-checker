/// Fixed application code; the only runtime input is JSON data and a root path.
const portableVerifier = r'''
import {createHash} from 'node:crypto';
import {createReadStream} from 'node:fs';
import {readFile,readdir,lstat,realpath} from 'node:fs/promises';
import {resolve,relative,isAbsolute,join} from 'node:path';
try {
 const began=Date.now();
 const chunks=[];let size=0;for await(const chunk of process.stdin){size+=chunk.length;if(size>4*1024*1024)throw Error('INPUT_LIMIT');chunks.push(chunk);}
 const {expected,previous}=JSON.parse(Buffer.concat(chunks).toString('utf8')), manifest=JSON.parse(expected);
 const base=await realpath(process.argv[1]);
 const sha=b=>createHash('sha256').update(b).digest('hex');
 const receipt=join(base,'portable-runtime.json');
 if((await lstat(receipt)).isSymbolicLink() || await readFile(receipt,'utf8')!==expected)throw Error('RECEIPT_MISMATCH');
 const runtime=join(base,'runtime');
 if(!(await lstat(runtime)).isDirectory()||(await lstat(runtime)).isSymbolicLink())throw Error('RUNTIME_LINK');
 const files=manifest.files, found={}, stamps=[];let statMs=0,realpathMs=0;
 async function visit(dir){for(const e of await readdir(dir,{withFileTypes:true})){
  const path=join(dir,e.name);let t=performance.now();const stat=await lstat(path);statMs+=performance.now()-t;
  if(stat.isSymbolicLink())throw Error('PAYLOAD_LINK');
  t=performance.now();const real=await realpath(path);realpathMs+=performance.now()-t;const rel=relative(base,real);
  if(!rel||rel.startsWith('..')||isAbsolute(rel))throw Error('PATH_ESCAPE');
  if(stat.isDirectory()){await visit(path);continue;}
  if(!stat.isFile())throw Error('NON_REGULAR');
  const key=relative(base,path).replaceAll('\\','/'), spec=files[key];
  if(!spec||spec.size!==stat.size)throw Error('PAYLOAD_SIZE_OR_EXTRA');
  found[key]=path;stamps.push(`${key}:${stat.size}:${stat.mtimeMs}:${stat.ctimeMs}`);
 }}
 const listStart=Date.now();await visit(runtime);const listMs=Date.now()-listStart;
 if(Object.keys(found).length!==Object.keys(files).length)throw Error('PAYLOAD_MISSING');
 const fingerprint=sha(base+'\n'+expected+'\n'+stamps.sort().join('\n'));
 const hashStart=Date.now();if(fingerprint!==previous){for(const [key,path] of Object.entries(found)){
  const h=createHash('sha256');for await(const chunk of createReadStream(path))h.update(chunk);
  if(h.digest('hex')!==files[key].sha256)throw Error('PAYLOAD_SHA_MISMATCH');
 }}
 const result={_fingerprint:fingerprint,_listMs:String(listMs),_statMs:String(Math.round(statMs)),_realpathMs:String(Math.round(realpathMs)),_hashMs:String(Date.now()-hashStart)};
 for(const key of ['nodePath','cliPath','browserRoot']){
  const name=manifest[key];if(typeof name!=='string'||name.includes('\\')||name.includes(':')||name.split('/').some(s=>!s||s==='.'||s==='..'))throw Error('ENTRY_PATH');
  const path=join(base,name), rel=relative(base,await realpath(path));
  if(key==='browserRoot'&&!(await lstat(path)).isDirectory())throw Error('ENTRY_PATH');
  if(!rel||rel.startsWith('..')||isAbsolute(rel)||(key!=='browserRoot'&&!found[name]))throw Error('ENTRY_ESCAPE');
  result[key]=await realpath(path);
 }
 result._nativeMs=String(Date.now()-began);process.stdout.write(JSON.stringify(result));
} catch(e) { process.stdout.write(JSON.stringify({error: /^(INPUT_LIMIT|RECEIPT_MISMATCH|RUNTIME_LINK|PAYLOAD_LINK|PATH_ESCAPE|NON_REGULAR|PAYLOAD_SIZE_OR_EXTRA|PAYLOAD_MISSING|PAYLOAD_SHA_MISMATCH|ENTRY_PATH|ENTRY_ESCAPE)$/.test(e.message)?e.message:'VERIFICATION_IO_ERROR'}));process.exitCode=2; }
''';
