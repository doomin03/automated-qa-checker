import React,{useState,useEffect,useRef} from 'react';
import {PlatformClient,OrganizationClient} from '../../shared/api/index.js';
import {readBlueprint,readEvents,blueprintHash} from '../../entities/blueprint/index.js';
import {RunWork} from './RunWork.jsx';
import {SuiteExecutions} from './SuiteExecutions.jsx';

async function hash(bytes){return Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');}
export function SharedScenarios({sourceXml,onRemote}){
 const [origin,setOrigin]=useState('http://127.0.0.1:4319'),[token,setToken]=useState(''),[project,setProject]=useState(''),[message,setMessage]=useState('선택 기능 · 명시한 로컬 테스트 서버에 연결하세요.'),[error,setError]=useState(''),[busy,setBusy]=useState(false),[connected,setConnected]=useState(false);
 const [drafts,setDrafts]=useState([]),[versions,setVersions]=useState([]),[runs,setRuns]=useState([]),[audit,setAudit]=useState([]),[cursors,setCursors]=useState({}),[packageId,setPackageId]=useState('user-scenario'),[title,setTitle]=useState('사용자 시나리오'),[version,setVersion]=useState('1.0.0'),[dependencies,setDependencies]=useState('[]'),[selected,setSelected]=useState(null),[diff,setDiff]=useState(''),[remote,setRemote]=useState(null),[watching,setWatching]=useState(false),[evidence,setEvidence]=useState([]);
 const client=useRef(null),connection=useRef(0),watch=useRef(0),snapshot=useRef(null),history=useRef([]),callback=useRef(onRemote),publishKeys=useRef(new Map());callback.current=onRemote;
 const [organization,setOrganization]=useState(null);
 useEffect(()=>()=>{connection.current++;watch.current++;client.current?.close();},[]);
 async function action(fn){if(busy)return;setBusy(true);setError('');try{await fn();}catch(e){setError(e.message||'공유 요청 실패');}finally{setBusy(false);}}
 async function list(kind,more=false){const api=client.current,p=api.project,epoch=connection.current;const page=await api[kind](p,{cursor:more?cursors[kind]:undefined,limit:20});if(epoch!==connection.current)return;({drafts:setDrafts,versions:setVersions,runs:setRuns,audit:setAudit})[kind](old=>more?[...old,...page.items]:page.items);setCursors(old=>({...old,[kind]:page.nextCursor}));}
 async function organizationSession(){const api=new OrganizationClient(origin);try{const session=await api.getSession();setOrganization({origin,session});setToken('');if(session.projects.length===1)setProject(session.projects[0].id);setMessage(`조직 로그인: ${session.userId}. 프로젝트를 확인하고 공유 연결을 누르세요.`);}finally{api.close();}}
 async function logout(){if(!organization)return;const api=new OrganizationClient(organization.origin,{csrfToken:organization.session.csrfToken});try{await api.logout();}finally{api.close();client.current?.close();connection.current++;watch.current++;setConnected(false);setWatching(false);setOrganization(null);setToken('');setMessage('로그아웃했습니다. 로컬 테스트 개발은 계속할 수 있습니다.');}}
 async function connect(){connection.current++;watch.current++;setWatching(false);client.current?.close();setConnected(false);setRemote(null);setSelected(null);setEvidence([]);setDiff('');setDrafts([]);setVersions([]);setRuns([]);setAudit([]);setCursors({});const session=organization?.origin===origin?organization.session:null;const api=new PlatformClient(origin,session?'':token,session?{session:true,csrfToken:session.csrfToken}:{});api.project=project;client.current=api;const me=await api.me();const membership=me.projects.find(p=>p.id===project);if(!membership)throw new Error('프로젝트 membership이 없습니다.');setConnected(true);setMessage(`${me.localMode?'로컬 테스트 identity':'조직 인증 사용자'}: ${me.userId} · 프로젝트 ${project}`);await Promise.all(['drafts','versions','runs',...(['qa_manager','admin'].includes(membership.role)?['audit']:[])].map(k=>list(k)));}
 async function chooseVersion(id){const api=client.current,v=await api.version(api.project,id);if(await hash(new TextEncoder().encode(v.xml))!==v.sha256)throw new Error('XML hash 불일치');setSelected(v);const pins=await api.pins(api.project,{limit:100});const previous=pins.items.find(p=>p.packageId===v.packageId);setDiff(previous&&previous.versionId!==id?JSON.stringify(await api.upgradeDiff(api.project,previous.versionId,id),null,2):'새 고정 버전 또는 현재 고정 버전');}
 function download(){const url=URL.createObjectURL(new Blob([selected.xml],{type:'application/xml'}));const a=document.createElement('a');a.href=url;a.download=`${selected.packageId}-${selected.version}.xml`;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
 async function chooseRun(id){watch.current++;setWatching(false);setEvidence([]);const api=client.current,r=await api.run(api.project,id);const b=readBlueprint(r.blueprintJson);if(await blueprintHash(b)!==r.snapshotHash)throw new Error('서버 실행 snapshot hash 불일치');snapshot.current=b;history.current=[];setRemote(r);setWatching(true);}
 useEffect(()=>{
  if(!watching||!remote)return;const epoch=watch.current,api=client.current;let stopped=false,inflight=false;const id=remote.id,identity=remote;
  const poll=async()=>{if(stopped||inflight)return;inflight=true;try{
   const page=await api.events(api.project,id,{afterSequence:history.current.length,limit:100});
   if(stopped||epoch!==watch.current)return;
   if(page.runId!==id||page.engineRunId!==identity.engineRunId||page.attempt!==identity.attempt||page.snapshotHash!==identity.snapshotHash)throw new Error('서버 진행 identity 불일치');
   const next=[...history.current,...page.eventsJson];const events=await readEvents(next.join('\n')+'\n',snapshot.current,{live:true});
   if(page.nextSequence!==events.length)throw new Error('서버 진행 cursor 불일치');
   if(stopped||epoch!==watch.current)return;history.current=next;callback.current(snapshot.current,events);const current=await api.run(api.project,id);
   if(stopped||epoch!==watch.current)return;setRemote(current);
   if(current.terminal&&!page.hasMore&&current.lastSequence===events.length&&current.evidenceStatus==='verified')setWatching(false);
  }catch(e){if(!stopped){setError(`${e.message} · 진행 재연결로 이어받을 수 있습니다.`);setWatching(false);}}finally{inflight=false;}};
  poll();const timer=setInterval(poll,1000);return()=>{stopped=true;clearInterval(timer);};
 },[watching,remote?.id]);
 async function loadEvidence(){const api=client.current,epoch=watch.current,images=[];let total=0;for(const a of remote.artifacts){if(!a.uploaded)continue;const item=await api.downloadArtifact(api.project,remote.id,a.artifactId);const bytes=Uint8Array.from(atob(item.base64),c=>c.charCodeAt(0));total+=bytes.length;if(bytes.length!==a.size||bytes.length>10*1024*1024||total>64*1024*1024||await hash(bytes)!==a.sha256)throw new Error('증거 bytes/size/hash 불일치');if(a.mimeType==='image/png')images.push({name:a.name,src:`data:image/png;base64,${item.base64}`});}if(epoch===watch.current)setEvidence(images);}
 return <section aria-label="공용 시나리오 서버"><h2>공용 XML Registry · 진행 공유</h2>
  <label>공유 서버 주소<input aria-label="공유 서버 주소" value={origin} onChange={e=>setOrigin(e.target.value)}/></label>
  <button disabled={busy} onClick={()=>action(async()=>{const api=new OrganizationClient(origin);try{window.location.assign(api.loginUrl('web'));}finally{api.close();}})}>조직 로그인</button>
  <button disabled={busy} onClick={()=>action(organizationSession)}>조직 세션 확인</button>
  {organization&&<><span>조직 사용자 {organization.session.userId}</span><button disabled={busy} onClick={()=>action(logout)}>조직 로그아웃</button><button disabled={busy} onClick={()=>{setOrganization(null);setMessage('로컬 테스트 token 연결을 선택했습니다.');}}>로컬 테스트 연결 선택</button></>}
  <label>테스트 사용자 token<input aria-label="공유 사용자 token" type="password" autoComplete="off" value={token} onChange={e=>setToken(e.target.value)}/></label>
  <label>프로젝트 ID<input aria-label="공유 프로젝트" value={project} onChange={e=>setProject(e.target.value)}/></label><button disabled={busy} onClick={()=>action(connect)}>공유 연결</button>
  <p role="status">{message}</p>{error&&<p role="alert">{error}</p>}
  {connected&&<>
   <h3>현재 편집한 Blueprint 게시</h3><label>패키지 ID<input value={packageId} onChange={e=>setPackageId(e.target.value)}/></label><label>제목<input value={title} onChange={e=>setTitle(e.target.value)}/></label><label>발행 버전<input value={version} onChange={e=>setVersion(e.target.value)}/></label><label>고정 dependency 목록 JSON<textarea value={dependencies} onChange={e=>setDependencies(e.target.value)}/></label>
   <button disabled={busy} onClick={()=>action(async()=>{await client.current.createDraft(client.current.project,{packageId,title,xml:sourceXml(),dependencies:JSON.parse(dependencies)});await list('drafts');setMessage('초안을 저장했습니다. 다른 검수자의 승인 뒤 발행할 수 있습니다.');})}>현재 XML 초안 저장</button>
   <ul>{drafts.map(d=><li key={d.id}>{d.packageId} · {d.title} · {d.status}<button disabled={busy} onClick={()=>action(async()=>{await client.current.reviewDraft(client.current.project,d.id);await list('drafts');})}>검수 승인</button><button disabled={busy} onClick={()=>action(async()=>{const k=`${d.id}:${version}`;if(!publishKeys.current.has(k))publishKeys.current.set(k,crypto.randomUUID());await client.current.publishDraft(client.current.project,d.id,version,publishKeys.current.get(k));await Promise.all([list('drafts'),list('versions')]);})}>버전 발행</button></li>)}</ul>
   <h3>공용 고정 버전</h3><ul>{versions.map(v=><li key={v.id}><button disabled={busy} onClick={()=>action(()=>chooseVersion(v.id))}>{v.packageId} · {v.version}</button></li>)}</ul>
   {selected&&<><pre>{diff}</pre><pre>{selected.xml}</pre><button onClick={download}>고정 XML 다운로드</button><button disabled={busy} onClick={()=>action(async()=>{await client.current.pin(client.current.project,selected.id,selected.sha256);setMessage('이 버전을 고정했습니다. Desktop에서 수신 후 명시 실행하세요.');})}>변경 확인 후 버전 고정</button></>}
   <h3>Desktop 실행 진행</h3><button disabled={busy} onClick={()=>action(()=>list('runs'))}>실행 목록 새로 고침</button><ul>{runs.map(r=><li key={r.id}><button disabled={busy} onClick={()=>action(()=>chooseRun(r.id))}>{r.engineRunId} · {r.reportedOutcome||'진행 중'}</button></li>)}</ul>
   {remote&&<><p data-testid="shared-run-status">외부 outcome: {remote.reportedOutcome||'미종료'} · evidence: {remote.evidenceStatus} · 업무: {remote.workStatus}</p><button onClick={()=>setWatching(v=>!v)}>{watching?'진행 수신 중지':'진행 재연결'}</button><button disabled={busy} onClick={()=>action(loadEvidence)}>검증된 증거 이미지 보기</button>{evidence.map(e=><figure key={e.name}><figcaption>{e.name}</figcaption><img style={{maxWidth:'100%'}} src={e.src} alt={e.name}/></figure>)}<RunWork key={remote.id} api={client.current} runId={remote.id} onUpdated={()=>action(async()=>setRemote(await client.current.run(client.current.project,remote.id)))}/></>}
   <h3>감사 기록</h3><button disabled={busy} onClick={()=>action(()=>list('audit'))}>감사 새로 고침</button><pre>{JSON.stringify(audit,null,2)}</pre>
   <SuiteExecutions key={connection.current} api={client.current} onRun={id=>action(()=>chooseRun(id))}/>
   {Object.entries(cursors).filter(([,c])=>c).map(([kind])=><button key={kind} disabled={busy} onClick={()=>action(()=>list(kind,true))}>{kind} 더 보기</button>)}
  </>}
  <p>수신·검수·발행은 테스트를 실행하지 않습니다. evidence verified는 자료 정합성 확인이며 외부 실행 신뢰나 실기기 검증 보증이 아닙니다. Registry는 단일 Blueprint XML 공유이며 Suite 게시·예약은 별도 Agent 기능입니다.</p>
 </section>;
}
