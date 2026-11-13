/* Editor subset of the public Engine XML. Not an execution schema or interpreter. */
(() => {
 const allowed = {blueprint:['schemaVersion','id','name'],flow:['id','entryNode'],variables:[],nodes:[],node:['id','type','action','timeoutMs'],params:[],edges:[],edge:['from','to','label'],selectors:[],target:[]};
 const params = {launch:['target'],input:['selector','valueRef','value'],tap:['selector'],assertText:['selector','expected'],screenshot:[]};
 const names={start:'시작',end:'종료',launch:'페이지 열기',input:'사용자 이름 입력',tap:'로그인 선택',assertText:'환영 문구 확인',screenshot:'화면 증거 저장'};
 function fail(message){throw new Error(message);}
 function parse(raw){
  try {
   if(raw.length>100000)fail('목업 입력은 100KB까지 지원합니다.');
   if(/<!DOCTYPE|<!ENTITY/i.test(raw))fail('DTD/ENTITY는 이 목업에서 지원하지 않습니다.');
   const dom=new DOMParser().parseFromString(raw,'application/xml');
   if(dom.querySelector('parsererror'))fail('XML 문법이 올바르지 않습니다. 원문을 확인하세요.');
   const root=dom.documentElement;
   if(root.tagName!=='blueprint'||root.getAttribute('schemaVersion')!=='qa.blueprint/v1')fail('공개 qa.blueprint/v1 루트만 편집할 수 있습니다.');
   for(const el of dom.querySelectorAll('*')){
    if(!Object.hasOwn(allowed,el.tagName))fail(`미지원 XML 요소: ${el.tagName}`);
    for(const attr of el.attributes)if(!allowed[el.tagName].includes(attr.name))fail(`미지원 속성: ${el.tagName}.${attr.name}`);
   }
   for(const el of dom.querySelectorAll('params,variables,selectors,target'))if(el.children.length)fail(`JSON 구역에 XML 자식은 허용하지 않습니다: ${el.tagName}`);
   const children=(el,tags)=>{for(const child of el.children)if(!tags.includes(child.tagName))fail(`미지원 구조: ${el.tagName}/${child.tagName}`);};
   children(root,['flow','selectors','target']);
   for(const tag of ['flow','selectors','target'])if(root.querySelectorAll(':scope > '+tag).length!==1)fail(`${tag}는 한 개만 지원합니다.`);
   const flow=root.querySelector(':scope > flow');children(flow,['variables','nodes','edges']);
   for(const tag of ['variables','nodes','edges'])if(flow.querySelectorAll(':scope > '+tag).length!==1)fail(`${tag}는 한 개여야 합니다.`);
   children(flow.querySelector('nodes'),['node']);children(flow.querySelector('edges'),['edge']);
   const variables=JSON.parse(flow.querySelector('variables').textContent),selectors=JSON.parse(root.querySelector('selectors').textContent),target=JSON.parse(root.querySelector('target').textContent);
   if(!variables||Array.isArray(variables)||!selectors.selectors||!target.launchTargets)fail('선언 구역의 공개 예시 구조를 확인하세요.');
   const nodes=[...flow.querySelectorAll('nodes > node')].map(el=>{
    children(el,['params']);const id=el.getAttribute('id'),type=el.getAttribute('type'),action=el.getAttribute('action');
    if(!id||!/^[A-Za-z][A-Za-z0-9_.-]{0,127}$/.test(id))fail('node ID 형식을 확인하세요.');
    if(!['start','end','action','assertion'].includes(type))fail(`미지원 node type: ${type}`);
    if(type==='start'||type==='end'){if(action||el.children.length)fail('start/end는 params 없는 기본형만 지원합니다.');}
    else if(!Object.hasOwn(params,action))fail(`미지원 action: ${action}`);
    if(type==='assertion'&&action!=='assertText'||type==='action'&&action==='assertText')fail('node type/action 조합을 확인하세요.');
    const p=el.querySelector('params')?JSON.parse(el.querySelector('params').textContent):{};
    if(!p||Array.isArray(p)||typeof p!=='object')fail('params는 JSON object여야 합니다.');
    if(el.querySelectorAll('params').length>1)fail('params는 한 개만 지원합니다.');
    for(const key of Object.keys(p))if(!(params[action]??[]).includes(key))fail(`미지원 params: ${action}.${key}`);
    if(action==='launch'&&(!p.target||!Object.hasOwn(target.launchTargets,p.target)))fail('없는 launch target 참조입니다.');
    if(['input','tap','assertText'].includes(action)&&(!p.selector||!Object.hasOwn(selectors.selectors,p.selector)))fail('없는 selector 참조입니다.');
    if(action==='input'&&((p.valueRef===undefined)===(p.value===undefined)))fail('input은 value 또는 valueRef 하나가 필요합니다.');
    if(p.valueRef!==undefined&&!Object.hasOwn(variables,p.valueRef))fail('없는 variable 참조입니다.');
    if(action==='assertText'&&typeof p.expected!=='string')fail('assertText expected 문자열이 필요합니다.');
    const timeout=el.getAttribute('timeoutMs');if(timeout!==null&&(!/^\d+$/.test(timeout)||+timeout>120000||+timeout<1))fail('timeoutMs 범위를 확인하세요.');
    return {id,type,action,params:p,timeout:timeout?+timeout:null,title:names[action??type],element:el};
   });
   if(nodes.length<2||nodes.length>30)fail('목업은 2~30개 node를 지원합니다.');
   const byId=new Map(nodes.map(n=>[n.id,n]));if(byId.size!==nodes.length)fail('중복 node ID입니다.');
   const start=nodes.filter(n=>n.type==='start'),end=nodes.filter(n=>n.type==='end');if(start.length!==1||end.length!==1||flow.getAttribute('entryNode')!==start[0].id)fail('start/end/entryNode를 확인하세요.');
   const edges=[...flow.querySelectorAll('edges > edge')].map(el=>({from:el.getAttribute('from'),to:el.getAttribute('to'),label:el.getAttribute('label')}));
   if(edges.some(e=>!byId.has(e.from)||!byId.has(e.to)))fail('없는 node를 참조하는 edge입니다.');
   if(edges.some(e=>e.label!==null))fail('분기 label은 이 목업의 편집 범위 밖입니다. 원문은 보존됩니다.');
   for(const n of nodes){const incoming=edges.filter(e=>e.to===n.id).length,outgoing=edges.filter(e=>e.from===n.id).length;if(incoming!==(n.type==='start'?0:1)||outgoing!==(n.type==='end'?0:1))fail('분기/다중 연결/연결 누락은 편집할 수 없습니다.');}
   const ordered=[],visited=new Set();let id=start[0].id;
   while(id){if(visited.has(id))fail('cycle은 지원하지 않습니다.');visited.add(id);ordered.push(byId.get(id));id=edges.find(e=>e.from===id)?.to;}
   if(ordered.length!==nodes.length||ordered.at(-1).id!==end[0].id)fail('연결되지 않은 node가 있습니다.');
   return {ok:true,dom,root,flow,nodes:ordered,edges,byId,variables,selectors,target};
  } catch(error){return {ok:false,error:error.message};}
 }
 function serialize(dom){return new XMLSerializer().serializeToString(dom);}
 function proposal(raw,selected,scope){
  const model=parse(raw);if(!model.ok)fail(model.error);const node=model.byId.get(selected);if(scope!=='whole'&&!node)fail('선택 블록이 없습니다.');
  const affected=[],changes=[];
  function modify(n){if(['start','end'].includes(n.type))fail('시작/종료 블록의 수정 예시는 지원하지 않습니다.');const before=n.timeout??'기본';n.element.setAttribute('timeoutMs','5000');affected.push(n.id);changes.push(`${n.id}: 제한 시간 ${before} → 5000 ms`);}
  function insert(edge){if(!edge)fail('시작 앞/종료 뒤에는 삽입할 수 없습니다.');let id='capture_ai',i=1;while(model.byId.has(id))id='capture_ai_'+i++;const fresh=model.dom.createElement('node');fresh.setAttribute('id',id);fresh.setAttribute('type','action');fresh.setAttribute('action','screenshot');const p=model.dom.createElement('params');p.appendChild(model.dom.createCDATASection('{}'));fresh.appendChild(p);model.flow.querySelector('nodes').appendChild(fresh);const old=[...model.flow.querySelectorAll('edge')].find(e=>e.getAttribute('from')===edge.from&&e.getAttribute('to')===edge.to);old.setAttribute('to',id);const after=model.dom.createElement('edge');after.setAttribute('from',id);after.setAttribute('to',edge.to);model.flow.querySelector('edges').appendChild(after);affected.push(id,edge.from,edge.to);changes.push(`${edge.from} → ${edge.to} 연결을 ${edge.from} → ${id} → ${edge.to}로 변경`);}
  if(scope==='modify')modify(node);
  else if(scope==='before')insert(model.edges.find(e=>e.to===selected));
  else if(scope==='after')insert(model.edges.find(e=>e.from===selected));
  else if(scope==='whole'){model.nodes.filter(n=>n.action==='assertText').forEach(modify);const launch=model.nodes.find(n=>n.action==='launch');if(!launch)fail('전체 변경 예시는 launch가 필요합니다.');insert(model.edges.find(e=>e.from===launch.id));}
  else fail('편집 범위를 선택하세요.');
  const xml=serialize(model.dom),checked=parse(xml);if(!checked.ok)fail(checked.error);return {xml,affected:[...new Set(affected)],changes};
 }
 window.BlueprintModel={parse,proposal,serialize};
})();
