import {readFile} from 'node:fs/promises';
import {resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';

const same=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
const set=value=>[...(value??[])].sort();
/** Conservative shared request/response compatibility: optional new fields are allowed. */
export function breakingChanges(before,after){
 const errors=[];
 const issue=(path,kind)=>errors.push(`${path}: ${kind}`);
 // Follow transitive refs in both versions: a response model reused by any request
 // cannot gain a required input field under the response-only exception.
 function references(document){const requests=new Set(),responses=new Set();function visit(value,refs){if(!value||typeof value!=='object')return;if(typeof value.$ref==='string'&&value.$ref.startsWith('#/components/schemas/')){const name=value.$ref.slice('#/components/schemas/'.length);if(!refs.has(name)){refs.add(name);visit(document.components?.schemas?.[name],refs);}}for(const [key,child]of Object.entries(value))if(key!=='$ref')visit(child,refs);}for(const item of Object.values(document.paths??{})){visit(item.parameters,requests);for(const method of ['get','post','put','patch','delete','head','options']){const op=item[method];if(!op)continue;visit(op.parameters,requests);visit(op.requestBody,requests);visit(op.responses,responses);}}return{requests,responses};}
 const oldRefs=references(before),newRefs=references(after);
 const responseOnly=name=>(oldRefs.responses.has(name)||newRefs.responses.has(name))&&!oldRefs.requests.has(name)&&!newRefs.requests.has(name);
 function schema(a,b,path,outputOnly=false){
  if(!b){issue(path,'schema removed');return;}
  for(const key of ['$ref','type','format','pattern','minimum','maximum','minLength','maxLength','minItems','maxItems','additionalProperties'])if(!same(a[key],b[key]))issue(path,`${key} changed`);
  if(Boolean(a.nullable)!==Boolean(b.nullable))issue(path,'nullable changed');
  if(!same(set(a.required),set(b.required))){const removed=(a.required??[]).some(key=>!(b.required??[]).includes(key));const added=(b.required??[]).filter(key=>!(a.required??[]).includes(key));const safe=outputOnly&&!removed&&added.every(key=>!Object.hasOwn(a.properties??{},key)&&Object.hasOwn(b.properties??{},key));if(!safe)issue(path,'required set changed');}
  if(!same(set(a.enum),set(b.enum)))issue(path,'enum changed');
  for(const kind of ['oneOf','anyOf','allOf','not'])if(!same(a[kind],b[kind]))issue(path,`${kind} changed`);
  for(const [name,value]of Object.entries(a.properties??{})){if(!b.properties?.[name])issue(`${path}.${name}`,'property removed');else schema(value,b.properties[name],`${path}.${name}`,outputOnly);}
  if(a.items)schema(a.items,b.items,`${path}[]`,outputOnly);
 }
 function content(a,b,path,outputOnly=false){for(const [mime,value]of Object.entries(a??{})){if(!b?.[mime])issue(`${path}/${mime}`,'media type removed');else if(value.schema)schema(value.schema,b[mime].schema,`${path}/${mime}`,outputOnly);}}
 for(const [path,item]of Object.entries(before.paths??{})){
  const next=after.paths?.[path];if(!next){issue(path,'path removed');continue;}
  for(const method of ['get','post','put','patch','delete','head','options']){
   const op=item[method];if(!op)continue;const nextOp=next[method];if(!nextOp){issue(`${method} ${path}`,'operation removed');continue;}
   const label=`${method} ${path}`;if(op.operationId!==nextOp.operationId)issue(label,'operationId changed');
   if(!same(op.security??before.security,nextOp.security??after.security))issue(label,'security changed');
   const a=[...(item.parameters??[]),...(op.parameters??[])],b=[...(next.parameters??[]),...(nextOp.parameters??[])];
   for(const p of a){const n=b.find(q=>q.in===p.in&&q.name===p.name);if(!n)issue(`${label}/${p.in}:${p.name}`,'parameter removed');else{if(Boolean(p.required)!==Boolean(n.required))issue(label,'parameter required changed');if(p.schema)schema(p.schema,n.schema,`${label}/${p.name}`);}}
   for(const n of b)if(n.required&&!a.some(p=>p.in===n.in&&p.name===n.name))issue(label,'new required parameter');
   if(Boolean(op.requestBody?.required)!==Boolean(nextOp.requestBody?.required))issue(label,'request body required changed');
   if(op.requestBody){if(!nextOp.requestBody)issue(label,'request body removed');else content(op.requestBody.content,nextOp.requestBody.content,`${label}/request`);}
   for(const [status,response]of Object.entries(op.responses??{})){const n=nextOp.responses?.[status];if(!n)issue(`${label}/${status}`,'response removed');else content(response.content,n.content,`${label}/${status}`,true);}
  }
 }
 for(const [name,value]of Object.entries(before.components?.schemas??{}))schema(value,after.components?.schemas?.[name],`schema ${name}`,responseOnly(name));
 return [...new Set(errors)].sort();
}
export async function main(args=process.argv.slice(2)){
 const options={};for(let i=0;i<args.length;i+=2){if(!['--baseline','--base-ref','--candidate','--review'].includes(args[i])||!args[i+1])throw Error('Use --baseline FILE or --base-ref REF, optional --candidate FILE / --review METADATA');options[args[i]]=args[i+1];}
 if(options['--baseline']&&options['--base-ref'])throw Error('Choose exactly one baseline source');
 const candidate=JSON.parse(await readFile(resolve(options['--candidate']??'packages/contract/openapi.json'),'utf8'));
 let bytes,source;
 if(options['--base-ref']){source=`${options['--base-ref']}:packages/contract/openapi.json`;bytes=execFileSync('git',['show',source],{windowsHide:true,maxBuffer:16*1024*1024,stdio:['ignore','pipe','pipe']});}
 else{source=options['--baseline']??'packages/contract/baselines/reviewed-local.json';bytes=await readFile(resolve(source));}
 const hash=createHash('sha256').update(bytes).digest('hex');
 if(options['--review']||(!options['--base-ref']&&!options['--baseline'])){const review=JSON.parse(await readFile(resolve(options['--review']??'packages/contract/baselines/reviewed-local.metadata.json'),'utf8'));if(review.sha256!==hash||review.status!=='accepted')throw Error('Reviewed baseline hash/status mismatch');}
 const errors=breakingChanges(JSON.parse(bytes),candidate);if(errors.length)throw Error(`Breaking API changes against ${source}\n${errors.join('\n')}`);
 process.stdout.write(JSON.stringify({compatible:true,source,sha256:hash})+'\n');
}
if(process.argv[1]&&import.meta.url===pathToFileURL(resolve(process.argv[1])).href)main().catch(error=>{console.error(error.message);process.exitCode=1;});
