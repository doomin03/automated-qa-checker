import {validateContract} from '@automated-qa-checker/contract';
export function canonicalJson(value) {
 if(Array.isArray(value)) return '['+value.map(canonicalJson).join(',')+']';
 if(value && typeof value==='object') return '{'+Object.keys(value).sort().map(k=>JSON.stringify(k)+':'+canonicalJson(value[k])).join(',')+'}';
 return JSON.stringify(value);
}
export async function blueprintHash(b) {
 const digest=await crypto.subtle.digest('SHA-256',new TextEncoder().encode(canonicalJson(b)));
 return 'sha256:'+Array.from(new Uint8Array(digest),x=>x.toString(16).padStart(2,'0')).join('');
}
export function readBlueprint(text) {
 if(new TextEncoder().encode(text).length>1024*1024) throw new Error('Blueprint는 1 MiB 이하여야 합니다.');
 const b=validateContract(JSON.parse(text),'blueprint');
 const ids=new Set(b.flow.nodes.map(n=>n.id));
 if(ids.size!==b.flow.nodes.length) throw new Error('중복 node ID');
 if(!ids.has(b.flow.entryNode)) throw new Error('entryNode가 없습니다.');
 for(const edge of b.flow.edges) if(!ids.has(edge.from)||!ids.has(edge.to)) throw new Error('존재하지 않는 node를 가리키는 edge');
 const visited=new Set(),active=new Set();
 const walk=id=>{
  if(active.has(id)) throw new Error('순환 graph는 지원하지 않습니다.');
  if(visited.has(id)) return;
  active.add(id);for(const e of b.flow.edges.filter(e=>e.from===id))walk(e.to);
  active.delete(id);visited.add(id);
 };
 walk(b.flow.entryNode);
 if(visited.size!==ids.size) throw new Error('도달할 수 없는 node가 있습니다.');
 return b;
}
export async function readEvents(text,blueprint,{live=false}={}) {
 if(text.length>16*1024*1024) throw new Error('이벤트 파일이 16 MiB를 초과했습니다.');
 const lines=text.split(/\r?\n/);
 if(live && !text.endsWith('\n')) lines.pop(); // Wait for an append-in-progress record.
 const unique=new Map();let runId,attempt;
 const nodes=new Set(blueprint.flow.nodes.map(n=>n.id));
 for(const line of lines.filter(l=>l.trim())) {
  const e=validateContract(JSON.parse(line),'event');
  if(runId && (runId!==e.runId||attempt!==e.attempt)) throw new Error('서로 다른 run/attempt가 섞여 있습니다.');
  runId=e.runId;attempt=e.attempt;
  if(e.nodeId&&!nodes.has(e.nodeId)) throw new Error('Blueprint에 없는 node event');
  const previous=unique.get(e.sequence);
  if(previous && canonicalJson(previous)!==canonicalJson(e)) throw new Error('같은 sequence의 내용이 다릅니다.');
  unique.set(e.sequence,e);
 }
 const events=[...unique.values()].sort((a,b)=>a.sequence-b.sequence);
 for(let i=0;i<events.length;i++) if(events[i].sequence!==i+1) throw new Error('이벤트 sequence 누락: '+(i+1));
 if(events.length) {
  if(events[0].type!=='run.started'||events.filter(e=>e.type==='run.started').length!==1) throw new Error('run.started가 올바르지 않습니다.');
  if(events[0].blueprintSnapshotHash!==await blueprintHash(blueprint)) throw new Error('실행 snapshot과 Blueprint가 다릅니다.');
  const terminal=events.filter(e=>e.type==='run.finished');
  if(terminal.length>1||(terminal.length&&events.at(-1)!==terminal[0])) throw new Error('terminal event 뒤에 추가 이벤트가 있습니다.');
  const started=new Set(),finished=new Set();let active;
  for(const e of events.slice(1)) {
   if(e.type==='step.started') {
    if(active||started.has(e.nodeId))throw new Error('노드 시작 순서가 올바르지 않습니다.');
    active=e.nodeId;started.add(active);
   } else if(e.type==='step.retrying') {
    if(active!==e.nodeId)throw new Error('실행 중이 아닌 노드의 retry');
   } else if(e.type==='step.finished') {
    if(active!==e.nodeId||finished.has(e.nodeId))throw new Error('노드 종료 순서가 올바르지 않습니다.');
    finished.add(e.nodeId);active=undefined;
   } else if(e.type==='run.finished'&&active)throw new Error('노드 종료 이벤트가 누락되었습니다.');
  }
 }
 return events;
}
export function replay(blueprint,events,count=events.length) {
 const states=Object.fromEntries(blueprint.flow.nodes.map(n=>[n.id,'pending']));
 let outcome='not_started',failure;
 for(const e of events.slice(0,count)) {
  if(e.type==='run.started')outcome='running';
  if(e.type==='step.started'||e.type==='step.retrying')states[e.nodeId]='running';
  if(e.type==='step.finished')states[e.nodeId]=e.outcome;
  if(e.failure)failure=e.failure;
  if(e.type==='run.finished') {outcome=e.outcome;for(const id of Object.keys(states))if(states[id]==='pending')states[id]='unrun';}
 }
 return {states,outcome,failure,completed:Object.values(states).filter(s=>['passed','failed','infra_error','blocked','cancelled'].includes(s)).length};
}
export function layout(blueprint) {
 const ids=blueprint.flow.nodes.map(n=>n.id),depth=Object.fromEntries(ids.map(id=>[id,0])),indegree=Object.fromEntries(ids.map(id=>[id,0]));
 for(const e of blueprint.flow.edges)indegree[e.to]++;
 const queue=ids.filter(id=>indegree[id]===0);
 while(queue.length) {const id=queue.shift();for(const e of blueprint.flow.edges.filter(e=>e.from===id)){depth[e.to]=Math.max(depth[e.to],depth[id]+1);if(--indegree[e.to]===0)queue.push(e.to);}}
 const rows={};const positions=Object.fromEntries(ids.map(id=>{const d=depth[id];const row=rows[d]||0;rows[d]=row+1;return [id,{x:24+d*200,y:24+row*116}];}));
 return {positions,width:Math.max(700,...Object.values(positions).map(p=>p.x+180)),height:Math.max(220,...Object.values(positions).map(p=>p.y+100))};
}

