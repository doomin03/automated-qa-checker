import {createServer} from 'node:http';
import {readFile,realpath,stat} from 'node:fs/promises';
import {resolve,relative,isAbsolute,extname} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=await realpath(fileURLToPath(new URL('../dist/',import.meta.url)));
const routes=new Set(['/','/qa/blueprints','/qa/shared']);
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.json':'application/json; charset=utf-8','.jsonl':'application/x-ndjson; charset=utf-8','.svg':'image/svg+xml','.png':'image/png','.ico':'image/x-icon'};
const inside=file=>{const rel=relative(root,file);return !isAbsolute(rel)&&rel!=='..'&&!rel.startsWith('..\\')&&!rel.startsWith('../');};
const server=createServer(async(req,res)=>{
 const fail=status=>{res.writeHead(status,{'content-type':'application/json; charset=utf-8','cache-control':'no-store','x-content-type-options':'nosniff'});res.end(JSON.stringify({code:status===404?'NOT_FOUND':'METHOD_NOT_ALLOWED'}));};
 if(!['GET','HEAD'].includes(req.method))return fail(405);
 try{const path=decodeURIComponent(new URL(req.url,'http://localhost').pathname);if(path.includes('\\')||path.includes('\0')||path==='/api'||path.startsWith('/api/'))return fail(404);const candidate=resolve(root,'.'+(routes.has(path)?'/index.html':path));if(!inside(candidate))return fail(404);const file=await realpath(candidate);if(!inside(file)||!(await stat(file)).isFile())return fail(404);const bytes=await readFile(file);res.writeHead(200,{'content-type':types[extname(file)]??'application/octet-stream','content-length':bytes.length,'cache-control':'no-cache','x-content-type-options':'nosniff'});res.end(req.method==='HEAD'?undefined:bytes);}catch{return fail(404);}
});
server.listen(Number(process.env.PORT??4318),'127.0.0.1',()=>console.log(JSON.stringify({event:'listening',url:`http://127.0.0.1:${server.address().port}`})));
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>server.close());
