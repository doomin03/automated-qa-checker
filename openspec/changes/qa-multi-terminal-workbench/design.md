# Design

## Context

`TerminalWorkbenchViewModel`에는 단일 TerminalService/Terminal/session/watcher/hash/undo가 있고 `start()`가 Codex만 허용한다. `TerminalService`는 bounded PTY 입출력과 Job close, cleanup_unknown latch를 이미 제공한다. `LiveDocumentRepository`는 고정 canonical root, 1 MiB UTF-8 읽기, 형식 검사와 후보 compile을 담당한다. 이를 재사용하되 목록만 감싸서 callback이나 감시 상태를 공유하지 않는다. `XmlBlockCompiler`의 namespace·참조 치환·접합 의미는 아직 Dart 소유다.

목업 `qa-multi-terminal-planning` 완료는 실제 제품 인수가 아니다. 현재 baseline은 main 3e73cd1의 기존 dirty이며 이전 반응형 작업·목업·서버/SDK를 보존한다. 최신 사용자 Engine 작성 기능 이관 지시가 디자인 스킬의 과거 Checker compiler 소유 설명보다 우선한다.

## Goals / Non-Goals

**Goals:** 실제 독립 PTY 다중 세션, 문서별 자동 반영 권한, 작은 창에서도 편집과 세션에 접근, Engine 공통 작성 기능 소비.

**Non-Goals:** 프로젝트 DB의 Engine 이관, 새 실행 DSL, 셸의 임의 명령을 앱이 모두 통제/추적한다는 보장, 자동 QA 실행, 기존 세션 프로세스의 앱 재시작 후 복구, 서버 runtime 승격, 일반 터미널 에뮬레이터 전체 기능 재작성.

## Decisions

합성 미리보기는 파생 문서다. Terminal pool은 XML block mode/semantic revision을 주입받아 직접 문서일 때만 원문 자동 반영/undo/GUI 저장을 허용한다. 합성 모드 파일은 검증된 검토 후보로 보존하고 기존 '직접 문서 / Flow' 전환을 안내한다. mode 전환 epoch를 candidate stamp에 포함하여 direct→composition→direct의 늦은 결과도 거절한다.

### D1. 세션 pool과 단일 소유권

app composition root가 TerminalService factory와 전용 compile repository를 조립한다. 상위 workbench VM이 session pool을 소유하며 각 session runtime은 immutable id/provider/projectId/qaId/시작 cwd/Engine pin과 개별 TerminalService, Terminal, watcher/debounce/poll, 후보/hash/상태를 소유한다. UI controller(스크롤·selection·focus)는 keyed session view-state registry가 소유하고 뷰 간 공유 시 동시에 활성 TerminalView 하나만 연결한다. 서비스나 VM이 편집기 TextEditingController를 소유하지 않는다.

pool은 최대 8개 보관 세션으로 시작한다. 상한에서 명시 안내하고 종료된 세션을 사용자가 제거하며 자동 삭제/종료하지 않는다. 세션별 출력은 기존 10,000줄·PTY 64 KiB window, 입력 32 KiB/회 제한을 유지한다. 숨긴 세션도 출력 drain을 계속한다. compiler 공유는 repository queue로 직렬화하여 한 prepare가 다른 세션의 process/cancel 상태를 덮지 않게 한다. run service와 compiler service는 별개다.

세션 종료는 해당 watcher와 후보 ticket을 먼저 무효화하고 해당 Service.close만 await한다. 다른 세션 callback/PTY는 건드리지 않는다. close 중 재호출은 같은 Future에 합류한다. parent exit/늦은 close 후에도 cleanup_unknown latch가 유지된다. 앱 종료 확인은 pool.closeAll로 모든 소유 세션을 bounded하게 정리하며 Provider dispose는 마지막 방어다. 외부 주입 factory/repository 소유권은 기존 composition 규칙대로 명시한다. 앱 다시 시작 시 과거 세션을 running으로 복구하지 않는다.

### D2. Provider 준비와 실제 실행

프로필은 provider ID, 표시명, 절대 executable 경로, 알려진 인자 builder와 탐지 상태를 가진다. PATH/명시 경로의 파일 존재, bounded version/help probe와 실제 spawn 결과를 구분한다. readiness는 missing/unsupported/available/failed이며 AI 로그인과 신뢰 프롬프트는 실제 TUI에서 표시한다. 설치됨을 인증됨 또는 모델 성공으로 표기하지 않는다. 외부 패키지 설치·사용자 credential 복사·전역 CLI 설정 수정은 하지 않는다.

2026-11-12 조사: Codex 0.162.1, `--no-daemon --no-alt-screen -C <session> -s workspace-write -a on-request`를 실제 help에서 확인했다. 공식 [CLI reference](https://learn.chatgpt.com/docs/cli/reference)를 열어 확인했다. 명시 사용자 시작만 허용하고 일반 셸 문자열 연결 대신 executable/args 배열을 사용한다. Windows PowerShell은 `-NoLogo -NoProfile`, cmd는 `/D`로 시작하며 고정 workingDirectory를 전달한다. pwsh/Claude는 PATH에서 발견되지 않았다. Claude 별도 builder는 설치된 CLI의 지원 옵션 확인 후 사용하고 Codex 옵션을 재사용하지 않는다. shell에는 AI skill 준비 배지를 붙이지 않는다. provider 선택은 임의 credential 저장 폼을 추가하지 않는다.

cwd 표시는 시작 경로다. 사용자가 셸에서 cd한 현재 경로를 강제/추적한다고 하지 않는다. 역할명 검토도 OS read-only 권한이 아니다. 세션 사본과 컨텍스트는 앱 workspace 아래 고유 canonical 폴더이며 원본 수신 자료/다른 세션 파일을 덮지 않는다. 프로젝트/QA 지침, 선택 문맥, 공개 고정 schema/template 안내만 제공하고 비밀값을 복사하지 않는다. 임의 셸 명령의 실행은 사용자의 실제 터미널 동작이며 앱 run 결과로 합성하지 않는다.

프로젝트/수신 QA의 현재 실행 계약을 `authoring-environment.json`에 engineVersion/contractVersion/contract hash/guideVersion으로 식별한다. 각 AI 사본에 공개 engine-contract.json/example.json과 Codex `.agents/skills/qa-authoring/SKILL.md` 또는 Claude `.claude/skills/qa-authoring/SKILL.md`를 생성한다. 가이드는 해당 사본 정의 편집과 명시 앱 실행 경계만 안내한다. 파일 준비와 실제 CLI discovery/모델 활용은 별도이며 일반 셸에 skill 준비를 표시하지 않는다. 사용자 전역 설정·credential은 읽어 복사하거나 수정하지 않는다. [Codex 공식 skill 안내](https://learn.chatgpt.com/docs/build-skills), [CLI 옵션](https://learn.chatgpt.com/docs/developer-commands?surface=cli)을 기준으로 로컬 help와 대조한다.

### D3. QA별 writer와 최종 commit gate

QA identity별 `{writerSessionId, writerEpoch, cleanupBarrier}`를 pool에서 관리한다. 세션 최초 생성은 검토 사본이며 사용자가 자동 반영 작성자를 명시한다. 양도·해제·QA 삭제·정리 미확인 시 epoch를 증가시킨다. 명시 양도는 살아 있는 이전 세션을 검토 사본으로 유지하고 기존 후보를 무효화한다. 이전 writer가 closing/cleanup_unknown이면 양도와 후보 적용을 차단하며 단순 UI 확인 버튼으로 해제하지 않는다. 새 writer 지정은 기존 파일을 현재 baseline으로 재해석하지 않고 변경 사본/충돌을 보존한 뒤 현재 원문과 동기화하거나 명시 후보 검토 후 새 epoch로 검증한다. 이번 단위에는 안전한 자동 복구를 발명하지 않고 진단/앱 종료 후 운영 확인을 안내한다.

후보 시작 ticket은 sessionId/projectId/qaId/canonical cwd/writerEpoch/document revision/Flow mutation revision/settings revision/Engine pin/file hash를 고정한다. 단순 node 선택/좌표 변경은 실행 문서 revision을 바꾸지 않는다. immutable snapshot.xml 또는 .json을 공개 Engine plan으로 검증한다. 최종 파일 재읽기까지 모든 await 후 ticket과 writer·cleanup·실행 중 여부를 다시 확인한 뒤 현재 활성 QA에만 반영한다. QA A→B→A도 activation generation으로 이전 후보를 버린다. 비활성 QA 파일은 후보 상태로 남고 돌아온 뒤 새 기준 검증을 수행한다.

다른 세션, invalid/partial/deleted/locked 파일, 양쪽 XML/JSON 수정, GUI/Flow dirty, 실행 중 변경은 마지막 정상 문서·그래프를 보존한다. 충돌 선택은 클릭 당시 GUI/Flow revision을 고정하고 GUI와 외부 원문 사본을 각각 보존한다. 새 편집이 생기면 명시 적용도 거절한다. undo 역시 적용 직후 revision에만 허용한다. 자동 반영은 draft 갱신이며 workspace 저장과 QA run을 수행하지 않는다.

현재 `externalRunBlocked`를 여러 VM이 덮는 위험을 피하도록 desktop에 keyed blocker 집계를 둔다. XML block/studio와 terminal은 자신의 사유만 갱신한다. 현재 QA writer의 unresolved conflict/cleanup만 관련 run을 막고 다른 QA/검토 사본의 상태가 무관한 실행을 막지 않는다. QA Engine busy와 PTY running은 별개다.

### D4. 도크와 반응형

기존 palette(canvas #1c1c1c/chrome #292929/panel #323232/text #e0e0e0/selection #8ea8bd), Segoe UI/Malgun Gothic, 4px 간격을 유지한다. AI는 하단 작업 도구이고 홈/캔버스가 중심이다. 세션 탭에 표시명·provider·QA·상태, 메뉴에 시작 경로와 작성 권한을 둔다. 같은 provider를 여러 번 열 수 있다.

기본 도크 280px 선호, 편집기 220px/터미널 160px를 가용 높이에 clamp한다. 낮은 높이에서 둘 다 확보할 수 없으면 기존 bounded 작업 패널 대안을 쓰고 문서 복귀 버튼을 제공한다. 최대화는 작업 영역 내부에 한정하고 복원 상태를 보존한다. split은 서로 다른 두 sessionId만 허용, 최소 pane 360px를 충족하지 못하면 단일 선택 세션으로 보이고 선호 split은 유지한다. 사이드패널 숨김은 접근 메뉴와 ExcludeFocus를 제공한다.

pointer resize와 focus 가능한 separator의 방향키/Home/End를 지원한다. 출력 수신은 focus/확대/scroll 위치를 강제하지 않는다. 메뉴 Escape와 세션 종료/Ctrl+C는 별개다. Ctrl+C/Delete가 terminal에 포커스될 때 canvas shortcut이 실행되지 않아야 한다. resize/tab/split/collapse에서도 editor keyed subtree와 세션별 controller를 보존한다. TerminalView layout 변경은 최초/현재 PTY rows/columns를 갱신하되 process를 다시 만들지 않는다. 스크롤 보존은 같은 출력 버퍼 위치를 기준으로 하며 줄 재배치 시 pixel 동일성을 주장하지 않는다.

### D5. Engine 작성 경계 이관

counterpart `qa-reusable-document-authoring`의 확정 alpha.9 / execution 0.3.0-draft.2 / authoring 0.1.0-draft.1을 관리 승인 후 별도 설치해 소비했다. templates list/show/create와 compose 공개 CLI를 새로운 authoring Service/Repository에서 호출한다. UI는 template 입력·asset/instance/link·position/undo를 소유하고 Engine은 namespace/reference rewriting/start-end 접합과 최종 Blueprint/XML/sourceMap을 소유한다. 승인 archive SHA256은 `09d0669d247c18cf88c7967156f801d15e2a871eb2e2b6d740ba245d7ca933e6`, execution bundle은 `b675005334c1345ef66b47e95eb8042ce45ade23941a1a0747ef3cfc485ea335`, authoring bundle은 `c38e5c1ce5caa0242cb6bdea81460252e6594f1a2e327388e0ef4ea4eda751a1`이다. 관리 승인/전수 확인은 상위 workspace `coordination/multi-terminal-implementation-20261112/checker-install-verification.json`, 공개 소비 증거는 본 저장소 `artifacts/multi-terminal/authoring/verification.json`에 있다.

확정 입력은 `schemaVersion: qa.composition/v1`과 assets(id,format,source,sha256), instances(id,assetId), links(from,to)다. sourceFile/프로젝트 DB/좌표는 Engine 의미 입력에서 제외한다. 성공 envelope는 `qa.authoredBlueprint/v1`의 blueprint/xml/두 snapshot hash/sourceMap/diagnostics이며 map은 `qa.compositionSourceMap/v1`이다. 현재 순차 외부 연결·원본 내부 DAG·target 동등성과 지원 제한은 유지한다. 같은 asset 중복 instance, 변수/selector/capture/branch/secretRef, namespace hash는 Engine 공개 fixtures의 검증을 소비하고 앱은 sourceMap의 전체 node 집합/원본 asset/node 및 두 snapshot을 검사한다. 기존 파일 경로는 UI sourceMap에 다시 붙인다. 작성 검증 실패의 `error.details.diagnostics`와 공통 CLI 실패의 `error.details: []`는 별도로 읽는다.

관리 승인 후 별도 앱용 runtime 디렉터리/asset을 alpha.9로 구성했고 기존 Dart 합성기는 삭제했다. alpha8 로컬 설치·이전 Release와 서버 alpha6는 보존한다. 구 Engine에는 compose/template 기능이 없다는 진단을 주며 새 경로에서 Dart 합성기로 몰래 우회하지 않는다. 실행은 기존 immutable snapshot validate/plan/run/cancel 경로를 유지한다. 구 workspace의 source/instances/layout은 저장 포맷 자동변환 없이 읽는다.

## Risks / Trade-offs

- 다중 세션 resource 사용 → 8개 상한, bounded buffers와 compiler queue, 실제 두 PTY 동시 출력·한쪽 종료 회귀.
- shell 사본은 보안 sandbox 아님 → 시작 cwd/CLI 정책 범위를 정확히 표시, 원본 비자동 덮기와 hash 검증.
- cleanup_unknown 이후 활동 여부 불명 → QA writer barrier와 epoch 유지, 성공 종료 합성 금지.
- Claude 미설치/외부 AI 신뢰·업데이트 화면 → missing/blocked와 adapter 구현/실제 모델 인수를 분리. native shell fixture를 실제 모델 작성 성공으로 보고하지 않음.
- 작성 계약 버전 불일치 → 관리 검증된 pin으로만 소비하며 구 runtime unsupported를 표시한다. 기본 서버 runtime은 자동 승격하지 않는다.

## Migration Plan

### 2026-11-13 VS Code 스타일 도크 반영

사용자가 목업의 앱 적용과 원격 push를 요청했다. 실제 `TerminalDock`의 표시만 목업에 맞춘다. #1e1e1e 배경, 44px 이상 패널 헤더, 파란 선택 밑줄과 평평한 세션 탭을 적용한다. 패널 열기와 세션 조작을 분리하고 우측 아이콘으로 추가·분할·확대·선택 종료·기타 메뉴를 제공한다. 이름 변경·Ctrl+C·종료 후 목록 제거는 기타 메뉴로 제공하며 도구에 툴팁과 접근성 이름을 유지한다. 선택 종료는 기존 close 액션이고 패널 접기는 세션을 종료하지 않는다.

실제 PTY spawn/input/output/cleanup, 세션별 controller·scroll·clipboard 소유, writer·QA·revision 보호와 준비 진단을 보존한다. 실제 실행을 모방하는 출력/문제/결과 탭을 추가하지 않는다. 기존 dock/adaptive/readiness 회귀와 analyzer/build를 가능한 환경에서 실행하고 결과와 환경 제한을 기록한다. 이번 PC의 SDK·런타임 설정과 이전 PC의 Release 인수를 구분한다.

구현은 세션 pool/순수 writer 규칙 → D08 도크와 실제 Windows 두 PTY → 검증된 Engine 작성 계약 소비 순서로 진행했다. 의미·sourceMap·직접 XML 실행 회귀를 유지한다. 별도 Release `artifacts/releases/desktop-multi-terminal-alpha9`에 full folder/소스·SDK·vendor·설정 SHA/launch와 캡처를 남긴다. rollback은 보존된 기존 Release 사용이며 사용자 workspace/자격증명을 되돌리거나 삭제하지 않는다. 완료한 목업 change와 관리 preservation 294파일은 수정하지 않는다.
