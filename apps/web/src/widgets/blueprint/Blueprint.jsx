import React from 'react';
const labels={pending:'대기',running:'실행 중',passed:'성공',failed:'실패',infra_error:'환경 오류',blocked:'차단',cancelled:'취소',unrun:'미실행'};
export function Blueprint({blueprint,graph,states,selected,onSelect}) {
 return <div className="graph-scroll"><div className="graph" style={{width:graph.width,height:graph.height}}>
  <svg width={graph.width} height={graph.height} aria-label="노드 연결선">
   <defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto"><path d="M 0 0 L 10 5 L 0 10 z" fill="#777"/></marker></defs>
   {blueprint.flow.edges.map((edge,i)=>{const a=graph.positions[edge.from],b=graph.positions[edge.to];return <g key={i}><path d={'M '+(a.x+160)+' '+(a.y+38)+' C '+(a.x+180)+' '+(a.y+38)+','+(b.x-20)+' '+(b.y+38)+','+b.x+' '+(b.y+38)} fill="none" stroke="#777" markerEnd="url(#arrow)"/>{edge.label&&<text x={a.x+164} y={a.y+22} fontSize="12">{edge.label}</text>}</g>;})}
  </svg>
  {blueprint.flow.nodes.map(node=><button key={node.id} data-testid={'node-'+node.id} className={'node '+states[node.id]+(selected===node.id?' selected':'')} style={{left:graph.positions[node.id].x,top:graph.positions[node.id].y}} onClick={()=>onSelect(node.id)}>
   <strong>{node.id}</strong><span>{node.action||node.type}</span><small>{labels[states[node.id]]||states[node.id]}</small>
  </button>)}
 </div></div>;
}

