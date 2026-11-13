'use strict';
const requirementMap=[
['실행 schema·이벤트·결과 계약 예시','CONTRACTS_AND_EXAMPLES.md',['E01','D07','W06'],'고정 공개 계약 소비 / 원본은 초안 예시','docs/architecture/engine-integration.md','현재 정본은 Engine 고정 release schema·CLI 계약. 원본 예시 필드를 별도 실행 schema로 발명하지 않음'],
['조직·프로젝트·공용 QA 수신','CHECKER_CODEX_PROMPT.md:11,61 / CODEX_MASTER_PROMPT.md:60-61',['W01','W02','W03','D01','D03','D04'],'구현·실제 로컬 서버/Windows 인수','docs/validation-project-home.md','실제 조직 Slack 계정 인수는 별도; 게시 QA와 개인 배정 inbox는 다름'],
['TC 번호·제목·목적·사전조건·단계/expected·priority/tags/platform','CHECKER_CODEX_PROMPT.md:13',['A02','W03','D06'],'부분 범위','docs/architecture/shared-scenarios.md','XML 및 제목·버전 흐름은 구현. 원본 TC 전체 설명 메타데이터를 편집·배포하는 독립 폼은 추가 계약/인수 필요'],
['Flow·블록 편집 / XML 직접 편집','PHASES_AND_ACCEPTANCE.md:25-26 / CODEX_MASTER_PROMPT.md:44',['D05','D06','D07'],'구현·Windows/CLI 인수','docs/validation-xml-block-studio.md','파일 블록 제한 조합과 내부 action 구분. 임의 include/call·runtime cycle 지원 아님'],
['실행·단계 로그·결과·PNG·실패 원인','CHECKER_CODEX_PROMPT.md:17,62',['D07','W05','W06','E01'],'구현·Chromium 실제 인수','docs/validation-project-home.md','목업 결과는 예시이며 실제 artifact는 기존 인수 링크로 분리'],
['기준 이미지·시각/layout/UX 비교','원본 QA 확장 원칙 / 현행 design-ux 명세',['D06','D07','W06','A03','E01'],'Engine·Checker 구현 / 조건부 비교','docs/architecture/design-ux.md','reference/profile/hash를 요구. 자동 기준 승격은 아님. 환경 불일치·증거 부재는 비교 불가'],
['불변 게시·독립 검수·Suite·pin·diff','CHECKER_CODEX_PROMPT.md:26 / CODEX_MASTER_PROMPT.md:61',['A01','A02','W02','W03','W04'],'구현·서버/웹 인수','docs/validation.md','반려·수정·폐기 API 및 개인 Suite Assignment inbox는 미구현'],
['업무 담당·주간 비교·알림','CHECKER_CODEX_PROMPT.md:30 / CODEX_MASTER_PROMPT.md:45,64',['A03','A06','W06'],'구현·local provider/notification fixture','docs/architecture/organization-auth-workflow.md','Run 업무와 실행 판정 분리. 외부 Slack 알림은 미완료'],
['예약·Agent·독립 자동 실행','PHASES_AND_ACCEPTANCE.md:40-47 / CODEX_MASTER_PROMPT.md:64',['W08','A04','A05','A08'],'구현·기본 alpha6 실제 교차 인수','docs/validation.md','Desktop 전체 Suite UI가 아님. 리소스 재고 CRUD UI는 미구현'],
['사용자·팀·역할·프로젝트 관리','CODEX_MASTER_PROMPT.md:45',['W01','A07'],'목표 / provisioning만 구현','docs/architecture/organization-auth-workflow.md','CRUD API·감사·권한 계약부터 정의하고 승인→구현→인수 필요'],
['독립 Engine package/CLI 재사용','CODEX_MASTER_PROMPT.md:14,33 / ENGINE_CODEX_PROMPT.md',['E01','D07','A05'],'독립 설치·공개 API/CLI 인수','design/mockups/product-planning/evidence/engine-planning-evidence.md','원격 npm 운영 공개 완료 아님. Flutter/서버를 필수 의존으로 두지 않음'],
['모바일 Android/iOS','PHASES_AND_ACCEPTANCE.md:49-52 / CODEX_MASTER_PROMPT.md:37,101',['E01','A08','D07'],'protocol·capability fixture / 실기기 미인수','design/mockups/product-planning/evidence/engine-planning-evidence.md','기기/OS/driver/cleanup 실증 후 지원 선언. fixture를 실기기 실행으로 표시 금지'],
['TV·일반 화이트박스','PHASES_AND_ACCEPTANCE.md:53 / CODEX_MASTER_PROMPT.md:37,102',['E01','A08'],'미지원 / 후속 조사','docs/planning/roadmap.md','플랫폼별 adapter·실기기와 allowlist/sandbox 계약이 먼저 필요'],
['AI 작성 보조·recorder·선택 export','PHASES_AND_ACCEPTANCE.md:58-60 / CODEX_MASTER_PROMPT.md:77,102',['D08','D05','W07','E01'],'AI/PTY·XML round-trip 부분 구현','docs/validation-terminal-blueprint.md','실제 AI 자동 편집 반영 인수 일부 미완료. recorder·범용 코드 생성 export는 미구현; XML 저장과 구별'],
['원본 이관·저장소/역할 경계·단계별 인수','COPY_PASTE_FIRST.md / WORKTREE_OPENSPEC_GUIDE.md / README.md',['E01','D01','A01'],'관리 원칙 / 기존 이관 명세','openspec/changes/refactor-server-web-app-monorepo/design.md','원본 모노레포 예시를 Engine 동일 repo 강제나 웹 관리자 전용으로 복제하지 않음']
];
const previousRender=render;
render=function(){previousRender();const target=$('#requirement-map');if(target)target.innerHTML=`<h2 style="margin-top:30px">원본 요구 → 현재 기능 → 후속 인수</h2><p>원본 MD 8개와 최신 사용자 지시를 함께 반영합니다. 현재 범위가 없는 요구도 삭제하지 않습니다.</p>${table(['원본 요구 / 근거','관련 화면','현재 범위·근거','남은 인수'],requirementMap.map(([title,source,ids,status,path,next])=>[`${title}<br><small>${source}</small>`,ids.map(id=>link(id)).join('<br>'),`${status}<br><a href="../../../${path}" target="_blank">근거 문서</a>`,next]))}`;};
render();
