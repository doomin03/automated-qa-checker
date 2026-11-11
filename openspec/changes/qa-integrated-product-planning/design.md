# Design

## D1. 근거와 작업 경계

Checker main HEAD `4f97e920a399d4a5434ab1ecbe44c4d879d397a4`, 기존 미커밋 작업·이전 목업·Release 보존. 최신 사용자 역할 정의와 원본 MD 8개의 프로젝트→QA 작성/검수/게시→다운로드/고정→실행/증거/업무 흐름이 기준이다. `apps/web/src/app/App.jsx`의 실제 UI route는 `/qa/blueprints`, `/qa/shared`이며 화면을 새로 분리하는 목업 IA는 제품 route 구현 완료가 아니다. 기존 Desktop home native `run-7a4c81ce`, studio native 및 공개 Engine 계약, 서버 API/권한 실사를 기능별 증거로 연결한다.

Checker는 화면/기획 통합을 소유한다. Engine 담당은 공개 package/CLI·snapshot/event/outcome·runtime 경계를, 웹 기획 담당은 실제 서비스/역할·화면 분해를 확인한다. 담당 직접 대화에서 제안, 구체적 반례, 수정/수용을 기록한다. 기존 제품 결함을 발견하면 계획 추적에만 남기고 이 change에서 제품 수정하지 않는다.

## D2. 검토 도구의 구조

단일 `design/mockups/product-planning/index.html`은 별도 서버 없이 열리는 정적 HTML/CSS/JS다. 로컬 연결은 상대경로, 웹 API/자격증명·외부 폰트 의존은 없다. 초기 화면은 기능 관계도이며 항상 `관계도 / 사용자 여정 / 화면설계 / 목업 / 결정과 근거`로 이동할 수 있다. 화면 ID와 여정은 URL hash로 직접 열고 브라우저 뒤로가기와 선택을 보존한다.

화면설계는 좌측 화면 목록·검색, 본문 목적과 정보/행동/상태, 우측 또는 아래의 해당 화면 미리보기로 구성한다. `이 상태 열기`는 같은 ID/상태를 가진 목업을 열고 `화면설계`로 돌아온다. 긴 modal 또는 문서 링크 모음으로 대체하지 않는다. 화면 목록에는 모든 검토 화면과 대응 여정/구현 근거가 있으며 고립 화면이 없어야 한다.

Desktop ID는 D01 홈·프로젝트, D02 로컬 QA, D03 서버에서 받기, D04 가져온 QA, D05 XML 파일 조합, D06 직접 XML, D07 검증·결과, D08 AI 도구·터미널이다. 웹 담당의 Wxx 공용 QA/진행, Axx 초안·검수·게시/운영 화면 ID를 수용하고 E01 독립 Engine 계약 화면을 둔다. 실제 Engine GUI가 있다는 의미가 아니라 검토용 입출력/실행 경로 설명이다.

관리 승인 조건으로 기존 studio에 작은 review route adapter를 추가한다. D01–D08 선택은 해당 홈/목록/편집/결과 또는 명시적인 설명 상태로 연결하며 모두 홈만 여는 링크로 대체하지 않는다. planning iframe은 별도 sessionStorage namespace를 사용하여 기존 localStorage의 사용자 예시 문서를 읽거나 덮지 않는다. 기존 직접 studio 진입은 기존 저장소와 동작을 유지한다.

## D3. 관계도와 데이터 의미

관계도는 사용자 웹, 관리 업무 웹, Checker Server, Agent, Desktop, 독립 Engine을 구분한다. 화살표는 XML+게시 version/hash, 로컬 receipt, 실행 요청, lease/heartbeat, events, result/artifact 등 실제 전달물을 표시한다. 외부 프로젝트→Engine package/CLI 경로도 포함한다.

로컬 경로는 서버 alpha.6 게시 XML 수신→새 로컬 QA→alpha.8 검증/명시 실행→로컬 결과다. 원격 경로는 서버 실행/예약 요청→Agent의 alpha.6→서버 진행/증거 조회다. 두 경로의 runtime 일치나 결과 자동 게시를 가장하지 않는다. alpha.8 결과를 기본 alpha.6 서버에 보내는 거부는 Engine terminal outcome `blocked`와 다르다.

원문 XML byte hash는 무결성, canonical snapshot hash는 실행 의미 식별이다. 원본 version 연결은 local QA+origin/project+snapshot 조건을 지키며 수정/합성 후 동일 게시 버전으로 귀속하지 않는다. XML 파일 블록과 내부 action node, 조합 sidecar/sourceMap과 실행 XML, 실행 outcome과 업무 status를 분리한다. Engine outcome 5종 passed/failed/blocked/infra_error/cancelled와 취소 요청 중을 구별한다. 검증 실패는 실행 결과를 생성하지 않는다.

## D4. 사용자 여정과 화면 상태

- 로컬 작업: 홈→프로젝트/QA→파일 조합 또는 직접 XML→검증→명시 실행→결과/증거/원인 블록→저장/홈. 선택·레이아웃은 실행 의미 변경이 아니며 원문 변경은 검증을 무효화한다.
- 공용 수신: 사용자 웹 프로젝트→게시 QA 또는 Suite 고정 버전→XML 전달/다운로드 안내→Desktop 서버에서 받기→새 로컬 QA. Suite는 개별 case 수신이고 전체 Suite Desktop 실행은 미구현이다. 기존 사본 열기와 새 사본 받기를 분리한다.
- 관리 업무: 작성→검수→게시→사용자 공용 목록. 업무 할당은 run 기반이며 게시 QA 개인 inbox를 발명하지 않는다.
- 원격 운영: 서버 실행 요청/예약→Agent 진행→event·증거 확인→업무 상태/담당/감사. 역할마다 허용 액션이 다르며 qa_tester가 가능한 예약을 admin 전용으로 표현하지 않는다.

화면별 목적/사용자·권한/진입·이탈/입력·데이터/액션/정상·빈·로딩·연결오류·권한거부·미저장·실행 중·실패·취소/상대 API/인수를 구조화한다. 해당 없는 상태는 이유를 표시한다. 예시 상태 선택은 사용자 조작으로만 바뀌고 실제 서버를 호출하지 않는다. 비활성 동작은 이유를 표시한다.

## D5. 구현과 제안의 표시

기능 registry는 `구현 확인`, `실제 검증`, `화면 구조 제안`, `미완료/미지원`을 별도 필드로 가진다. 하나의 완료 배지로 합치지 않는다. 파일·문서·검증 artifact 링크와 인수 조건을 함께 제공한다. Desktop AI CLI/PTY의 실제 구현과 미인수 자동 반영, 개인 QA inbox, 전체 Suite Desktop 실행, 사용자·팀·역할 CRUD, alpha8→alpha6 게시 호환성을 과장하지 않는다.

## D6. 디자인 토큰과 검토

공식 frontend-design 및 qa-workbench-design을 적용한다. Desktop은 canvas `#1c1c1c`, chrome `#292929`, panel `#323232`, control `#414141`, text `#e0e0e0`, selection `#8ea8bd`를 유지한다. 검토/웹은 같은 Segoe UI/Malgun Gothic와 4px 간격 체계, 13px 본문·14px 패널·20px 페이지 제목, 1px 구분선을 사용한다. 웹은 밝은 문서 바탕 `#f5f5f3`, 진한 글자 `#292929`, 중립 선택 표시로 긴 목록·검수 비교를 읽기 쉽게 한다. 의미 있는 상태색 외 장식색·그라데이션·KPI·hero·대문자 장식을 사용하지 않는다.

```text
QA 기획 검토    관계도  여정  화면설계  목업  결정
화면/검색       목적·사용자·현재 구현 근거       상태/역할
Desktop         선택한 화면 또는 조작 목업
사용자 웹       목록 | 선택 내용 / 검수 비교
관리 업무       다음 행동 · 관련 화면설계
Engine          예시 데이터 / 실제 증거 링크
```

검토 결과: 기존 Desktop을 새 웹 틀로 다시 그리지 않고 iframe 안에 보존한다. 웹은 조회·검수·운영의 행 목록과 선택 상세를 강조한다. 기획 설명은 검토 도구 안에 두고 제품 chrome을 개발 메모로 채우지 않는다. 1024에서는 부차 설계 패널을 아래나 접힘으로 옮기며 핵심 버튼과 목록을 유지한다.

## D7. 검증과 보존

관계도 노드/화면 ID/여정 링크/근거 경로의 유효성, 화면설계↔목업 왕복, 역할별 액션, 상태 예시, 프로젝트→수신→편집의 기존 조작, 명시적 run 예시와 오류/취소 경계를 자동 클릭 검증한다. 1440×900/1024×768의 관계도·설계·웹 사용자·검수·운영·Desktop 홈/작업실을 캡처 후 시각 검수한다. 기존 studio 핵심 검사는 회귀를 확인한다. 제품 Engine/Windows 재실행이나 새 Release는 필요 없으며 기존 인수 증거와 이번 목업 검증을 분리한다. OpenSpec strict, diff check, 변경된 정적 파일 검사를 수행한다.

## D8. 기존 기획 문서 정합

`docs/planning/roadmap.md`의 과거 P2/P3/P4 미구현 표기를 현재 구현과 단계별 실제 인수 증거로 갱신하되 역사적 계획을 완료 주장으로 변환하지 않는다. `docs/architecture/system-design.md`는 Engine이 웹에 직접 결과를 게시하는 것으로 읽히지 않게 Desktop 또는 Agent가 공개 결과를 수집하고 필요한 서버 계약으로 전달함을 표시한다. 사용자/팀/역할 CRUD는 목표와 현재 구현을 구분한다. `organization-auth-workflow.md`의 alpha.5는 과거 인수 범위로 보존하고 현재 alpha.6/alpha.8 pin 안내를 연결한다. 제품 코드나 계약을 변경하지 않는다.
