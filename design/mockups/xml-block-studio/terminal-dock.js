'use strict';
// A local interaction model only. No PTY, network, filesystem or Engine calls.
(() => {
  const profiles = {
    codex: {name:'Codex',ready:true,ai:true},
    claude: {name:'Claude Code',ready:false,ai:true},
    powershell: {name:'PowerShell',ready:true,ai:false},
    cmd: {name:'명령 프롬프트',ready:true,ai:false},
  };
  const sessions=[], documents=new Map(), panes=new Map(), documentViews=new Map();
  let previousDocument=null;
  let sequence=0, active=null, split=null, collapsed=true, expanded=false, height=280, tab='terminal', trigger=null, homeReturn=null;
  const pin='alpha.8 / 0.3.0-draft.2 / 고정 schema 예시';
  const dock=document.createElement('section');dock.id='terminal-dock';dock.className='collapsed';
  dock.innerHTML=`<div class="td-resize" role="separator" tabindex="0" aria-label="터미널 높이" aria-orientation="horizontal" aria-valuemin="160" aria-valuemax="500" aria-valuenow="280"></div>
    <div class="td-toolbar" role="tablist" aria-label="하단 패널"><button data-td="tab" data-tab="terminal" role="tab" aria-selected="true">터미널</button><button data-td="tab" data-tab="output" role="tab" aria-selected="false">출력</button><button data-td="tab" data-tab="problems" role="tab" aria-selected="false">문제</button><button data-td="tab" data-tab="results" role="tab" aria-selected="false">결과</button><div class="td-tools"><button data-td="new" aria-label="새 터미널 세션" aria-expanded="false">＋ 새 세션</button><button data-td="split" aria-pressed="false">좌우 분할</button><button data-td="expand" aria-label="터미널 확대">확대</button><button data-td="collapse" aria-label="터미널 접기">접기</button></div></div>
    <div class="td-content"><div class="td-message" role="status"></div><div class="td-sessionbar"><div class="td-sessions" role="tablist" aria-label="터미널 세션"></div><span class="td-other"></span><button data-td="session-menu" aria-label="선택 세션 메뉴" aria-expanded="false">세션 ⋯</button></div><div class="td-panes"></div><div class="td-context"></div></div>`;
  const oldOutput=document.querySelector('.output');oldOutput.before(dock);oldOutput.remove();
  const pop=document.createElement('section');pop.className='td-popover';pop.hidden=true;pop.setAttribute('aria-label','터미널 메뉴');document.body.append(pop);
  const homeStrip=document.createElement('div');homeStrip.className='td-home-sessions';homeStrip.hidden=true;document.querySelector('#project-home').after(homeStrip);
  const content=dock.querySelector('.td-content'),paneArea=dock.querySelector('.td-panes'),sessionBar=dock.querySelector('.td-sessionbar'),context=dock.querySelector('.td-context');
  const notice=dock.querySelector('.td-message');oldOutput.hidden=true;content.append(oldOutput);
  const identity=()=>opened?`${opened.p}/${opened.q}`:null;
  const current=()=>sessions.find(s=>s.id===active);
  const docState=()=>{
    const key=identity();if(!key)return null;
    // Positions and selection are presentation, not execution identity.
    const signature=JSON.stringify({directXml,assets:assets.map(a=>[a.id,a.xml]),nodes:nodes.map(n=>[n.id,n.asset]),edges});
    let d=documents.get(key);if(!d){d={revision:0,signature,pin,run:false,writerEpoch:0};documents.set(key,d);}else if(d.signature!==signature){d.signature=signature;d.revision++;}
    return d;
  };
  const ownSessions=()=>sessions.filter(s=>s.document===identity());
  const alive=s=>s&&s.process!=='exited';
  const writerFor=key=>sessions.find(s=>s.document===key&&s.writer&&alive(s));
  const processName=s=>({running:'실행 중',stopping:'정리 중',unknown:'정리 미확인',exited:'종료됨'}[s.process]||'준비 중');
  function message(text){notice.textContent=text;}
  function limits(){const main=document.querySelector('#studio main');const available=main.getBoundingClientRect().height+dock.getBoundingClientRect().height;return {min:Math.min(160,Math.max(100,available-220)),max:Math.max(160,available-220),large:Math.max(160,available-75)};}
  function layout(){
    const range=limits(),actual=expanded?range.large:Math.min(range.max,Math.max(range.min,height));
    dock.style.setProperty('--dock-height',`${actual}px`);dock.classList.toggle('collapsed',collapsed);dock.classList.toggle('expanded',expanded);
    const resize=dock.querySelector('.td-resize');resize.setAttribute('aria-valuenow',String(Math.round(actual)));resize.setAttribute('aria-valuemin',String(range.min));resize.setAttribute('aria-valuemax',String(expanded?range.large:range.max));
    dock.querySelector('[data-td=expand]').textContent=expanded?'복원':'확대';dock.querySelector('[data-td=expand]').setAttribute('aria-label',expanded?'터미널 복원':'터미널 확대');
    dock.querySelector('[data-td=collapse]').textContent=collapsed?'열기':'접기';dock.querySelector('[data-td=collapse]').setAttribute('aria-label',collapsed?'터미널 열기':'터미널 접기');
    dock.querySelector('[data-td=split]').setAttribute('aria-pressed',String(!!split));
    updatePanes();
  }
  function capturePane(s){const el=panes.get(s.id);if(!el?.isConnected||el.parentElement!==paneArea||tab!=='terminal'||collapsed)return;s.scroll=el.querySelector('.td-output').scrollTop;s.input=el.querySelector('input').value;}
  function pane(s){
    if(panes.has(s.id))return panes.get(s.id);
    const el=document.createElement('section');el.className='td-pane';el.dataset.session=s.id;
    el.innerHTML='<div class="td-pane-heading"><strong></strong><span class="td-process"></span></div><pre class="td-output" tabindex="0" aria-label="터미널 출력"></pre><form class="td-inputline"><span>❯</span><input aria-label="터미널 입력" autocomplete="off" spellcheck="false" placeholder="예시 입력 · 실제 명령 실행 안 함"><button type="submit">입력</button></form>';
    el.querySelector('input').addEventListener('input',e=>s.input=e.target.value);
    el.querySelector('form').addEventListener('submit',e=>{e.preventDefault();const input=el.querySelector('input');if(!input.value.trim()||s.process!=='running')return;s.output+=`\n❯ ${input.value}\n입력 기록만 추가했습니다. 실제 명령은 실행하지 않습니다.`;input.value='';s.input='';updatePane(s);});
    el.querySelector('.td-output').addEventListener('scroll',e=>{if(el.isConnected&&el.parentElement===paneArea&&tab==='terminal'&&!collapsed)s.scroll=e.target.scrollTop;});
    panes.set(s.id,el);return el;
  }
  function updatePane(s){const el=pane(s);el.querySelector('strong').textContent=`${s.name} · ${profiles[s.provider].name}`;el.querySelector('.td-process').textContent=processName(s);const out=el.querySelector('.td-output');if(out.textContent!==s.output){const top=out.scrollTop;out.textContent=s.output;out.scrollTop=top;}el.querySelector('input').disabled=s.process!=='running';el.querySelector('form button').disabled=s.process!=='running';}
  function updatePanes(){
    if(tab!=='terminal')return;
    const selected=current(),splitSession=sessions.find(s=>s.id===split&&s.document===identity()&&s.id!==active),wide=innerWidth>=1200;
    const wanted=selected&&selected.document===identity()?[selected,...(splitSession&&wide?[splitSession]:[])]:[];
    for(const [id,el]of panes){if(el.parentElement===paneArea&&!wanted.some(s=>s.id===id)){capturePane(sessions.find(s=>s.id===id));el.remove();}}
    paneArea.querySelector('.td-empty')?.remove();
    for(const s of wanted){const el=pane(s);if(el.parentElement!==paneArea){paneArea.append(el);el.querySelector('input').value=s.input;el.querySelector('.td-output').scrollTop=s.scroll||0;}updatePane(s);}
    if(!wanted.length)paneArea.innerHTML='<div class="td-empty">이 QA의 터미널이 없습니다. 작성 도구 또는 일반 셸을 선택하세요.<br><button data-td="new">새 세션</button></div>';
    const owner=writerFor(identity());context.innerHTML=selected?`<span title="${esc(selected.project+' / '+selected.qa)}">${esc(selected.project)} / ${esc(selected.qa)}</span><span class="td-path" title="${esc(selected.cwd)}">시작 경로: ${esc(selected.cwd)}</span><span>${selected.writer?'자동 반영 작성자':'사본 / 검토'}</span>${splitSession&&!wide?'<span class="td-fallback">좁은 창 · 세션 탭으로 전환</span>':''}`:`<span>자동 반영 작성자: ${owner?esc(owner.name):'없음'}</span>`;
  }
  function renderSessions(){
    const own=ownSessions();if(!own.some(s=>s.id===active))active=own[0]?.id||null;
    dock.querySelector('.td-sessions').innerHTML=own.map(s=>`<button class="td-session" role="tab" aria-selected="${s.id===active}" data-td="select" data-id="${s.id}" title="${esc(s.name+' / '+s.qa)}">${esc(s.name)}<small>${s.writer?'작성자':processName(s)}</small></button>`).join('');
    const other=sessions.filter(s=>s.document!==identity()&&alive(s));dock.querySelector('.td-other').textContent=other.length?`다른 문서 ${other.length}개 세션`:'';
    dock.querySelector('[data-td=session-menu]').disabled=!current();dock.querySelector('[data-td=split]').disabled=own.length<2;
    updatePanes();
  }
  function showTab(next){
    for(const s of sessions)capturePane(s);tab=next;collapsed=false;dock.classList.remove('collapsed');
    dock.querySelectorAll('[data-td=tab]').forEach(b=>b.setAttribute('aria-selected',String(b.dataset.tab===tab)));
    paneArea.replaceChildren();paneArea.hidden=tab==='output';oldOutput.hidden=tab!=='output';sessionBar.hidden=tab!=='terminal';context.hidden=tab!=='terminal';
    if(tab==='terminal')renderSessions();
    if(tab==='problems'){paneArea.innerHTML='<div class="td-simple"><h3>문서 검증</h3><p>실제 Engine 검증을 실행하지 않았습니다. 세션 메뉴의 작성 흐름 예시에서 오류와 충돌 상태를 검토하세요.</p></div>';}
    if(tab==='results')paneArea.innerHTML='<div class="td-simple"><h3>아직 실행 결과가 없습니다</h3><p>터미널 준비와 문서 반영은 QA 실행이 아닙니다. 실제 검증·명시 실행·결과는 Windows 앱에서 제공합니다.</p></div>';
    layout();
  }
  function closeMenu(restore=true){pop.hidden=true;dock.querySelectorAll('[aria-expanded]').forEach(b=>b.setAttribute('aria-expanded','false'));if(restore&&trigger?.isConnected)trigger.focus();}
  function menu(html,source){closeMenu(false);trigger=source||document.activeElement;trigger?.setAttribute?.('aria-expanded','true');pop.innerHTML=html+'<button data-td="close-menu">닫기</button>';pop.hidden=false;const r=dock.getBoundingClientRect();pop.style.bottom=`${Math.max(12,innerHeight-r.top+8)}px`;if(pop.getBoundingClientRect().top<8)pop.style.bottom='40px';pop.querySelector('input,button')?.focus();}
  function newMenu(source){menu('<h3>새 터미널 세션</h3>'+Object.entries(profiles).map(([id,p])=>`<button data-td="create" data-provider="${id}">${p.name}<small>${p.ready?'준비 완료 예시': '설정 필요 예시 · CLI와 로그인 확인'}</small></button>`).join(''),source);}
  function create(provider){
    if(!opened)return;const p=profiles[provider];if(!p.ready){menu(`<h3>${p.name} 설정 필요</h3><p>실제 설치와 로그인은 확인하지 않았습니다. 아래 버튼은 준비된 화면 예시만 엽니다.</p><button data-td="ready" data-provider="${provider}">준비 완료 예시로 보기</button>`,trigger);return;}
    const d=docState(),project=projectBy(opened.p),qa=qaBy(opened.p,opened.q),id=`terminal-${++sequence}`;
    const s={id,provider,name:`${p.name} ${sessions.filter(s=>s.provider===provider).length+1}`,document:identity(),project:project.name,qa:qa.name,projectId:opened.p,qaId:opened.q,cwd:`작업 사본/${opened.p}/${opened.q}/${id}`,baseRevision:d.revision,baseHash:d.signature,pin:d.pin,process:'running',writer:false,input:'',scroll:0,output:`${p.name} 세션 준비 예시\n작성 대상: ${qa.name}\n시작 경로: 작업 사본/${opened.p}/${opened.q}/${id}\n${p.ai?'공개 작성 계약과 문맥 준비 예시':'일반 셸 · AI 스킬을 적용하지 않습니다.'}\n실제 프로세스는 실행하지 않습니다.`};
    sessions.push(s);active=id;closeMenu(false);showTab('terminal');message('새 세션을 열었습니다. 문서 반영은 세션 메뉴에서 작성자로 지정하세요.');pane(s).querySelector('input').focus();
  }
  function sessionMenu(source){const s=current();if(!s)return;menu(`<h3>${esc(s.name)}</h3><button data-td="rename">이름 변경</button><button data-td="details">소속 · 시작 경로 · 준비 상태</button><button data-td="writer">${s.writer?'자동 반영 해제':'자동 반영 작성자로 지정'}</button><button data-td="candidate-menu">작성 흐름 예시</button>${s.process==='running'?'<button data-td="terminate">세션 종료…</button>':''}${['stopping','unknown'].includes(s.process)?'<button data-td="cleanup-ok">정리 완료 예시</button><button data-td="cleanup-unknown">정리 미확인 예시</button>':''}`,source);}
  function setWriter(){const s=current(),old=writerFor(identity());if(!s||s.process!=='running'){message('실행 중인 예시 세션만 작성자로 지정할 수 있습니다.');closeMenu();return;}if(old&&old!==s){if(old.process==='unknown'||old.process==='stopping'){message('이전 작성자의 정리가 확인되지 않았습니다. 먼저 세션 메뉴에서 정리를 확인하세요.');closeMenu();return;}menu(`<h3>자동 반영 작성자 변경</h3><p>${esc(old.name)}에서 ${esc(s.name)}으로 변경합니다. 이전 후보는 자동 반영할 수 없습니다.</p><button data-td="transfer">작성자 변경</button>`,trigger);return;}s.writer=!s.writer;refreshBase(s);closeMenu();renderSessions();message(s.writer?'현재 QA의 자동 반영 작성자로 지정했습니다.':'자동 반영을 해제했습니다.');}
  function refreshBase(s){const d=docState();d.writerEpoch++;s.baseRevision=d.revision;s.baseHash=d.signature;s.pin=d.pin;}
  function candidateMenu(){const s=current();if(!s)return;menu(`<h3>작성 흐름 예시</h3><p>고정된 예시 검증 결과를 전달합니다. 입력한 임의 XML이 Engine 검증을 통과했다고 판단하지 않습니다.</p><button data-td="prepare" data-kind="valid">유효한 예시 후보 준비</button><button data-td="prepare" data-kind="invalid">검증 오류 후보 준비</button>${s.candidate?'<button data-td="complete">대기 후보의 검증 결과 전달</button>':''}<button data-td="run-guard">${docState().run?'실행 중 보호 해제 예시':'실행 중 보호 켜기 예시'}</button><button data-td="pin-change">Engine pin 변경 예시</button>`,trigger);}
  function prepare(kind){const s=current();if(!s||s.process!=='running')return;const d=docState();s.candidate={kind,document:s.document,session:s.id,cwd:s.cwd,revision:d.revision,hash:d.signature,pin:d.pin,writerEpoch:d.writerEpoch,source:window.DEMO_XML+'\n<!-- 터미널의 검증된 예시 후보 -->'};closeMenu();message('후보가 검증 대기 중입니다. 세션 메뉴에서 검증 결과를 전달할 수 있습니다.');s.output+='\n후보 준비 → Engine 검증 대기 (예시)';updatePane(s);}
  function complete(){
    const s=current(),c=s?.candidate;if(!c)return;const d=docState();let reason='';
    if(c.kind==='invalid')reason='검증 오류: 후보를 반영하지 않았습니다. 마지막 정상 문서를 유지합니다.';
    else if(c.document!==identity()||c.session!==s.id||c.cwd!==s.cwd)reason='다른 문서 또는 세션의 후보입니다.';
    else if(c.writerEpoch!==d.writerEpoch)reason='작성자가 변경되어 이전 후보는 다시 검토해야 합니다. 현재 기준으로 새 후보를 준비하세요.';
    else if(c.revision!==d.revision||c.hash!==d.signature)reason='문서 충돌: 후보 작성 후 GUI가 변경되었습니다. 사본에서 검토하세요.';
    else if(c.pin!==d.pin)reason='Engine pin이 변경되었습니다. 새 계약으로 재검증해야 합니다.';
    else if(!s.writer||writerFor(identity())!==s||s.process!=='running')reason='검증된 사본입니다. 현재 자동 반영 작성자가 아니므로 문서를 유지합니다.';
    else if(d.run)reason='QA 실행 중: 현재 문서를 유지합니다. 실행 종료 후 다시 검토하세요.';
    if(reason){s.output+='\n'+reason;message(reason);s.candidateState='review';}
    else{directXml=c.source;dirty=true;if(mode==='direct'){const editor=document.querySelector('#source textarea'),start=editor.selectionStart,end=editor.selectionEnd,scroll=editor.scrollTop;editor.value=directXml;editor.setSelectionRange(Math.min(start,directXml.length),Math.min(end,directXml.length));editor.scrollTop=scroll;}docState();s.candidateState='applied';s.output+='\n예시 Engine 검증 통과 → 직접 XML draft 반영. 저장·QA 실행은 하지 않았습니다.';message('검증된 예시를 직접 XML 초안에 반영했습니다. 블록 조합 원본은 유지합니다. 저장과 실행은 별도입니다.');document.querySelector('#dirty').textContent='*';document.querySelector('#status').textContent='터미널 반영 · 저장하지 않은 변경';}
    s.candidate=null;updatePane(s);closeMenu();
  }
  function details(){const s=current();menu(`<h3>세션 정보</h3><dl><dt>프로젝트 / QA</dt><dd>${esc(s.project)} / ${esc(s.qa)}</dd><dt>시작 경로</dt><dd>${esc(s.cwd)}</dd><dt>현재 셸 경로</dt><dd>관측하지 않음 · cd를 강제하거나 추적하지 않습니다.</dd><dt>작성 기준</dt><dd>revision ${s.baseRevision} / ${esc(s.pin)}</dd><dt>준비</dt><dd>${profiles[s.provider].ai?'CLI·로그인·작성 계약 준비 예시':'일반 셸 준비 예시 · AI 스킬 없음'}</dd></dl><p>현재 제품은 단일 Codex 기반입니다. 이 다중 세션과 Claude 화면은 설계 예시이며 역할명은 OS 권한 격리를 보증하지 않습니다.</p>`,trigger);}
  function documentChanged(){if(previousDocument)documentViews.set(previousDocument,{active,split});previousDocument=identity();const view=documentViews.get(previousDocument);active=view?.active||null;split=view?.split||null;docState();message('');renderSessions();layout();homeStrip.hidden=true;}
  function homeChanged(){homeReturn=sessions.find(s=>alive(s));homeStrip.hidden=!homeReturn;homeStrip.innerHTML=homeReturn?`<span>작업실에 ${sessions.filter(alive).length}개 예시 세션이 남아 있습니다. 홈 이동은 종료가 아닙니다.</span><button data-td="return">${esc(homeReturn.qa)} 돌아가기</button>`:'';closeMenu(false);}
  function select(id){for(const s of sessions)capturePane(s);if(id===split)split=active;active=id;showTab('terminal');renderSessions();dock.querySelector(`[data-td=select][data-id="${id}"]`)?.focus();}
  document.addEventListener('click',e=>{
    const b=e.target.closest('[data-td]');if(!b)return;const a=b.dataset.td,s=current();
    if(a==='tab')showTab(b.dataset.tab);if(a==='new')newMenu(b);if(a==='create')create(b.dataset.provider);if(a==='ready'){profiles[b.dataset.provider].ready=true;create(b.dataset.provider);}if(a==='select')select(b.dataset.id);
    if(a==='collapse'){collapsed=!collapsed;layout();}if(a==='expand'){collapsed=false;expanded=!expanded;layout();}
    if(a==='split'){split=split?null:ownSessions().find(v=>v.id!==active)?.id;showTab('terminal');layout();}
    if(a==='session-menu')sessionMenu(b);if(a==='close-menu')closeMenu();if(a==='details')details();if(a==='writer')setWriter();
    if(a==='transfer'){const old=writerFor(identity());if(old)old.writer=false;s.writer=true;refreshBase(s);closeMenu();renderSessions();message('자동 반영 작성자를 변경했습니다. 이전 세션 후보는 사본으로 남습니다.');}
    if(a==='rename'){menu(`<h3>세션 이름</h3><label>역할 또는 작업 이름<input id="td-rename" maxlength="48" value="${esc(s.name)}"></label><button data-td="rename-save">이름 저장</button>`,trigger);pop.querySelector('input').select();}
    if(a==='rename-save'){const name=pop.querySelector('input').value.trim();if(name){s.name=name;closeMenu();renderSessions();}}
    if(a==='candidate-menu')candidateMenu();if(a==='prepare')prepare(b.dataset.kind);if(a==='complete')complete();
    if(a==='run-guard'){docState().run=!docState().run;message(docState().run?'실행 중 보호 예시를 켰습니다. 실제 QA는 실행하지 않습니다.':'실행 중 보호 예시를 해제했습니다.');closeMenu();}
    if(a==='pin-change'){docState().pin+=' 변경';message('계약 pin 변경 예시: 기존 후보는 다시 검증해야 합니다.');closeMenu();}
    if(a==='terminate')menu(`<h3>${esc(s.name)} 종료</h3><p>접기와 달리 선택한 예시 세션을 종료합니다. 다른 세션과 문서는 유지됩니다.</p><button data-td="terminate-confirm">종료 요청</button>`,trigger);
    if(a==='terminate-confirm'){s.process='stopping';s.output+='\n종료 요청 → 정리 응답 대기';closeMenu();renderSessions();message('정리 중입니다. 세션 메뉴에서 정리 완료/미확인 상태를 검토할 수 있습니다.');}
    if(a==='cleanup-ok'){s.process='exited';s.writer=false;s.candidate=null;s.output+='\n정리 완료 · 종료됨';closeMenu();renderSessions();message('선택 세션이 종료되었습니다. 입력과 출력 기록은 남습니다.');}
    if(a==='cleanup-unknown'){s.process='unknown';closeMenu();renderSessions();message('정리 미확인: 이 QA의 새 작성자 지정은 정리 확인 전 차단됩니다.');}
    if(a==='return'&&homeReturn)openQa(homeReturn.projectId,homeReturn.qaId);
  });
  document.addEventListener('keydown',e=>{if(e.isComposing)return;if(e.key==='Escape'&&!pop.hidden){e.preventDefault();closeMenu();}if(e.key==='Enter'&&e.target.id==='td-rename'){e.preventDefault();pop.querySelector('[data-td=rename-save]').click();}});
  const resize=dock.querySelector('.td-resize');let resizing=null;
  resize.addEventListener('pointerdown',e=>{if(e.button!==0)return;e.preventDefault();expanded=false;collapsed=false;resizing={y:e.clientY,height:dock.getBoundingClientRect().height};dock.classList.add('dragging');resize.setPointerCapture(e.pointerId);resize.focus();});
  resize.addEventListener('pointermove',e=>{if(!resizing)return;const range=limits();height=Math.max(range.min,Math.min(range.max,resizing.height+resizing.y-e.clientY));layout();});
  const stopResize=()=>{resizing=null;dock.classList.remove('dragging');};resize.addEventListener('pointerup',stopResize);resize.addEventListener('pointercancel',stopResize);
  resize.addEventListener('keydown',e=>{if(!['ArrowUp','ArrowDown','Home','End'].includes(e.key))return;e.preventDefault();expanded=false;collapsed=false;const range=limits();height=e.key==='Home'?range.min:e.key==='End'?range.max:Math.max(range.min,Math.min(range.max,dock.getBoundingClientRect().height+(e.key==='ArrowUp'?20:-20)));layout();});
  window.addEventListener('resize',layout);
  window.TerminalDock={open:()=>showTab('terminal'),documentChanged,homeChanged,sessions,documents,profiles,create,select,prepare,complete,inspect:()=>({active,split,collapsed,expanded,height,tab,identity:identity()}),review(state){showTab('terminal');if(!ownSessions().length){create('codex');current().writer=true;current().name='XML 작성';create('powershell');current().name='실행 환경 확인';select(ownSessions()[0].id);split=ownSessions()[1].id;}if(state==='setup')newMenu();if(state==='validation_error'){prepare('invalid');complete();}if(state==='conflict'){prepare('valid');directXml+='\n<!-- GUI 편집 예시 -->';docState();complete();}if(state==='cleanup_unknown'){current().process='unknown';message('작성자 정리 미확인 · 새 작성자 전환 차단');}renderSessions();layout();}};
  layout();
})();
