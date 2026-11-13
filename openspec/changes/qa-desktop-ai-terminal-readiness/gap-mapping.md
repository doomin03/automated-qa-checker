# 미완료와 후속 구현 대응

2026-11-12, Checker `main@3e73cd1f14b0aab658748e9c9b5c1be4a87794ad`. 제품 코드를 수정하기 전 읽기 조사다. 기존 dirty와 alpha.9 Release를 보존했다. `rg '^\s*- \[ \]' openspec/changes --glob tasks.md`에서 이 change 추가 전 미체크 15개를 확인했다. 체크박스 수는 전체 제품 roadmap의 모든 누락 수가 아니다.

## 기존 미체크 15개

| 기존 항목 | 현재 코드/후속 증거 | 분류와 남은 조건 |
| --- | --- | --- |
| interactive-terminal 1.2 수명 | TerminalService/Session/Pool, `multi-terminal/app-tests-final` PTY20세션·flood·부모 선종료, `spawn-close-final` | 후속 인수 연결 누락. scope dispose/close join/8세션은 새 D08 task1.1/1.3과 연결 가능 |
| 1.3 CLI·문맥·IME | TerminalProfileService, session contextText/prepareEnvironment, native-2 Codex update TUI | 부분 인수. 로그인/권한 화면·실제 IME 및 model 파일 편집은 미인수. 신규2.1/2.3 |
| 2.1 파일 동기화 | LiveDocumentRepository, Session.refresh; terminal_workspace tests, native-2 PowerShell scenario.json 수정 | 기능 구현. 실제 XML/JSON AI 편집과 삭제/잠금/원자 rename의 조건별 증거를 확정해야 전체 체크 가능 |
| 2.2 stale/충돌/undo | Session final read guards, writer/mode epoch; focused-7, terminal_workspace, multi_terminal tests | 후속 인수 연결 누락. 기존 부분 실패 기록 보존하고 조건별 테스트 연결 |
| 2.3 실행 분리 | 독립 compile repository/RunVM, native-2 active shells+template/composition4runs | 기능 구현. 기존 terminal 편집 문서→직접 실행 chain은 신규2.1에 정확히 연결; 합성 run으로 전부 대체 금지 |
| 3.1 작업 공간 | BlueprintWorkspace/XMLStudio/TerminalDock, planning-responsive native와 multi-terminal native8captures | 후속 구현/인수 연결 누락. 기존 직접 Flow와 파일 블록 모드 구별 |
| 3.2 gesture/focus | terminal_workspace 실제0.5줌 drag/핀 방향, 기존 파일 블록 gesture, dock focus tests | 일부 근거. terminal Delete/Ctrl+C의 실제 Windows canvas 격리/IME는 신규2.3로 보완 |
| 3.3 layout | CanvasLayoutVM/sidecar, 초기 read+move+undo 보존 회귀; 기존 service-consumption large-flow JSON | 구현/후속 증거 연결. 1000노드 debug 측정은 release FPS 보장 아님; 기존10/100/1000 측정의 실제 coverage를 먼저 확인 |
| 4.1 실제 AI 완주 | 과거 desktop-ai 비대화 생성 성공, 현 multi-terminal은 shell 파일수정/Codex시작까지만 | 실제 미인수. 비대화 생성/모의 셸 편집을 interactive 모델 성공으로 대체 금지. 신규2.1/2.2 |
| 4.2 전체 검증/Release | alpha.9 Release20files, source78/SDK209/vendor172/config14, verify/analyze/build exit0; 합산81PASS/1skip | 옛 alpha.8 특정 배포 계획이 후속 제품으로 대체됨. 존재하지 않는 옛 Release 완료 주장 대신 migration/evidence 연결 |
| 4.3 안내/마감 | docs/multi-terminal-quickstart 및 validation, 25strict | 후속 안내는 존재. 실제 AI 미인수 조건 남기고 legacy tasks 정합 필요 |
| auth-workflow 3.1 실제 조직 IdP | OIDC/JWKS/session/CSRF/RBAC, local provider fixture | 외부 앱 credentials/workspace/redirect/계정 필요. 코드 없는 상태와 구별 |
| platform-services 2.2 OIDC/RBAC | qa-auth-workflow가 구현·fixture 인수 소유 | 상위 task가 구현과 외부 인수를 혼합. 세부 근거/실계정 잔여를 분리해야 함 |
| platform-services 4.1 sync/archive | P3/P4 구현 완료 근거 있으나 위 외부 인수 잔여 | 행정 마감/상위 조건 미충족. 자동 archive 금지 |
| flow-editor 3.1 sync/archive | P2 구현 완료 | 행정 마감. 원본 조건과 현재 specs drift 확인 뒤 별도 승인 순서 |

## 확인된 현재 기능 갭

`terminal_dock.dart::_add`는 매번 빈 경로 controller로 시작하며 진단 상태를 내부 영어 값으로 표시한다. 기존 실행 파일 selector, 경로 기억, 설치 안내/복구는 없다. `TerminalProfileService._find`는 PATH와 Codex 고정 후보를 검색하지만 Claude의 사용자 `.local/bin` 비PATH 설치는 놓칠 수 있다. `inspect`는 로그인/모델과 분리된 executable probe로 적절하다.

`LiveDocumentRepository.prepareEnvironment`는 `.agents/skills/qa-authoring/SKILL.md` 또는 `.claude/skills/qa-authoring/SKILL.md`와 contract/example/context를 이미 준비한다. manifest는 `providerDiscoveryVerified:false`다. 가이드 파일 준비 자체를 다시 구현할 필요는 없다. 세션 메뉴에서 준비 파일 확인/호출 안내·문맥 전달 접근을 보완하고 실제 발견/활용은 별도 인수한다.

## 문서 상태 갭

README는 최신을 project-home alpha.8, AGENTS와 system-design도 현재 Desktop alpha.8로 설명한다. 현재 앱 pin은 alpha.9이며 이전 문서 기록과 구분한 머리말/링크 정합이 필요하다. 옛 validation-terminal-blueprint는 당시 부분 인수 기록으로 보존하고 최신 대응 링크만 추가한다. 완료된 D08 change와 목업을 미완료로 되돌리지 않는다.

## 체크박스 밖 실제 roadmap 누락

`docs/planning/roadmap.md`, `design/mockups/product-planning/requirements.js`가 명시하는 기능 중 조직/팀/역할/프로젝트 CRUD, 개인 QA/Suite Assignment inbox, 검수 반려·게시 폐기, 전체 Agent/기기 재고 UI, TC 전체 metadata 폼, Desktop 전체 Suite 실행, Recorder/범용 코드 export는 별도 구현 범위다. 실제 모바일/TV/whitebox 및 외부 알림은 Engine 계약/기기·계정 의존도 구분한다. 이 신규 readiness change가 모두를 구현한다고 하지 않는다.

## 추천 순서

1. 이 change: 기존 terminal 재사용으로 provider 경로/준비 복구와 실제 interactive edit→GUI→run 인수. 서버/Engine 변경 없이 진행 가능.
2. 다른 PC 배포: 현재 receipt는 개발 PC 절대 경로/Node/Chromium cache에 의존한다. portable 또는 명시 installer·runtime/browser 준비·fresh-user smoke를 별도 change로 설계. 원본 alpha.9 package/Release 보존.
3. 공용 runtime 정합: 서버 alpha.6와 앱 alpha.9 차이 때문에 기본 공유가 차단되는 것은 현재 올바른 동작이다. 관리 승인된 독립 server/Agent compatibility 인수 후 새 설정으로 승격해야 하며 앱에서 검사 우회 금지.
4. 사용자 여정 누락: TC metadata/개인 배정·검수 lifecycle/CRUD와 Suite 전체 실행을 서버 DTO·권한·불변 version 계약부터 분할한다. 외부 provider·기기 없이는 가능한 코드/fixture를 진행하되 실환경 성공은 미완료로 남긴다.

조사 단계에서 설치/전역 설정/credential 내용 열람/모델 요청/제품 코드 변경은 수행하지 않았다. 신규 제품 apply는 관리 범위 검토 이후다.

## 2026-11-13 후속 구현·인수 연결

위 표는 11월12일 구현 전 조사 기록이다. 이후 `qa-desktop-ai-terminal-readiness`가 실행 파일 선택/기억/진단과 가이드 확인을 구현했고, `qa-desktop-portable-runtime`이 alpha.10/Node/Chromium 전체 배포 및 실제 상대경로 실행을 인수했다. 최신 근거는 `docs/validation-desktop-readiness-portable.md`다. 서버/Agent alpha.10은 별도 `qa-server-agent-alpha10-runtime` 소유이며, 개인 배정/Registry lifecycle은 별도 명세에 남는다.

옛 interactive-terminal의 실제 AI XML/JSON 수정 및 한글 OS IME를 완료로 바꾸지 않는다. Codex 복구 시험은 사용량 제한으로 파일 수정 없이 종료했고 Claude는 미설치다. 문맥 파일 준비와 CLI 탐지·실제 skill 활용은 구분한다. 초기에 실패한 UI/packaging 기록은 원본으로 보존했고 후속 집중 복구 결과와 연결했다. 새로운 배포가 과거 부분 인수 change의 모든 조건을 소급 충족한다고 표시하지 않는다.
