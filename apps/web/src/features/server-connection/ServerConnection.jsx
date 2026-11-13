import {useEffect,useRef,useState} from 'react';
import {HealthClient,ApiFailure,TransportFailure} from '../../shared/api/index.js';
export function ServerConnection(){
 const [origin,setOrigin]=useState(import.meta.env.VITE_API_BASE_URL||'http://127.0.0.1:4319'),[message,setMessage]=useState('서버 연결은 로컬 파일 QA의 필수조건이 아닙니다.'),[busy,setBusy]=useState(false);
 const active=useRef(null),generation=useRef(0);
 useEffect(()=>()=>{generation.current++;active.current?.abort();},[]);
 async function connect(){
  const id=++generation.current;active.current?.abort();active.current=new AbortController();setBusy(true);setMessage('연결 확인 중');
  try{const health=await new HealthClient(origin).getHealth({client:'web'},{signal:active.current.signal});if(id===generation.current)setMessage(`${health.service} · ${health.status} · ${health.client} · API ${health.apiVersion}`);}
  catch(error){if(id===generation.current)setMessage(error instanceof ApiFailure?`API ${error.status}: ${error.body.code} (${error.body.requestId})`:error instanceof TransportFailure?`연결 오류: ${error.reason}`:'주소 또는 API 계약 오류');}
  finally{if(id===generation.current)setBusy(false);}
 }
 return <section><h2>공유 서버 연결</h2><label>API origin<input aria-label="API origin" value={origin} onChange={e=>{generation.current++;active.current?.abort();setBusy(false);setOrigin(e.target.value);setMessage('새 주소의 연결을 확인하세요.');}}/></label><button disabled={busy} onClick={connect}>서버 연결 확인</button><p data-testid="server-status">{message}</p><p>현재 health 연결 확인입니다. 조직 로그인·공용 Registry·진행 자동 수신은 별도 기능입니다.</p></section>;
}
