# 2026-11-10 실제 Desktop 프로젝트·QA·AI 작성

새 앱 전용 alpha.8과 프로젝트/QA 저장·Codex 후보 검증/적용·실제 Windows 실행을 인수했다. [명령·회귀·제약·Release hash](validation-desktop-ai.md), [내일 실행 순서](desktop-ai-quickstart.md)를 따른다. 이전 alpha.6 서버/Agent/Release 및 아래 격리 인수 기록은 보존한다.

# 2026-11-07 Engine 모듈 분리 소비 호환

alpha.8/draft.2 candidate-1을 별도 설치해 공개 exports·타입·CLI/XML 및 실제 Flutter Service 호환을 인수했다. [소비 경계·실행 명령](architecture/engine-refactor-compatibility.md)을 따른다. 제품 소스와 기본 alpha.6 설치/Release/서버/Agent 설정은 변경하지 않았다.

- 격리 설치148파일 목록·SHA가 Engine candidate verification과 일치했다. tgz SHA `4215662445780eeecd016ad6acf2a7b2c5e16b9a4e62cf8ae88e30ee0452e77f`, bundle SHA `638d48f182d12819ebd167d42457c7dceaa90928abb38c32a4867e3c94b10763`.
- 공개 root/playwright/appium import·XML API roundtrip PASS. 실제 tsc 정상 consumer exit0, 잘못된 호출 exit2. 새 모듈 분리를 private import로 우회하지 않았다.
- `node scripts/flutter.mjs test test/engine_candidate_service_test.dart test/engine_service_integration_test.dart --concurrency=1 --reporter expanded`: 주입 후보2개 테스트/7실행 PASS,59초. JSON/XML PASS·의도한 FAIL·지연 assertion·1000node visited999/unvisited997 및 paused-cancel 실제 result107ms를 확인했다. `node scripts/flutter.mjs analyze`:79.1초 PASS.
- 로그는 `artifacts/engine-refactor/alpha8-service-tests.log`, `alpha8-analyze.log`이며 세부 결과/최종 인수는 `artifacts/engine-refactor/0.1.0-alpha.8/4215662445780eeecd016ad6acf2a7b2c5e16b9a4e62cf8ae88e30ee0452e77f/acceptance.json`에 있다. 기본alpha.6설치74·Release14·제품43소스 및 alpha.7설치·증거128파일을 보존한다. 이전 service-audit acceptance를 덮지 않았다.
- `qa-engine-refactor-compatibility`는5/5 완료다. 최종 OpenSpec strict15개/foundation/diff를 통과했고 Windows 재빌드·운영 승격·commit/push는 하지 않았다. 외부 Slack·모바일 실기기·운영 부하 인수는 이번 호환 검사로 완료 처리하지 않는다.

# 2026-11-07 Engine 소비 안정성 체크포인트

Flutter CLI의 UI pause와 OS pipe drain을 분리하고 출력 누계·명령/실행 전체기한·정상 취소 grace를 적용했다. 40/1000node Flow의 잘린 마지막 노드에 접근할 수 있도록 canvas 범위를 보완했다. [운영 정책·재현·제약](architecture/engine-service-readiness.md)을 따른다. 기본 Engine pin은 alpha.6이며 alpha.7 candidate-3는 별도 설치로 소비 인수를 완료했다.

- `node scripts/flutter.mjs test test/cli_process_test.dart test/large_flow_view_test.dart test/flow_editor_test.dart test/engine_bridge_test.dart test/engine_ui_test.dart test/engine_service_integration_test.dart test/workbench_state_test.dart --concurrency=1 --reporter expanded`: focused20개 PASS,2분23초. `artifacts/service-audit/flutter-regression.log`.
- `node scripts/flutter.mjs analyze`: PASS,6.3초. `artifacts/service-audit/flutter-analyze.log`.
- `node --test apps/server/test/engine-consumption.test.mjs`: 실제 process의 큰 UTF8 응답·stderr 한도·잘못된 JSON·15초 timeout과 child 종료1개 PASS(4경계). `artifacts/service-audit/server-regression.json`. 서버 제품 코드는 변경하지 않았다.
- 마지막 debug widget1000node build3393ms/스크롤·선택1216ms,40node1101/318ms. `artifacts/service-audit/large-flow-view.json`. 원문·좌표·이동 undo 보존과 마지막 노드 접근을 검증했으며 release 성능 보증이 아니다.
- 공개 alpha.6 paused-cancel 마지막 관측688ms에 실제 disk cancelled result가 생성됐다. `artifacts/service-audit/public-0.1.0-alpha.6/paused-cancel.json`. UI paused 중 결과 보존은 실제 CLI 근거이며 강제종료 fixture의 cleanup unknown과 구분한다.
- 기존 배포 Release14파일·HTTP/Agent/Engine pin의 bytes/hash 보존 및 scoped source 변경은 `artifacts/service-audit/preservation.json`에 기록한다. 이번 소스 보완은 기존 실행 파일에 반영된 것으로 주장하지 않는다. Windows 재빌드나 무관한 전체 웹/서버 회귀는 반복하지 않았다.
- 이 체크포인트의 OpenSpec strict14개, foundation83 Markdown/114 로컬 링크, 경계 회귀7개와 `git diff --check`가 통과했다. `qa-engine-service-consumption`의 실제 완료4/6만 체크했고 새 Engine 후보 소비와 최종 보고는 남겼다.

이후 관리 승인 candidate-3를 별도 설치해 실제 Service6실행을2개 테스트/1분1초에 인수했다. PASS·의도한 FAIL·350ms 지연 단언·1000node 방문999/미방문997 양쪽 결과 목록·UI pause 중 실제 취소 결과702ms를 확인했다. `artifacts/service-audit/public-0.1.0-alpha.7/service-candidate.json`, `paused-cancel.json`, `artifacts/service-audit/flutter-candidate3.log`를 따른다. 새 테스트를 포함한 analyze도6.1초 PASS했다. 버전은 alpha.7/contract0.3.0-draft.2, tgz SHA는 `0199b719baaf2f41c46b6e6cb07dc8ddd80464923c639ed724cae612f31c80c3`, bundle SHA는 `36ceac45564c61f5f0b442136488838299a56846992b65ce360a5ea5c4dde7fe`다.

격리 후보79파일과 기존alpha.6설치74파일/Release14파일을 확인했다. 기본 pin·앱 assets·서버/Agent 설정은 alpha.6이고 새 Windows 배포를 만들지 않았다. 완료 범위는 소스 보완과 공개 후보 소비 인수이며 후속 운영 승격은 별도다. 마지막 strict14개/foundation83문서·114링크/diff 검사를 통과한 뒤 tasks6/6을 완료했다. 종합 근거는 `artifacts/service-audit/acceptance.json`이다.

# 2026-10-31 Desktop Blueprint 목업 (현재 디자인 검토)

[새 목업](../design/mockups/desktop/blueprint-workspace/index.html)은 프로젝트 목록 → QA 목록 → 차콜 Blueprint 작업 공간을 제공한다. 그래프/XML/선택 속성은 하나의 문서를 사용하며, 네 AI 편집 범위는 예시 제안 → 미리보기 → 적용/취소·되돌리기로 연결한다. 공급자 키 입력은 메모리에서만 사용하는 연결 시연이며 실제 AI 요청·인증·Engine 실행이 아니다. 실제 Flutter 스타일 이식은 수행하지 않았다.

- `node design/mockups/desktop/blueprint-workspace/verify.mjs`: Chromium 상호작용 30검사 PASS, 최종 캡처14개. 프로젝트/QA 탐색·팬/줌·XML 선택, 네 범위 apply/undo, stale 제안 거절, 미지원 원문·QA별 미반영 입력 보존, snapshot 진행/중단/환경 오류, 키 비영속을 확인했다. 외부 HTTP 요청·영속 저장 API 호출·페이지 오류는 0이다.
- 초기 문서와 네 범위 변경 XML 5개를 설치된 공개 Engine alpha.6 CLI의 `validate`·`plan`으로 각각 검사해 10회 PASS했다. CLI `run` 호출은 0이다. [검증 JSON](../design/mockups/desktop/blueprint-workspace/verification.json)과 같은 폴더의 `evidence`에 변경 XML을 보존한다.
- 최초 1024 캡처에서는 숨긴 탐색 패널 뒤 grid 자동 배치가 중앙/우측 패널을 겹치게 했다. 열·행 위치를 고정하고 실제 bounding box 비중첩·캔버스 최소 폭·전체 node 가시성·패널 접기/펼치기 회귀를 추가했다. 수정된 `10-compact.png`와 `10-compact-expanded.png`는 이 재검증 결과다. 최초 페이지 overflow 검사만으로 화면 인수를 완료한 것으로 처리하지 않는다.
- 이전 목업 원문·캡처19파일의 SHA-256 일치를 확인했다. 관리 독립 대조에서 Flutter 제품 source42파일·Release14파일과 Engine/HTTP 계약 pin의 drift는 0이다. 제품이 변경되지 않아 Flutter 테스트·Windows 빌드를 반복하지 않았다.
- 관리 최종 시각 검수 후 `qa-desktop-blueprint-workspace` 9/9를 완료했다. 전체 OpenSpec strict13개, foundation78 Markdown/111 로컬 링크, `git diff --check`가 통과했다. commit/push는 수행하지 않았다.

# 2026-10-31 Provider/MVVM 작업 공간 리팩터 (현재 제품)

최신 실행 파일은 `artifacts/releases/alpha6-mvvm/Release/automated_qa_desktop.exe`다. RunPanel을 상위 Stateless 조합 View로 나누고 실행 설정·진단 플랫폼은 Provider VM, 문서 정본은 편집 VM, 기능 간 작업 순서는 Workbench VM으로 이동했다. UI controller/selection/IME와 dialog는 View 수명에 남겼다. 앱에서 만든 공유 자원은 composition root가 정확히 한 번 종료하고 외부 주입 자원은 borrowed로 취급한다. [구조와 소유권](architecture/flutter-mvvm.md), [OpenSpec 인수](../openspec/changes/qa-desktop-mvvm-boundaries/tasks.md)를 따른다.

- `node scripts/flutter.mjs analyze`: 오류 없음.
- `node scripts/flutter.mjs test --concurrency=1`: 최종 고정 source 29개 PASS, 6분6초. `artifacts/flutter-mvvm-tests.log`. 기존 실제 CLI validate/run/PASS/FAIL/cancel, 디자인 결과·PNG, 조직 provider fixture, Registry·Suite 수신/진행 게시/재연결과 새 재마운트·IME·ABA·stale 오류·dispose 소유권 회귀를 포함한다.
- `node scripts/flutter-integration.mjs`: 실제 Windows QaApp에서 자체 Nest 연결→중단→transport 오류→재시작 재시도 1개 PASS. `artifacts/flutter-mvvm-windows-integration.log`, `artifacts/flutter-mvvm-windows-health.json`. 실제 Engine 실행은 이 native 검사와 별도의 Provider/CLI 회귀에서 인수한다.
- `node scripts/flutter.mjs build windows --release`: 52초 PASS. 새 Release 전체14파일을 별도 경로로 복사하고 bytes/hash를 대조했다. manifest `artifacts/flutter-release-mvvm.json`, hash `9b0c659935deb5627926827adcc3f01b79f684a93e1b340c7d680437740998f1`, AOT `data/app.so` hash `cff750c4a5f3b2a638af9b2a942a2080904be2657020e008020a9194ba724108`.
- `artifacts/flutter-desktop-launch-mvvm.json`: 직접 시작한 별도 hidden process의 `FLUTTER_RUNNER_WIN32_WINDOW` 초기화 PASS 후 그 프로세스만 종료했다. 이 smoke는 전체 화면 조작 인수로 확대하지 않는다. 요청 당시 PID22828은 이번 확인 시 조회되지 않았으며 해당 PID를 종료하지 않았다. 이전 `artifacts/releases/alpha6/Release`의13파일은 기존 manifest와 모두 일치한다.
- Engine alpha.6/runtime package·bundle·HTTP·Agent 계약 hash 불변과 Dart 제품 source inventory는 `artifacts/flutter-mvvm-source.json`에 기록했다. 의존성/DSL/HTTP를 변경하지 않았다.
- 마지막 OpenSpec strict12개, foundation74 Markdown/109 로컬 링크, 기존 경계7개와 diff check를 통과했다. 최종 인수 요약은 `artifacts/flutter-mvvm-verification.json`이며 제품 source42파일의 빌드 후 drift는0이다. 이번 MVVM7/7과 목업4/4는 완료했고 기존 외부 Slack 환경2항목·행정 sync/archive2항목은 그대로 남긴다.

중간 회귀에서는 이전 View 타입/단독 DI를 가정한 테스트와 접힌 진단 패널 조회를 수정했다. 실행 중 반영된 마지막 상태 보정의 컴파일 시점이 섞인 실패는 `flutter-mvvm-tests-attempt-2.log`에 보존했다. 이후 source를 고정하고 위 전체29개를 다시 실행해 PASS했다. 이번 인수는 기존 설치에서의 리팩터 회귀이며 아래의 별도 fresh 설치 기록을 대체하지 않는다.

별도 [UX 목업](../design/mockups/desktop/README.md)은 OpenSpec4/4, Chromium 상호작용18개·캡처12개·외부 HTTP 요청0을 인수했다. 예시 데이터이며 실제 로그인/Engine 실행/공유 전송이나 Flutter 디자인 적용을 뜻하지 않는다.

# 2026-10-31 alpha.6 및 Desktop 보완 (이전 인수)

최종 사용자 실행 경로는 `C:/workspace/QA/automated-qa-checker/artifacts/releases/alpha6/Release/automated_qa_desktop.exe`다. 같은 폴더의 DLL/data를 함께 보존한다. 새 설치 위치 `.local/fresh-1793430224589`에서 생성한 Release 전체13파일을 복사해 bytes/hash 일치를 확인했으며 이 안정 경로에서도 hidden native 창 초기화가 통과했다. manifest SHA256 `8e5ccfefef2ad9b38685a09affddb1530005ae08fcc8d6f5f6187aae07d5901d`, `data/app.so` SHA256 `202f337b8b67f23dbf814e931ef0cfb7493b34e98001bf99540229863ad0c06a`. `artifacts/flutter-release-stable.json`과 `flutter-desktop-launch-stable.json`이 근거다. 기존 `apps/app/build`의 이전 빌드와 혼동하지 않는다.

새 의존성 설치에서 frozen JS/Flutter/Dart 설치, 고정 Engine·Chromium 설치, generator checksum, SDK 재생성, 실제 dev/startup, 서버37/TS9/모델7/경계7, strict10, 실제 웹 관찰·라우팅·XML·공유·조직·업무·Suite, 계약 drift/호환성/실패전파, 양 SDK 실제 HTTP, Flutter analyze/25tests, Windows native integration 및 Release build를 통과했다. 마지막 `verify:all`의 native smoke는 P/Invoke generic delegate 문제로 exit1이었으며 `artifacts/fresh-attempt-2-smoke-failure.json`에 원래 실패를 보존했다. 검증 도구의 전용 delegate로 수정해 해당 마지막 단계만 재실행해 exit0을 확인했다. 전체 명령을 재실행하거나 최초 exit1을 PASS로 바꾸지 않았다. 누적 단계 인수 근거는 `artifacts/fresh-recovery-verification.json`이다.

source inventory666개에서 변경은 `scripts/smoke-windows-release.ps1` 검증 도구 한 개뿐이고 제품/SDK 및 나머지 source의 SHA drift는 0이었다. 마지막 문서·OpenSpec 완료표 정정은 별도 문서 delta artifact로 남기며 검증 당시 snapshot을 바꾸지 않는다. 첫 시도 Windows PATH 환경 키 처리 실패 역시 별도 `fresh-attempt-1-path-failure.json`에 보존한다. 실제 Slack 계정·Android/iOS 기기·원격 CI/운영 배포 인수는 완료로 표시하지 않는다.

완료표의 남은 범위를 구분한다. `qa-auth-workflow 3.1`과 `qa-platform-services 2.2`는 같은 실제 Slack 계정·workspace·redirect 환경 인수가 남아 있으며 로그인 코드·local RS256 provider·RBAC·Desktop callback은 검증했다. `qa-flow-editor 3.1`, `qa-platform-services 4.1`은 기준 spec sync/archive의 행정 후속이다. 모바일 실기기 인수는 Engine의 별도 미완료 항목이다. Recorder/TV·whitebox·Figma 직접 API, 공유 PNG/font 자산 패키지 게시 UI, Desktop 전체 Suite 일괄 실행은 이번 인수 기능으로 표시하지 않는다.

고정 runtime은 `0.1.0-alpha.6`, 실행 contract는 `0.3.0-draft.1`이다. tgz SHA256 `33dbcacea025fb98a52fb0411af05cb113bc85e47e84a98463912b6aace1acef`, bundle SHA256 `1f880001f8c653e51527ee9f92c5728aa7517b61adfb6c158d218a4a0542ed8d`. Agent HTTP artifact는 `8c25e3c853f3b8d24003464d2ddc55a20675b7ac3f741a46c238a50ce4149490`이며 final 설치와 관리 독립 교차 확인을 통과했다.

`node scripts/flutter.mjs test test/capability_ui_test.dart test/shared_ui_test.dart --concurrency=1` 2PASS. 실제 public CLI/Provider 화면에서 설치 Chromium과 native 설정/미연결을 구분했다. 실제 Nest에 발행한 Suite의 두 case를 순서대로 수신·고정하고 각 Registry version provenance를 보존했다. 수신/고정만으로 실행한 횟수는 0이다. 연결교체 중 늦은 수신은 거절하고 기존 pin을 유지했다. 증거는 `artifacts/flutter-shared-ui/verification.json`이며 Desktop 전체 Suite 일괄 실행을 뜻하지 않는다. 전체 Suite 순차 실행은 독립 Agent 실제 서버 matrix의 별도 증거다.

최종 HTTP reviewed local baseline은 `f705acfa8a30d4c89ec8f588a2d85bd49a837ee1084d93fa273a725f3a09ef90`이다. 앞서 수용한 `21d69689…` 원문을 보존했으며 remote baseline 검증을 주장하지 않는다. TS9/Dart7, 인코딩/nullable/unknown/error 실제 HTTP fixture와 read-only codegen drift를 통과했다. `artifacts/web-route-verification.json`은 production404/deep-link 및 StrictMode·문서 교체·구독 cleanup, `artifacts/windows-health-integration.json`은 실제 Windows QaApp에서 자체 Nest 종료·재시작·재시도 증거다.

새 설치 인수는 `node scripts/verify-fresh.mjs <고정 alpha.6 tgz>`와 `artifacts/fresh-install-verification.json`의 실제 결과로 판정한다. 이 스크립트는 source inventory와 SHA를 보존하고 node_modules/build를 복사하지 않는다. OS·Flutter/C++ toolchain 및 checksum으로 확인하는 generator download cache, Playwright browser cache는 공유하므로 새 OS 검증이 아니다. 최종 release의 전체 파일/app.so hash는 해당 빌드의 `flutter-release-current.json`으로 판정하며 native runner exe hash만으로 Dart 변경 여부를 판단하지 않는다.

# 2026-10-31 alpha.5 제품 인수 (이전 기록)

고정 Engine runtime0.1.0-alpha.5 / contract0.3.0-draft.1. tgz SHA256 `1fdd43ca48df3b9377202eb1640d3c61e1fc0c65acc4a8847d4d28e95a2a9bb7`, 공개 bundle SHA256 `b183b90e0a8d93ab531b10ca409a4e657003fd85812a131f97479695283a5370`. alpha.4 늦은 screenshot 경쟁 수정은 Engine 관리 probe 인수 후 소비했다.

- 디자인/UX 실제 CLI: 기준 PNG·수치 입력, 비교 PASS/의도적 FAIL과 diff, input/focus/history-back/합성 overlay, profile/hash mismatch, 비실행 작성, 원본 기준 불변 PASS. `artifacts/flutter-design/verification.json`. 실제 OS 키보드 검증은 아니다.
- Flutter Provider 실제 사용자 경로: 기준 입력→연결 XML→검증·실행→check report 및 검증된 PNG Image.memory 표출 PASS. `artifacts/flutter-design-ui/ui-verification.json`. 일반 step screenshot도 같은 bytes 검증/화면 경로를 사용한다.
- 작성 문서: 공개 expand→원본/대응표 보관·재전개hash/planhash 대조→반복3회→captureText/input valueRef/assertValue expectedRef PASS, count101거부·편집 후 회차label무효. `artifacts/flutter-authoring/verification.json`.
- 모바일: 실제 설치 CLI가 별도 Appium config로 local W3C fixture에 접속·session cleanup PASS. `artifacts/flutter-appium/verification.json`. 실제 Android/iOS 기기 인수는 미완료다.
- 공용 전달: 실제 Nest Registry→Flutter 버전/hash/pin/offline 수신→명시 CLI 실행→events/result/PNG 게시 PASS. 서버 중단 중 두 번째 실행도 passed 유지, 재시작 후 durable report 복구 PASS. 일치 snapshot만 versionId 연계하고 편집 후 연결해제, 잘못된 connection candidate/다른서버cache 거부 및 동의 초기화 PASS. `artifacts/flutter-shared/verification.json`.
- 실제 Flutter 수신 폼 및 자동실행 없음 PASS: `artifacts/flutter-shared-ui/verification.json`. 실제 웹 작성/독립검수/발행/핀→인증 cursor polling 중지·재연결→실행graph/result→검증 PNG 표시 PASS: `artifacts/shared-web-verification.json`.
- 서버13 tests, TS SDK6 tests, Dart SDK5 tests/analyze, 양SDK 실제동일Nest통합, generator/drift는 apps/server/VALIDATION.md. local/test identity 인수이며 실제 OIDC·Agent·예약·Suite 전체 완료가 아니다.

실행 명령: `corepack pnpm verify`, `corepack pnpm test:xml`, `corepack pnpm contract:platform-integration`, `corepack pnpm app:test`, `corepack pnpm test:shared-ui`, `corepack pnpm app:build`. verify는 foundation/boundaries6/models7/server13/SDK6/OpenSpec8/build/기존실제browser PASS했다. Flutter analyze clean. 최종 동일 source 전체 Flutter 21 tests는 6분에 PASS했다. 이후 조직 인증 UI 변경은 별도 targeted 검증하며 마지막 전체 인수를 다시 수행한다. 최초 순차 검사는 중간 관리 리뷰 반영으로 compiler cache가 이전 SharedRepository를 사용하여 해당 테스트 load가 실패했고 나머지20개 PASS, 최신 Shared2개 targeted 재검증은 PASS했다.

Windows release build84.1초 PASS. 실제 AOT `data/app.so` SHA256 `ab2cf6f5e765fa84be7c557e027cccdd5b2d3269e09d732bb2a9f8d6528a456c`. 전체 Release manifest `artifacts/flutter-release-alpha5.json` hash `f67eb15f6d5a16a64be454290e172e888ebc67f44bc6c67ca619e43ba2deebbe`; embedded runtime asset hash `a7abce57fe0ed52fd51b048162032954aab4df5155bd85a784d415cfcded9b46`. native runner exe hash는 기존과 동일할 수 있으며 제품변경 증명은 AOT/asset hash로 한다. 숨김 실행 process 및 FLUTTER_RUNNER_WIN32_WINDOW 초기화 확인: `artifacts/flutter-desktop-launch-alpha5.json`. 이 smoke는 실제 OS UI 조작 인수가 아니다.

재현 흐름은 [로컬 기능 데모](local-demo.md), [공유 설계](architecture/shared-scenarios.md)를 따른다. auth/workflow/Agent 후속 UI 변경 후에는 다시 build하여 새 hash를 기록한다.

# Blueprint UI 검증

## 2026-10-31 로컬 CLI·블록·웹 XML·서버 기반 인수

현재 main / 작업 시작 HEAD 4f97e920a399d4a5434ab1ecbe44c4d879d397a4에서 구현했다. 이전 날짜의 shell/미연결 기록은 당시 이력이다.

- Engine alpha.3 / contract draft.1 공개 package SHA-256 ea8ec57eb40d362698f3fb47bc7a583848cd3cde3e1806483b2d0a2c6ba13285, bundle 84522812b8192de6e0d37bab32a6872d4cbb4573bef9da8a491bbf7608fe09aa를 소비한다. runtimeIntegrationEnabled=true는 Desktop 명시 CLI 실행만 뜻하며 웹은 XML 전달·이벤트 관찰이다.
- Flutter analyze 통과, 전체 기존 13 tests + 새 기본폼 widget 1 test 통과. 실제 공개 CLI PASS/FAIL/cancel, 비실행 validate/plan, 변조 snapshot·잘못된 버전·준비 중 취소·결과 누락/이벤트 모순, 파일 IO, Flow branch/undo/redo/XML roundtrip을 포함한다. 추가로 engine_ui_test.dart를 재실행하여 실제 XML 입력→검증→실행→결과와 graph의 동일 snapshot passed 표시·편집 불일치 차단·읽기 전용 snapshot 복귀를 통과했다.
- artifacts/flutter-engine/verification.json은 실제 PASS/FAIL/cancel report 경로를, artifacts/flutter-ui-engine/ui-verification.json은 Provider UI→실제 CLI PASS를 기록한다. 실행별 result/events/PNG bytes와 hash를 서비스 및 관리 에이전트가 대조했다.
- flutter build windows --release 통과. apps/app/build/windows/x64/runner/Release/automated_qa_desktop.exe SHA-256 cd167334a550cf744571b90749e504966fa659156d3ff2cf45ef77c058267c7c. 같은 Release DLL/data를 유지한다. Hidden 실행 후 PID의 FLUTTER_RUNNER_WIN32_WINDOW 초기화를 확인하고 종료했다. artifacts/flutter-desktop-launch.json은 native 시작 smoke이며 OS UI 직접 조작 E2E가 아니다. 실제 UI 동작과 CLI는 위 Provider widget 경로에서 검증했다.
- pnpm run verify 통과: foundation 47문서/79링크, boundary6, Blueprint7, Nest5, TS SDK4, strict7, JS build 및 실제 browser UI. 비동기 file.text 완료 전 검사하던 UI 테스트를 실제 not_started 상태 대기로 수정한 뒤 통과했다.
- node --test tests/ui.test.mjs tests/xml.test.mjs 2/2 통과: 실제 편집 XML 다운로드→공개 CLI import/export/plan 일치, 자동 실행 없음, 실제 Nest cross-origin health 성공/서버 중단 오류, 이벤트 replay/file follow.
- 서버/생성 SDK 세부 증거는 [서버 검증](../apps/server/VALIDATION.md). offline OpenAPI/generator/read-only drift, 양 SDK 실제 HTTP는 서버 담당 검증과 관리 독립 HTTP 확인을 공유한다. 최초 수용된 로컬 health OpenAPI SHA-256은 3880a44b997188d5bc41e27a1719c3e4f6a8c6eb6817cecc059e870cecda651c이며 원격 base branch 계약은 없다.
- root Flutter wrapper의 analyze/--version 전달 통과. 전체 verify:all/원격 CI, 새 환경 전체재현, 확대 SDK fixture와 breaking gate는 아직 별도 미완료다.
- handoff 1.1/1.2/2.1/2.2/3.2/3.3/3.4/4.1은 이번 증거로 인수한다. flow-editor 2.2/2.3/2.5/2.6은 같은 pin/graph/CLI 증거를 공유한다. capability 검사는 구현했으나 device picker 2.4는 아직 남는다. 디자인 UX/Appium의 신규 공개 계약, 실제 모바일 기기, 서버 인증/Registry/진행 자동 수신/예약은 완료로 표시하지 않는다.

재현은 [로컬 엔진 연결](architecture/local-engine.md)을 따른다. Flutter SDK 경로는 C:/workspace/QA/.tools/flutter-3.47.5, Dart3.13.4, provider6.1.5+1이다. 앱 폴더에서 flutter analyze, flutter test --concurrency=1, flutter build windows --release를 실행하며 root에서는 node scripts/flutter.mjs로 같은 인자를 전달할 수 있다. commit/push는 수행하지 않았다.



## 2026-10-29 Flutter MVVM/Provider shell 검증

- 사용자 후속 요청으로 원본 모노레포 D6/flutter-app-shell와 관련 changes를 MVVM/Provider로 먼저 정합하고 OpenSpec strict 6/6 통과 후 구현했다.
- Flutter3.47.5, revision `6a19cca56475dbfba1478ee68d7bd0c2ef891da1`, Dart3.13.4, provider6.1.5+1 exact, pubspec.lock. 로컬 SDK `C:/workspace/QA/.tools/flutter-3.47.5`를 사용했고 글로벌 PATH/config를 바꾸지 않았다.
- doctor에서 Windows/Visual Studio Community2026 18.8.0/Windows SDK10.0.26100.0 확인. Android SDK 미설치와 로컬 git tag channel/PATH 경고는 Windows 대상과 구분했다.
- `flutter pub get --enforce-lockfile` 성공, 최종 `flutter analyze` No issues, `flutter test` 7/7 통과. 실제 UTF-8 파일 round trip·1MiB 제한·잘못된 UTF-8·없는 파일·Windows 잠긴 기존 파일 보존/임시정리, immutable/dirty/error/busy 상태, dispose 후 완료, Provider widget 상태·수명 검증을 포함한다.
- 최종 `flutter build windows --release` 성공. 결과 `apps/app/build/windows/x64/runner/Release/automated_qa_desktop.exe` 및 같은 폴더 DLL/data.
- 서버/API/엔진을 연결하지 않고 release exe를 Hidden으로 실행해 process input-idle과 `FLUTTER_RUNNER_WIN32_WINDOW` 생성을 확인한 뒤 테스트 프로세스를 종료했다. 근거 `artifacts/flutter-desktop-launch.json`. 숨김 창은 .NET MainWindowHandle에 나타나지 않아 Win32 EnumWindows로 PID별 창을 확인했다. 이 smoke는 native 창 초기화 검사이며 OS UI를 직접 조작한 E2E는 아니다. 화면 편집/저장 상태 연동은 Flutter widget test로 검증했다.
- 파일 read는 maxBytes+1로 제한, save는 같은 디렉터리 temp flush→rename이다. 저장 실패를 테스트 실행 결과로 표현하지 않는다.
- OpenSpec 모노레포6.1, qa-flow-editor2.1, handoff3.1은 동일 shell 증거를 공유한다. 엔진 compile/run·시각적 block builder·HTTP SDK/server·handoff 제품 build3.4는 미완료다. Checker engine pin은 alpha.1 그대로다.
- 최종 문서 OpenSpec strict6/6 및 foundation42Markdown/70local links 통과. JS 제품 변경은 이번 범위가 아니며 기존 웹 XML 미검증 변경을 인수하지 않았다. 원격 CI·commit/push는 수행하지 않았다.

구조와 재현 명령은 [Flutter MVVM 안내](architecture/flutter-mvvm.md)를 따른다.

## 2026-10-29 원본 모노레포 OpenSpec 이관 검증

- 원본 local origin/feature `325ca653fe213eb02b1b1e6e4fd7edc147f71721`의 change 10파일을 읽고 Checker에 QA 이관본을 작성했다. 후속 `monorepo-setup` `2e515c0df05fd592ec18e9e7388bb34eb3e904c5`와의 차이는 [적용표](../openspec/changes/refactor-server-web-app-monorepo/integration.md)에 구분했다. 참고 저장소는 수정하지 않았다.
- 저장소 고정 OpenSpec의 `validate --all --strict --no-interactive`: 6개 change 모두 통과했다. 플랫폼 추가 task 번호 충돌을 발견해 정정한 뒤 다시 통과했다.
- `node scripts/check-foundation.mjs`: 41 Markdown 파일과 62 local link 검사 통과. 제품 테스트를 뜻하지 않는다.
- 이관 change의 구현 tasks 0/39, XML handoff 0/9. 기존 문서 역할과 블록/XML 동등성, 서버 자동 전달 후속 목표, Windows 성공 인수 조건을 정합했다. 이번에는 제품 구현 tasks를 완료 처리하지 않았다.
- 명세 우선 지시 전에 수정한 웹 XML serializer/UI 2파일은 미검증 중간 변경으로 보존했다. 이 수정 이후의 JS 제품 전체 verify는 실행하지 않았다. 아래 과거 검증 결과를 새 코드 인수 근거로 사용하지 않는다.
- Flutter3.47.5/Dart3.13.4의 로컬 SDK 버전 조회만 성공했다. Desktop 앱 생성·widget/analyze·Windows build는 미수행이다. 새 commit/push/worktree 또는 제품 구현 재개는 하지 않았다.

## 이전 Blueprint 검증 기록

2026-10-24, Windows / Node 24.18.0.

- public engine contract: 0.1.0-alpha.1, SHA-256 b9e125e56685243c82ab7e90a2f574a2538e0ea014f23f6d4035ff75fd0953f6 검증 후 가져옴.
- 이벤트 모델 테스트 7개: 실제 실패·미실행, 중복 제거/재정렬/gap, 다른 snapshot/run/상충 sequence, 부분 JSONL, canonical hash, 분기 재생, schema 거부 통과.
- 실제 Chromium UI E2E 1개: JSON 가져오기, 실패 예제, slider 재생, 잘못된 action 거부, 파일 따라가기 갱신, markup 안전 표시, pageerror 없음 통과.
- Vite production build 성공. screenshot은 로컬 artifacts/blueprint-preview.png.
- 파일 따라가기 E2E는 FileSystemHandle substitute를 사용하며 OS 파일 선택 dialog 자체의 검증이 아니다.
- pnpm run verify 성공: foundation, public artifact hash, 이벤트 모델, OpenSpec strict 3개, web build, 실제 browser UI 인수. 추가 분기 모델 검사는 개별 재실행으로 통과했다. GitHub Actions는 설정만 작성했으며 원격 실행하지 않았다.

OpenSpec: qa-ai-blueprint 4/4. qa-flow-editor의 Flutter 구현과 qa-platform-services의 서버 구현 tasks는 미완료로 유지한다.

apps/web/public/demo의 blueprint.json/events.jsonl은 엔진의 실제 failed run_6f27d9d5-010a-4067-8977-953858421394에서 가져온 credential 없는 fixture다. 샘플 실행 target의 임시 localhost port는 기록 당시 값이며 실행 재사용은 engine demo로 새로 생성한다.

Flutter Desktop, GUI에서 CLI 직접 실행, Claude/Codex CLI 직접 호출, 로그인·권한·예약·Agent는 미구현이다. 이를 성공한 통합으로 보고하지 않는다.

## 모노레포 정책·검증 정비

2026-10-29 담당 인수 기록. 원본 MD와 현재 규칙의 대조는 [관리 인계](architecture/manager-handoff.md)를 따른다.

- 관리 에이전트가 변경 후 `npx --yes pnpm@10.34.8 run verify`를 실행해 통과했다. 경계 회귀 6개, 이벤트 모델 7개, 실제 Chromium UI 1개, OpenSpec strict 4개, JS build가 포함된다.
- Checker 담당이 `npx --yes pnpm@10.34.8 install --frozen-lockfile --ignore-scripts`를 추가 확인했다. 3 workspace, lockfile 변경 없이 성공했다.
- 원본 대조 문서·인계·tasks 수정 후 `node scripts/check-foundation.mjs` 성공(28 Markdown, 40 local links), 로컬 `openspec validate --all --strict --no-interactive` 4/4 통과를 확인했다.
- root `dev`로 시작한 `http://127.0.0.1:4318`에 `Invoke-WebRequest` 실행: HTTP 200, `/src/app/main.jsx`와 `/@vite/client` 응답 확인. 개발 프로세스는 유지했다. 추가 인자 전달로 다른 port를 적용한 성공 증거는 없으며 확인한 주소는 4318이다.
- 의존 경계 검사는 JS/TS AST와 package manifest를 대상으로 한다. Dart 분석, 전체 FSD slice 규칙, 실행 중 파일 접근의 검증은 아니다.
- Flutter/Nest는 계속 README 경계만 있으며 실제 앱 실행·빌드 검증에 포함되지 않았다. 현재 GitHub Actions 설정의 원격 실행도 이번 작업에서 확인하지 않았다.

