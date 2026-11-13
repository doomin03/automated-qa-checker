# 기획과 실제 앱 대응

## Baseline

2026-11-12, `main@3e73cd1`. 입력은 `design/mockups/product-planning/index.html`, 화면 정의 `app.js`의 desktopSeed, 여정 정의, `requirements.js`, 서버/웹 관계 `data.js`다. 목업은 실행 증거가 아니며 기존 완료와 이번 검증을 구분한다. 기존 기획 파일은 수정하지 않는다.

앱 경로의 `workbench/`는 `apps/app/lib/app/workbench/`, `features/`는 `apps/app/lib/features/`를 뜻한다.

## Screen mapping

| 기획 | 현재 구현·기존 증거 | 이번 보완과 인수 | 의존/경계 |
|---|---|---|---|
| D01 홈·프로젝트 | `workbench/views/project_home.dart`, `view_models/project_home_view_model.dart`; `docs/validation-project-home.md` | 작은 창의 sidebar/상단/목록, 긴 이름·검색0·offline·저장 실패; 숨긴 탐색 재접근 | 로컬 workspace 포맷 유지, 서버 없이 사용 |
| D02 프로젝트 QA 목록 | 같은 홈, `DesktopWorkspaceViewModel`의 선택/dirty guard/lastRun | list+260px 상세의 compact 전환; 큰 글자·긴 이름·선택0; QA 전환/재개 시 source/dirty/run 소속 유지 | 개인 배정 목록으로 표시하지 않음 |
| D03 서버에서 받기 | 홈 수신 및 `features/shared_scenarios`; `integration_test/project_home_test.dart`의 실제 서버 수신 | context/역할/서버 Engine 표시, ordered Suite pin 재조회·case 선택; receive dialog bounded scroll; loading/error/retry·연결 교체 | backend context/PinPage 생성 SDK 후 소비; 수신으로 실행0 |
| D04 가져온 QA | receipt 저장/원본 hash/로컬 QA 매핑, 기존 home native 인수 | 원본 서버/프로젝트/version과 로컬 변경 표시가 좁은 화면에서도 조회 가능; 동일 version 재수신·다른 QA 귀속 방지 회귀 | 원본 bytes hash와 실행 snapshot hash 구별 |
| D05 XML 파일 블록 작업실 | `views/xml_block_studio.dart`, `view_models/xml_block_workbench_view_model.dart`; `docs/validation-xml-block-studio.md` | 740px 미만 inspector 접근 결손 보완, library/dialog/toolbar/속성 scroll; pan/zoom/fit/선택/연결 및 실행 sourceMap 유지 | 파일 자산≠내부 action; 같은 target·단일 입출력 등 기존 합성 제한 유지 |
| D06 직접 XML 문서 | `desktop_workspace_view.dart`, editor VM/공개 EngineService | raw source와 compiled preview 구분, 낮은 창/긴 코드/검증 오류, dirty 및 검증 만료; sourceMap 없는 직접 문서 상태 표시 | parser/DSL은 Engine; 사용자 명시 실행 |
| D07 검증·실행 결과 | `features/run_review/views/run_results.dart`의 events/검증 PNG/check reports; 기존 desktop/studio native PASS·FAIL·cancel | bounded 결과 dock, 원QA/run/snapshot 표기, PNG/긴 오류 접근; alpha8→alpha6 공유 불가 분리 | 실제 step.finished/outcome skipped, 요청cancel≠최종cancelled, 업무done≠passed |
| D08 AI 도구·터미널 | `TerminalDock`, `TerminalWorkbenchViewModel`, PTY service; 기존 후보 생성 AI는 `docs/validation-desktop-ai.md`, terminal 부분 증거 `docs/validation-terminal-blueprint.md` | 결과와 terminal 높이 조정/compact 작업 패널; focus 단축키 격리; 직접 문서 stable file→plan→GUI, dirty충돌/QA변경/stale; 실제 PTY fixture 파일 반영 인수 | 고정 후보 폼은 명시apply; interactive는 clean 시 자동반영. 이번 모델 호출은 미실행, Claude 미설치와 fixture 구분 |

## Journey and relationships

| 기획 관계/여정 | 이번 Desktop 반영 | 그대로 남는 경계 |
|---|---|---|
| 공용 게시물→수신 사본→수정→명시 실행→결과 | D03/04 원본, D06 문서, D07 실행 snapshot을 별도 표시 | 게시 원본 불변; 수정 snapshot을 원본 실행으로 귀속 금지; runtime 불일치 공유 거절 |
| 프로젝트→QA→파일 자산/인스턴스→합성→Engine | D01/02→D05/06→D07 사용자 버튼 경로 | 새 실행 schema 없이 공개 Engine plan/run; GUI 좌표는 기존 저장 경로 |
| Suite pin→ordered case→로컬 QA | 재조회 목록·case 선택·사본 저장 | Desktop 전체 Suite 실행 아님; 서버 Agent 순차 실행과 구분 |
| 예약→Agent→진행/결과 | 기존 서버 계약·상태 확인에 필요한 연결 문맥 유지 | scheduler/Agent 프로토콜을 앱에서 새로 구현하지 않음 |
| 실패→업무상태/비교/알림 | 실행 판정/증거/공유 표시와 업무상태 의미를 혼합하지 않음 | 기존 웹/서버 업무흐름, 실제 Slack 검증 미완료 유지 |
| AI 생성/터미널→파일→GUI→실행 | 선택 문맥·프로젝트/QA 요청·파일 변화를 문서모드에 맞게 연결 | AI가 자동 실행한 것으로 보고하지 않음; 실제 terminal 임의명령은 앱 통제 범위 밖 |

## Requirements inventory disposition

| requirements 영역 | 판정 |
|---|---|
| 공개 실행 schema/events/result, 독립 Engine | 기존 구현 재사용. Engine 변경·pin 변경 없음 |
| 조직/프로젝트/공유 수신 | 기존 API에 context/핀 조회 추가를 backend가 담당. 앱은 생성 SDK만 소비 |
| TC 번호/목적/사전조건/우선순위/태그 전체 편집 | 제목/XML/version 외 완전한 업무 metadata 폼은 후속 계약. 이번 D01–08 필수경로 아님 |
| Flow/block/XML, 실행 logs/PNG | 이번 통합·반응형 인수의 핵심 |
| 디자인/UX 기준 비교 | 기존 검증 report/PNG 표시를 유지·scroll 인수. 기준 자동 승격 금지 |
| Registry/review/pin/diff | 기존 기능 및 이번 pin 재접근. 개인 배정/withdrawal 확대 없음 |
| workflow/comparison/notification | 기존 서버/웹 구현. 실제 Slack 수신 인수로 주장하지 않음 |
| scheduler/Agent/resource | 기존 alpha6 상태 보존. Desktop 전체 Suite/자원관리 CRUD 후속 |
| 사용자/팀/역할 CRUD | backend 기획 범위 별도. 이번 앱에 관리자 CRUD 화면 추가 없음 |
| 모바일/TV/whitebox | 실제 기기 및 TV/whitebox 후속, 데스크톱 resize가 모바일 지원이라는 뜻 아님 |
| AI/Recorder/일반 코드 export | 기존 AI/terminal 연결만; recorder/일반 코드 export 미구현 유지 |
| 원본 MD8/두 repo/모노레포 출처 | 기존 설계/인수 보존, 원본 기획이나 Engine repo 수정 없음 |

## Acceptance distinction

기존 `project_home_test.dart`, `xml_block_studio_test.dart`, `desktop_ai_test.dart`는 이미 확보된 기본 기능 증거다. 이번에는 작은 창/글자 확대/긴 내용/패널 동시 열기, 새 context/pin SDK, 현재 통합 terminal의 사용자 경로를 새로 인수한다. 정적 코드 관찰만으로 overflow 재현 PASS/FAIL을 작성하지 않는다. 실제 Windows DPI, Flutter text scale, 위젯 devicePixelRatio를 각각 기록한다.
