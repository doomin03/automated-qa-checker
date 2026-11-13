'use strict';
if (planningReview) {
  const params = new URLSearchParams(location.search);
  const screen = params.get('screen') || 'D01', sample = params.get('state') || 'normal';
  if(params.get('version')) {
    published[0] = {id:'planning-version',name:params.get('package')||'login-smoke',title:params.get('title')||'로그인 기본 점검',version:params.get('version')};
  }
  document.body.dataset.reviewScreen = screen;
  document.querySelector('.review span:nth-of-type(2)').textContent = `${screen} · 격리된 검토 세션 · 실제 실행 없음`;
  const receivedSample = {id:'planning-received',name:'받은 로그인 QA',updated:'2026-11-11 12:20',upstream:{...published[0]},state:JSON.parse(JSON.stringify(templateState))};
  if (!homeData.projects[0].qas.some(q=>q.id===receivedSample.id)) homeData.projects[0].qas.push(receivedSample);
  if (screen==='D02') {homeProject=homeData.projects[0].id;homeSelected=homeData.projects[0].qas[0].id;renderHome();}
  if (screen==='D03') {homeSection='available';connected=sample!=='offline';remoteSelection=published[0].id;renderHome();}
  if (screen==='D04') {homeSection='received';homeSelected=receivedSample.id;renderHome();}
  if (['D05','D06','D07','D08'].includes(screen)) {
    openQa(homeData.projects[0].id,homeData.projects[0].qas[0].id);
    switchMode(screen==='D06'?'direct':'blocks');
    requestAnimationFrame(fit);
  }
  if (screen==='D08') window.TerminalDock.review(sample);
  if (screen==='D07') {
    const panel=document.createElement('section');panel.className='planning-panel';
    panel.style.cssText='position:absolute;inset:145px 12px 86px 55px;background:#292929;border:1px solid #777;padding:24px;overflow:auto;z-index:5;';
    {
      const content={normal:['실행 전','검증 후 실행할 수 있습니다. 아직 결과와 화면 증거가 없습니다.'],failed:['실패','greeting.xml · 예상 문구와 관측 문구가 다릅니다.'],passed:['통과','선택한 실행 snapshot의 모든 방문 단계가 통과한 예시입니다.'],cancel_requested:['취소 요청 중','종료 응답을 기다립니다. 아직 cancelled 결과가 아닙니다.'],cancelled:['취소됨','Engine 종료 응답을 받은 예시입니다. 수집된 화면 증거 없음.'],validation_error:['검증 오류','evidence.xml의 연결을 확인하세요. 실행이 시작되지 않았으며 결과가 없습니다.'],infra_error:['환경 오류','브라우저 시작 실패. 수집된 화면 증거 없음.'],running:['실행 중','선택한 실행 snapshot을 처리하는 예시입니다. 아직 결과가 없습니다.'],incompatible:['로컬 실행 통과 · 공유 호환성 불일치','로컬 alpha.8 결과는 passed로 보존합니다. 기본 alpha.6 서버는 runtime 불일치로 게시를 거부합니다. Engine blocked 또는 미실행으로 바꾸지 않습니다.']};
      const [title,body]=content[sample]||content.normal;
      panel.innerHTML=`<h2>${title}</h2><p>가입 및 로그인 흐름</p><p>${body}</p><p>화면 상태 예시 · 실제 Engine 호출/PNG 생성 없음</p>${sample==='failed'?'<button id="planning-cause">원인 블록 보기</button>':''}<details><summary>실행 진단 상세</summary><p>실행 snapshot과 현재 편집본을 분리합니다. sourceMap은 해당 run과 원본 asset hash에 묶습니다.</p><p>공유: 기본 서버 alpha.6과 Desktop alpha.8의 runtime 호환성 불일치. 로컬 판정은 그대로 보존합니다.</p></details>`;
    }
    document.querySelector('#studio').append(panel);
    panel.querySelector('#planning-cause')?.addEventListener('click',()=>{panel.remove();selected=2;render();fit();});
  }
  if(['empty','loading','error','permission'].includes(sample)&&['D01','D02','D03','D04'].includes(screen)){
    const text={empty:'목록에 항목이 없습니다. 새 문서 또는 다른 프로젝트를 선택하세요.',loading:'목록을 불러오는 예시 상태입니다.',error:'목록을 불러오지 못했습니다. 연결을 확인하고 다시 시도하세요.',permission:'이 프로젝트의 게시 항목을 받을 권한이 없습니다. 로컬 문서는 계속 사용할 수 있습니다.'};
    document.querySelector('.home-list').innerHTML=`<p class="home-empty">${text[sample]}</p>`;
  }
  const back=document.createElement('a');back.href=`../product-planning/index.html#spec/${screen}`;back.target='_top';back.textContent='화면설계';back.style.cssText='color:inherit;margin-left:12px';document.querySelector('.review').append(back);
  actions.planning=()=>{window.top.location.href=back.href;};
}
