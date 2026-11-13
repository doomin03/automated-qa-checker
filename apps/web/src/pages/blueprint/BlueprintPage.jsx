import React,{useState,useEffect,useRef,useMemo} from 'react';
import {engineContract} from '@automated-qa-checker/contract';
import {readBlueprint,readEvents,replay,layout,exportBlueprintXml} from '../../entities/blueprint/index.js';
import {ServerConnection} from '../../features/server-connection/index.js';
import {SharedScenarios} from '../../features/shared-scenarios/index.js';
import {Blueprint} from '../../widgets/blueprint/index.js';
const initial=JSON.stringify(engineContract.example,null,2);
export function BlueprintPage({section='blueprint'}) {
 const [blueprint,setBlueprint]=useState(()=>readBlueprint(initial)),[text,setText]=useState(initial),[events,setEvents]=useState([]),[cursor,setCursor]=useState(0),[selected,setSelected]=useState('start'),[error,setError]=useState(''),[notice,setNotice]=useState(''),[playing,setPlaying]=useState(false),[following,setFollowing]=useState(false);
 const handle=useRef(null),generation=useRef(0),alive=useRef(false),controllers=useRef(new Set()),downloads=useRef(new Map());
 useEffect(()=>{alive.current=true;return()=>{alive.current=false;generation.current++;handle.current=null;for(const controller of controllers.current)controller.abort();controllers.current.clear();for(const [url,timer] of downloads.current){clearTimeout(timer);URL.revokeObjectURL(url);}downloads.current.clear();};},[]);
 function invalidate(){generation.current++;for(const controller of controllers.current)controller.abort();controllers.current.clear();return generation.current;}
 const current=token=>alive.current&&token===generation.current;
 const state=useMemo(()=>replay(blueprint,events,cursor),[blueprint,events,cursor]),graph=useMemo(()=>layout(blueprint),[blueprint]);
 function apply(source) {
  const b=readBlueprint(source);invalidate();handle.current=null;setFollowing(false);setPlaying(false);setBlueprint(b);setText(JSON.stringify(b,null,2));setEvents([]);setCursor(0);setSelected(b.flow.entryNode);setError('');setNotice('문서를 불러왔습니다. 자동으로 실행하지 않습니다. 최종 실행 검증은 aqa validate로 진행합니다.');return b;
 }
 async function guard(fn) {try{setError('');await fn();}catch(e){if(alive.current&&e.name!=='AbortError'){setError(e.message);setPlaying(false);}}}
 async function readFile(file,kind){const token=invalidate();try{const content=await file.text();if(!current(token))return;if(kind==='blueprint')apply(content);else{setFollowing(false);setPlaying(false);await loadEvents(content);}}catch(e){if(current(token))throw e;}}
 async function loadEvents(source,b=blueprint,live=false) {
  const token=generation.current,parsed=await readEvents(source,b,{live});
  if(!current(token))return;
  setEvents(parsed);setCursor(parsed.length);
 }
 useEffect(()=>{
  if(!playing)return;
  const timer=setInterval(()=>setCursor(c=>{if(c>=events.length){setPlaying(false);return c;}return c+1;}),400);
  return ()=>clearInterval(timer);
 },[playing,events.length]);
 useEffect(()=>{
  if(!following||!handle.current)return;
  let busy=false,cancelled=false;
  const poll=async()=>{if(busy)return;busy=true;try{const file=await handle.current.getFile();const content=await file.text();if(!cancelled)await loadEvents(content,blueprint,true);}catch(e){if(!cancelled){setError(e.message);setFollowing(false);}}finally{busy=false;}};
  poll();const timer=setInterval(poll,800);
  return ()=>{cancelled=true;clearInterval(timer);};
 },[following,blueprint]);
 async function follow() {
  if(!window.showOpenFilePicker)throw new Error('이 브라우저는 파일 따라가기를 지원하지 않습니다. 이벤트 파일 불러오기를 사용하세요.');
  const token=generation.current,handles=await window.showOpenFilePicker({multiple:false,types:[{description:'QA JSONL events',accept:{'application/json':['.jsonl']}}]});if(!current(token))return;[handle.current]=handles;setPlaying(false);setFollowing(true);
 }
 function download(format='json') {
  const checked=readBlueprint(text),content=format==='xml'?exportBlueprintXml(checked):JSON.stringify(checked,null,2),url=URL.createObjectURL(new Blob([content],{type:format==='xml'?'application/xml':'application/json'}));
  const a=document.createElement('a');a.href=url;a.download=checked.id+'.qa.'+format;a.click();downloads.current.set(url,setTimeout(()=>{URL.revokeObjectURL(url);downloads.current.delete(url);},1000));
  setNotice(format==='xml'?'XML을 내려받았습니다. Flutter Desktop에서 열거나 붙여넣고 검증 후 실행하세요. 파일 전달이며 서버 자동 동기화는 아닙니다.':'JSON을 내려받았습니다.');
 }
 async function sample() {
  const token=invalidate(),controller=new AbortController();controllers.current.add(controller);
  try{const fetchText=async path=>{const response=await fetch(path,{signal:controller.signal});if(!response.ok)throw new Error('예제 파일을 읽을 수 없습니다.');return response.text();};const [source,eventText]=await Promise.all([fetchText('/demo/blueprint.json'),fetchText('/demo/events.jsonl')]);if(!current(token))return;const b=readBlueprint(source),parsed=await readEvents(eventText,b);if(!current(token))return;apply(source);setEvents(parsed);setCursor(parsed.length);setNotice('실제 Playwright 실행에서 생성한 실패 기록을 불러왔습니다.');}catch(e){if(current(token))throw e;}finally{controllers.current.delete(controller);}
 }
 const node=blueprint.flow.nodes.find(n=>n.id===selected);
 return <main>
  <header><h1>{section==='shared'?'Automated QA · 공용 시나리오':'Automated QA · Blueprint'}</h1><p>공용·사용자 테스트를 편집하고 Flutter에 XML로 전달합니다. 실제 실행 기록을 노드별로 확인합니다. 엔진 {engineContract.engineVersion}</p>{section==='shared'&&<a href="#shared-scenarios">공용 시나리오·Suite·예약 입력으로 이동</a>}</header>
  <section className="toolbar" aria-label="파일 작업">
   <label className="button">Blueprint JSON 가져오기<input data-testid="blueprint-file" type="file" accept=".json" onChange={e=>{const f=e.target.files[0];if(f)guard(()=>readFile(f,'blueprint'));e.target.value='';}}/></label>
   <label className="button">이벤트 JSONL 불러오기<input data-testid="events-file" type="file" accept=".jsonl" onChange={e=>{const f=e.target.files[0];if(f)guard(()=>readFile(f,'events'));e.target.value='';}}/></label>
   <button onClick={()=>guard(sample)}>실제 실패 기록 예제</button>
   <button onClick={()=>guard(follow)} disabled={following}>이벤트 파일 따라가기</button>
   {following&&<button onClick={()=>setFollowing(false)}>따라가기 중지</button>}
  </section>
  {error&&<p role="alert" className="error">{error}</p>}
  {notice&&<p role="status">{notice}</p>}
  <section className="summary"><strong data-testid="run-outcome">{state.outcome}</strong><span>방문 완료 {state.completed} / 전체 {blueprint.flow.nodes.length}</span><span>이벤트 {cursor} / {events.length}</span>{following&&<span>파일 변경 확인 중</span>}</section>
  <div className="toolbar"><button disabled={!events.length||following} onClick={()=>{setCursor(0);setPlaying(true);}}>처음부터 재생</button><button onClick={()=>setPlaying(false)} disabled={!playing}>일시정지</button><input aria-label="이벤트 재생 위치" type="range" min="0" max={events.length} value={cursor} disabled={following} onChange={e=>{setPlaying(false);setCursor(Number(e.target.value));}}/></div>
  <Blueprint blueprint={blueprint} graph={graph} states={state.states} selected={selected} onSelect={setSelected}/>
  <div className="columns">
   <section><h2>선택한 노드: {node?.id}</h2><pre>{JSON.stringify(node,null,2)}</pre>{state.failure&&<><h3>실패 원인</h3><pre data-testid="failure">{JSON.stringify(state.failure,null,2)}</pre></>}<h3>실행 이벤트</h3><ol className="events">{events.slice(0,cursor).map(e=><li key={e.sequence}>{e.sequence} · {e.type} · {e.nodeId||'run'} {e.outcome||''}</li>)}</ol></section>
   <section><h2>Flow JSON</h2><textarea aria-label="Blueprint JSON 편집" value={text} onChange={e=>{invalidate();setText(e.target.value);}} spellCheck="false"/><div className="toolbar"><button onClick={()=>guard(()=>apply(text))}>검사 후 화면에 적용</button><button onClick={()=>guard(()=>download())}>JSON 내보내기</button><button onClick={()=>guard(()=>download('xml'))}>Flutter용 XML 내보내기</button></div></section>
  </div>
  <section><h2>웹에서 Flutter로 테스트 전달</h2><ol><li>공용 예제 또는 사용자 JSON을 가져와 수정하고 XML로 내려받습니다.</li><li>Flutter Desktop에서 XML 파일을 열거나 직접 XML을 붙여넣고 검증·계획을 확인합니다.</li><li>Flutter에서 실행을 눌러 실제 테스트를 시작합니다. 가져오기와 검증만으로 실행하지 않습니다.</li><li>실행 폴더의 blueprint.json과 events.jsonl을 웹에서 불러오거나 파일 따라가기로 진행을 확인합니다.</li></ol><p>파일 전달 또는 공용 Registry를 사용합니다. Flutter에서 블록·반복·XML을 작성하고 명시 실행하면 선택한 서버에 진행을 게시할 수 있습니다. 고정 엔진은 Playwright와 Appium adapter를 제공하며 실제 모바일 기기 인수·조직 로그인·예약은 별도입니다.</p></section>
  <ServerConnection/>
  <section id="shared-scenarios"><SharedScenarios sourceXml={()=>exportBlueprintXml(readBlueprint(text))} onRemote={(b,ev)=>{invalidate();handle.current=null;setFollowing(false);setPlaying(false);setBlueprint(b);setText(JSON.stringify(b,null,2));setEvents(ev);setCursor(ev.length);setSelected(b.flow.entryNode);setNotice('서버에 게시된 실제 실행 snapshot과 진행입니다. 외부 실행의 신뢰·실기기 검증 보증은 별도입니다.');}}/></section>
 </main>;
}

