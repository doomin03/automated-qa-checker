# Design

## Context

기준 HEAD는 `main@3e73cd1`, 조사일은 2026-11-12다. `mapping.md`는 기획 D01–D08/관계도/여정/requirements를 실제 코드와 연결한다. 현재 기존 홈 및 XML 블록 native 인수는 존재하지만 800×600·낮은 높이·확대 글자와 모든 도킹 조합 인수는 없다. 아래 정적 관찰은 아직 새 런타임 결함 재현 결과로 표시하지 않는다.

- `ProjectHome`: sidebar 176, QA 상세 260/수신 상세 고정 폭, 상단 44 높이. 고정 크기 수신 dialog.
- `DesktopWorkspaceView`: 탐색 패널은 1200 미만에서 숨김, AI 290/330 폭, 결과 200 높이, 설정/미리보기 dialog 고정 크기.
- `XmlBlockStudio`: library는 1100 이상, inspector는 740 이상에서만 inline 표시. library는 dialog 대안이 있지만 inspector 버튼은 좁은 창에서 bool만 바꾸며 실제 패널이 나타나지 않는다.
- `TerminalDock`: 현재 180 높이와 창 전체 높이의 45% drag 제한이며 실제 남은 영역을 고려하지 않는다. header 34와 상태/경로 행도 별도 높이를 차지한다.
- Flutter MVVM/Provider, 실제 PTY 및 alpha8 공개 CLI, 실행 sourceMap·PNG 검증 경로는 이미 존재한다. 관련 View만 이동해 Provider scope와 프로세스 소유권을 새로 만들지 않는다.

## Goals / Non-Goals

**Goals:** 기획의 현재 제품 여정을 창 크기와 글자 배율에 관계없이 완수하고, 출처·권한·호환 상태를 실제 계약과 연결한다. 시각 기준은 기존 어두운 desktop chrome/파일 블록 canvas이며 새 테마 작업이 아니다.

**Non-Goals:** ScreenUtil 추가, 전역 배율 고정, 새로운 Engine DSL/renderer, 서버 runtime 승격, 개인 배정함·전체 Suite 일괄 실행·사용자 CRUD·실기기·recorder. 서버 members 조회는 이 Desktop 여정에 직접 소비자가 없어 앱 범위에서 제외한다.

## Decisions

### D1. Local constraints and accessible panels

ScreenUtil 없이 `LayoutBuilder`의 실제 부모 제약으로 홈/편집기/도킹을 계산한다. `MediaQuery`는 전체 view와 사용자 textScaler 정보에 사용한다. 작은 UI 정책 객체/위젯을 app/workbench에 두되 업무 상태를 복제하는 VM은 만들지 않는다. `Expanded/Flexible/Wrap`으로 컨트롤을 배치하고 텍스트를 전역 축소하지 않는다.

충분한 폭에서는 기존 sidebar/inspector를 유지한다. 부족하면 탐색·목록 상세·속성·AI를 한 번에 하나의 bounded 대체 패널로 열며 닫기와 원 화면 복귀를 제공한다. 버튼만 존재하고 내용이 안 나타나는 상태를 없앤다. breakpoint는 폼/글자 실측으로 결정하고 폰/태블릿 이름으로 분기하지 않는다.

### D2. Shared vertical budget and view lifetime

상단 chrome을 제외한 실제 body 높이에서 편집기와 하단 dock의 예산을 계산한다. 넉넉할 때 사용자의 dock 높이를 존중한다. 높이 700 logical px 미만에서는 결과와 터미널을 각각 bounded 작업 패널로 열어 주 편집 영역을 유지한다. 1280×500에서 inline 결과/터미널 때문에 canvas가 74px 이하로 줄어든 실제 회귀가 이 정책의 근거다. 저장된 선호 높이와 현재 clamp된 높이를 구분해 창 복원 시 되돌린다. 최소 viewport에서 캔버스 유효 높이 180 logical px를 목표로 하며 글자 확대 시 핵심 도구를 가로 스크롤/대체 패널로 이동한다.

반응형 재배치가 Repository/VM/PTY를 dispose하거나 실행을 재시작해서는 안 된다. View의 controller/focus 수명은 중앙 editor의 안정된 key와 조합 구조로 유지한다. 터미널 선택/스크롤 controller는 부모 dock이 소유하고 bounded 패널에 빌려주며 활성 TerminalView는 한 개만 둔다. 패널은 빌린 controller를 dispose하지 않는다. 화면을 숨기는 것과 터미널을 종료하는 것은 별도 액션이다.

### D3. Scroll, text and dialogs

목록·inspector·AI·로그/결과는 각자 bounded scroll과 필요한 scrollbar를 갖는다. 대화상자는 가용 폭/높이 이하이며 내용만 스크롤하고 닫기/확인 액션에 접근 가능하게 한다. Tab focus 이동 시 대상이 scroll into view 된다. 긴 오류 원문을 두 줄 ellipsis로만 소비하지 않고 상세 열기를 제공한다. 이름 summary 생략은 tooltip/상세에서 전체 원문을 확인할 수 있을 때만 사용한다. XML/로그의 의도된 가로 스크롤과 일반 폼의 overflow를 구분한다.

### D4. Project contract consumption

Backend counterpart `qa-product-planning-backend-context`가 공개 context DTO와 Suite pins 조회를 정의·테스트·생성한다. 합의 초안은 `getProjectContext → ProjectContextResponse {projectId, role, allowedActions, engine:{engineVersion,contractVersion,contractSha256,archiveSha256:null|string}}`이며 `listSuitePins → PinPage {items:[packageId,versionId,sha256],nextCursor}`를 재사용한다. 앱은 이 응답을 connection generation에 묶는다. allowedActions는 역할의 진입권한이며 ownership/reviewer/revision은 mutation의 서버 검사가 최종 권위다. 정책을 role 이름만으로 새로 발명하지 않는다. 기본 alpha6 서버와 alpha8 앱은 호환되지 않는 공유 상태를 먼저 보여주며 서버의 실제 최종 검사를 유지한다. context 실패/불명확 상태는 서버 행위만 닫고 로컬 편집·실행은 보존한다.

기존 Suite 수신은 ordered case 선택 경로이며 조회 API는 저장된 pin 재접근에 사용한다. 새로운 실행 DTO/Engine schema는 만들지 않는다. API 변경은 backend 소유이고 검증된 Dart SDK checkpoint 이후에만 앱을 연결한다. 구형 서버의 context 404는 서버 업그레이드 필요/정보 없음으로 표시하며 임의 호환으로 간주하지 않는다. context는 조회 시점의 서버 설정이며 실시간 장치 접속/설치 상태나 mutation 성공을 보증하지 않는다.

### D5. Document and AI authority

파일 블록은 재사용 XML 자산과 인스턴스, 직접 문서는 XML/JSON, 실행은 불변 snapshot으로 구분한다. 기존 `XmlBlockWorkbenchViewModel`의 run blocking과 sourceMap을 유지한다. 기존 후보 생성 도구는 검증된 preview를 명시 적용하는 경로다. interactive terminal은 직접 문서에서 stable read→고유 `.xml/.json` snapshot→공개 plan→QA/document/Flow/settings/filehash 재대조→clean 상태 자동 반영의 기존 정책을 사용한다.

합성 모드에서 터미널 파일을 자동 반영해 compiled preview를 덮는 흐름은 제공하지 않는다. 직접 문서로 이동하는 명시적 안내와 dirty guard를 제공한다. 터미널 세션이 살아 있다는 이유만으로 앱의 모든 검증/실행을 busy로 막지 않으며 실제 conflict/미검증 source를 기준으로 판단한다. 앱은 사용자가 terminal에서 직접 실행한 임의 명령을 추적/통제한다고 주장하지 않는다.

### D6. Verification and preservation

위젯 행렬: 1440×900/1024×768/800×600/1280×500 × text1/1.25/1.5. 긴 한국어, 120자 경로, 긴 오류, 다수 목록, terminal+result, focus 이동, 패널 열기/닫기, canvas zoom/selection을 검사한다. geometry와 액션 도달 여부를 확인하고 단순 overflow 로그만 PASS 기준으로 삼지 않는다. devicePixelRatio 1/1.25/1.5 변경과 textScaler는 별개로 테스트하며 OS DPI 설정을 바꿨다고 보고하지 않는다.

Windows 통합은 실제 화면의 홈→게시물/핀 수신→직접/파일 블록→검증→명시 실행→결과 PNG, compact panel 접근, resize 중 문서/프로세스 유지, alpha6 게시 불일치와 로컬 결과 유지에 집중한다. 실제 CLI/PTY fixture 인수와 실제 Codex 모델 파일 편집 인수를 분리한다. 외부 모델 편집은 가능한 경우 추가 인수하되 UI 보완의 완료를 외부 서비스에 종속시키지 않고 미인수를 명시한다. 기존 validation은 회귀 선정 근거로 재사용하고 이번에 재실행한 결과만 새 PASS로 기록한다.

## Risks / Trade-offs

- 패널 reparent로 focus/controller가 초기화될 위험 → stable scope/key, 왕복 resize와 진행 중 세션 identity 회귀.
- context/SDK 변경과 동시 작업 충돌 → backend 단독 생성, 앱은 받은 checkpoint 소비. root lock/scripts 수정은 관리 조율.
- 큰 글자에서 정보 밀도 감소 → scroll/대체 패널, 글자 크기 강제 축소 금지.
- 실제 Codex 로그인/신뢰/외부 모델 상태 → 전용 repo 밖 fixture만 사용하고 외부 조건 실패를 fixture 성공으로 대체하지 않는다.
- 기획의 후속 목표 혼합 → mapping에서 명시 제외, 기존 미완료 task를 이번 완료로 소급하지 않는다.

## Migration Plan

작업실/수신 저장 포맷을 바꾸지 않는 UI 보완을 먼저 적용하고 backend SDK를 연결한다. 기존 Release와 설치/pin은 보존한다. 인수된 앱은 `artifacts/releases/desktop-planning-responsive-alpha8` 별도 폴더와 전체 파일/source manifest로 배포하며 native launch를 확인한다. 되돌림은 기존 Release 실행으로 가능하며 사용자 workspace 데이터를 reset하지 않는다.

## References

- `design/mockups/product-planning/{app.js,requirements.js,data.js}` 및 기존 완료 change/validation (세부 `mapping.md`).
- [Flutter adaptive layout](https://docs.flutter.dev/ui/adaptive-responsive/general): 전체 view와 local constraints 구분.
- [Flutter TextScaler](https://api.flutter.dev/flutter/widgets/MediaQuery/textScalerOf.html): 사용자 글자 배율을 layout에 반영.
- `frontend-design` 및 `qa-workbench-design` 로컬 스킬. 새 라이브러리/테마가 아니라 기존 desktop 작업실을 제약에 맞추는 선택.
