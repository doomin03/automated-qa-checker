import {readBlueprint} from './model.mjs';

// Consumer-side authoring projection of the engine's documented XML contract.
// Parsing, graph compilation and execution remain in the engine.
export function exportBlueprintXml(source) {
 const blueprint=readBlueprint(typeof source==='string'?source:JSON.stringify(source));
 const attribute=value=>String(value).replace(/[&<>"\t\n\r]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;','\t':'&#9;','\n':'&#10;','\r':'&#13;'}[c]));
 const element=(tag,attrs={},children='')=>'<'+tag+Object.entries(attrs).filter(([,v])=>v!==undefined).map(([k,v])=>' '+k+'="'+attribute(v)+'"').join('')+'>'+children+'</'+tag+'>';
 const data=(object,keys)=>keys.filter(key=>object[key]!==undefined).map(key=>element(key,{},'<![CDATA['+JSON.stringify(object[key]).replaceAll(']]>',']]]]><![CDATA[>')+']]>')).join('');
 const flow=blueprint.flow;
 const nodes=flow.nodes.map(node=>element('node',Object.fromEntries(['id','type','action','timeoutMs'].map(key=>[key,node[key]])),data(node,['params','condition','retry']))).join('\n');
 const edges=flow.edges.map(edge=>element('edge',Object.fromEntries(['from','to','label'].map(key=>[key,edge[key]])))).join('\n');
 const xml='<?xml version="1.0" encoding="UTF-8"?>\n'+element('blueprint',{schemaVersion:blueprint.schemaVersion,id:blueprint.id,name:blueprint.name},'\n'+element('flow',{id:flow.id,entryNode:flow.entryNode,name:flow.name},data(flow,['variables','metadata'])+element('nodes',{},nodes)+element('edges',{},edges))+data(blueprint,['selectors','target','testCase']))+'\n';
 if(/[\u0000-\u0008\u000b\u000c\u000e-\u001f]/u.test(xml))throw new Error('XML에서 지원하지 않는 제어 문자가 있습니다.');
 if(new TextEncoder().encode(xml).length>1024*1024)throw new Error('XML 파일은 1 MiB 이하여야 합니다.');
 return xml;
}
