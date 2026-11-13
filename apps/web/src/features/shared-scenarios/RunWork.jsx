import React,{useEffect,useState} from 'react';

export function RunWork({api,runId,onUpdated}){
 const [work,setWork]=useState(null),[status,setStatus]=useState('todo'),[assignee,setAssignee]=useState(''),[baseline,setBaseline]=useState(''),[comparison,setComparison]=useState(null),[notifications,setNotifications]=useState([]),[error,setError]=useState(''),[busy,setBusy]=useState(false);
 useEffect(()=>{let active=true;setWork(null);setComparison(null);setNotifications([]);setError('');api.work(api.project,runId).then(value=>{if(active){setWork(value);setStatus(value.status);setAssignee(value.assigneeId??'');}}).catch(e=>{if(active)setError(e.message);});return()=>{active=false;};},[api,runId]);
 async function action(fn){if(busy)return;setBusy(true);setError('');try{await fn();}catch(e){setError(`${e.message} · 충돌 시 업무 새로 고침 후 변경을 다시 확인하세요.`);}finally{setBusy(false);}}
 async function refresh(){const value=await api.work(api.project,runId);setWork(value);setStatus(value.status);setAssignee(value.assigneeId??'');onUpdated?.();}
 return <section aria-label="실행 업무와 비교"><h4>업무 처리 · outcome과 별도</h4>
  {work&&<><p>업무 revision: {work.revision}</p><label>업무 상태<select aria-label="업무 상태" value={status} onChange={e=>setStatus(e.target.value)}><option value="todo">todo</option><option value="in_progress">in_progress</option><option value="done">done</option></select></label><label>담당 사용자 ID<input aria-label="담당 사용자 ID" value={assignee} onChange={e=>setAssignee(e.target.value)}/></label><button disabled={busy} onClick={()=>action(async()=>{await api.updateWork(api.project,runId,{status,assigneeId:assignee||null,revision:work.revision});await refresh();})}>업무 변경 저장</button></>}
  <button disabled={busy} onClick={()=>action(refresh)}>업무 새로 고침</button>
  <h4>이전 비교 가능한 실행</h4><button disabled={busy} onClick={()=>action(async()=>setComparison(await api.compare(api.project,runId)))}>결과 비교</button>
  <label>기준 실행 ID<input aria-label="기준 실행 ID" value={baseline} onChange={e=>setBaseline(e.target.value)}/></label><button disabled={busy||!baseline} onClick={()=>action(async()=>setComparison(await api.selectBaseline(api.project,runId,baseline)))}>기준 실행 명시 선택</button>
  {comparison&&<pre data-testid="run-comparison">{JSON.stringify(comparison,null,2)}</pre>}<p>검증된 profile/reference와 동일 snapshot 범위만 비교합니다. 이미지 기준 파일과 원래 outcome은 바뀌지 않습니다.</p>
  <h4>알림 전달 상태</h4><button disabled={busy} onClick={()=>action(async()=>{await api.enqueueNotification(api.project,runId);setNotifications((await api.notifications(api.project,runId)).items);})}>로컬 검증 알림 요청 (관리 권한)</button><button disabled={busy} onClick={()=>action(async()=>setNotifications((await api.notifications(api.project,runId)).items))}>알림 상태 조회</button>
  <pre>{JSON.stringify(notifications,null,2)}</pre><p>현재 전송 대상은 운영자가 명시한 local-test HTTP fixture입니다. Slack 로그인과 알림 권한은 별개이며 실제 외부 Slack 발송은 하지 않습니다.</p>
  {error&&<p role="alert">{error}</p>}
 </section>;
}
