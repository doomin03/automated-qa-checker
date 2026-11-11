# 2026-11-10 실제 Desktop 프로젝트·QA·AI 작성 인수

Checker `main/4f97e920a399d4a5434ab1ecbe44c4d879d397a4`의 기존 dirty tree를 보존하면서 `qa-desktop-ai-workspace`를 구현했다. Engine 제품 패키지/서버 소스·HTTP 계약·이전 Release/목업은 변경하지 않았다. 사용 순서는 [Desktop 시작 안내](desktop-ai-quickstart.md)다.

## 구현과 저장

- `features/project_workspace`: immutable 프로젝트/QA·지속 지침·최근 실행 metadata, bounded JSON16MiB, 문서1MiB, OS lock/revision, sibling flush/replace. 형식 오류·directory/link·미지원/unknown field는 거절하며 원본을 보존한다.
- `features/ai_authoring`: Codex 고정 인자·기존 인증·stdin/JSONL, 고유 세션, 전체 후보 공개 Engine 검증, 변경 비교·명시 적용·revision-safe undo. 일회성 요청은 QA 전환 시 초기화하고 저장되는 지속 요청과 분리한다. View는 파일/Process를 직접 호출하지 않는다.
- `app/workbench`: 도킹 목록/XML/Flow/AI/결과를 조합하며 새 QA와 Flow 문서 소속을 묶는다. 실행 결과 소속과 snapshot은 실행 시작에 고정한다. 최근 runId/hash/outcome/reportDirectory를 해당 QA에 기록할 때 현재 미저장 원문·지침을 덮지 않는다.
- `AppProviders`는 생성한 의존성만 한 번 해제한다. 앱 전용 alpha.8 manifest/bundle/기기 receipt는 `desktop-*` asset이고 기존 alpha.6 asset·기본 설치/서버 설정은 그대로다.

## 실제 Windows UI·Codex·Engine

`node scripts/flutter.mjs test integration_test/desktop_ai_test.dart -d windows --dart-define=QA_REPO=C:/workspace/QA/automated-qa-checker`는 최종 1/1 PASS,66초였다. `artifacts/windows-desktop-ai/integration.log`와 `run-6d5a867e/verification.json`을 기록했다. 이전 첫 인수 `run-b1fc3e86`도 보존한다.

실제 제품 UI 버튼으로 프로젝트/QA 생성→XML 가져오기→지침/요청 입력→Codex 후보 생성→전체 diff 미리보기→명시 적용→저장→검증→실행을 수행했다. 실제 Codex0.162.1 기존 ChatGPT 인증을 사용했으며 모델 응답이 추가한 `ai_evidence` 노드가 실행됐다. 성공/의도한 실패/실제 취소 3개 결과의 run.finished/result가 일치하고 전체42 events·PNG3개 bytes/hash를 관리자가 직접 대조했다. 생성만으로 run은 발생하지 않았다.

캡처는 같은 폴더의 `01-projects.png`, `02-request.png`, `03-proposal.png`, `04-passed-png.png`, `05-failed.png`, `06-flow-passed.png`, `07-restored.png`다. Flow에서 실제 start 선택과 passed 배지를 확인했다. 복원은 **기존 Provider scope를 dispose한 뒤 새 scope로 같은 저장 파일을 읽고 프로젝트/QA를 열어** 원문·지침·지속 요청·lastRun을 대조한 것이다. 동일 검사에서 OS 프로세스를 종료·재실행했다고 주장하지 않는다. 1440×900/1024×768 접근 검사는 `desktop_workspace_test.dart`의 WidgetTester 크기 변경 및 오류 없음으로 인수했고 위 native 캡처는 기본 창 크기다.

디자인 check-report 인수는 이번 전체 회귀의 `design_engine_test.dart`와 `design_ui_test.dart`에 연결된다. 설치된 alpha.8 실제 Chromium의 기준/실제/diff와 공개 보고서를 검증하고 동일 `RunResults`의 `Image.memory`로 verified PNG를 표시했다. 이는 새 AI가 이미지를 이해하거나 디자인을 생성한 인수가 아니다.

## 회귀 결과와 보완 이력

첫 기본 병렬 실행은43 PASS/3 서버 시작 timeout/1 조건부 candidate skip이었다(도구 출력 기록). 저장소 공식 `app:test`와 같은 `--concurrency=1` 실행은45 PASS/1 공유 네트워크 단절 검사 실패/1 skip, 원본 로그 `artifacts/flutter-desktop-ai-tests.log`를 보존했다. 공유 검사가 서버 종료 후1초에 실패를 요구했지만 실제 SDK timeout은30초다. 테스트를 최대35초 내 failed를 확인하도록 정합하고 제품 공유 코드는 바꾸지 않았다.

`test/desktop_workspace_test.dart test/shared_engine_test.dart --concurrency=1` 후속은2/2 PASS,29초(`flutter-desktop-ai-recovery.log`)이며 공유 수신·실행·단절 failed·재시작·같은 결과 재게시를 검증했다. 이 테스트는 **격리 Nest 서버에 alpha.8 manifest를 명시 주입**한 것으로 기본 alpha.6 서버/Agent 승격이 아니다. 최종 `test/ai_cli_test.dart test/desktop_workspace_test.dart --concurrency=1`은5/5 PASS,9초(`flutter-desktop-ai-focused-final.log`)였다. 기존 전체+영향 회귀를 합쳐 적용 검사47개 통과, 승인 후보 환경변수가 필요한 격리 package 검사1개는 skip으로 남는다. `verify:all`을 한 번에 통과했다고 보고하지 않는다.

추가 인수에는 네 AI 요청 범위·candidate 검증 오류·자동run0·문서 ABA/선택/요청/지침 stale·후속 수동편집 undo 거절·Flow 전환·결과 소속·저장 후 그래프 유지가 포함된다. 실제 Dart child fixture에서 진단/인증 실패·missing Claude/path·도구 이벤트 거절·출력 cap·timeout·취소를 검증했다. Windows 두 OS process 저장 경쟁과 staging 중 writer 종료/기존 파일 보존도 포함된다. 독립 감사의 저장9사례·AI service immediatecancel/orphan cleanupUnknown 및 Flutter VM4경계가 별도 PASS이며 `../coordination/artifacts/desktop-independent-20261110`에 관리 증거가 있다.

AI timeout 기본180초, stdout4MiB/stderr1MiB, 소유 tree 종료 명령 최대5초와 exit/pipe 정리7초를 구분한다. fixture는 짧은 예산을 주입한다. 부모 프로세스가 먼저 종료하고 자식 pipe가 남는 경우 정리 미확인을 표시하고 추가 생성은 거절한다. 실제 Codex 성공과 fixture 취소를 같은 증거로 혼동하지 않는다.

## Runtime·Release

앱 runtime0.1.0-alpha.8 / execution contract0.3.0-draft.2:

- tgz SHA256 `4215662445780eeecd016ad6acf2a7b2c5e16b9a4e62cf8ae88e30ee0452e77f`
- bundle SHA256 `638d48f182d12819ebd167d42457c7dceaa90928abb38c32a4867e3c94b10763`
- `scripts/install-desktop-engine.mjs`에서 별도 설치148파일 전체가 동결 verification과 일치하고 public version/bundle/Chromium 설치를 확인했다. 기존 browser cache를 사용할 수 있으며 새 OS 설치 인수는 아니다.
- `node scripts/flutter.mjs analyze` 최종 PASS(3.8초, `flutter-desktop-ai-analyze-final.log`). 앞선9개 lint info를 수정한 결과이며 첫 로그도 보존했다.
- `node scripts/flutter.mjs build windows --release` PASS(35.2초, `flutter-desktop-ai-build.log`). `record-desktop-release.mjs`로 별도 Release17파일 복사·bytes 대조, `smoke-desktop-release.ps1`로 실제 process/FLUTTER_RUNNER_WIN32_WINDOW 초기화 PASS. UI 상호작용은 위 Windows integration 증거와 구분한다.
- 최종 폴더 `artifacts/releases/desktop-ai-alpha8/Release`; `manifest.json`의 파일맵 digest `a648859ee849507a7d04db0f8266e6a61eb4b96a020ddebb204bb2aa514f9159`, app.so SHA `30b6bbcf41a122902c7dbc95b8193b5489eac7f9c4ead86004a49f17b9dea54d`. 이 digest는 manifest JSON파일 자체의 SHA와 다르다.
- `source-manifest.json`은54개 Dart source이며 digest `92452977876d68f23b88453cd889e6d928c5b9992207a44b44bf3df146286967`. 관리자가 release17/source54/runtime148 및 기존201파일 drift0을 독립 확인했다.

고정4339 데모 명령도 관리자가 서버기동→생성 XML→실제Chromium exit0/passed·16events·PNG1개로 독립 확인했다. 일시 integration 포트가 닫힌 XML을 사용자 데모로 안내하지 않는다.

## 제약

Claude 실제 adapter/인수, 실 Slack 계정, Android/iOS 실기기, AI 이미지 해석과 전체 대화 이력은 미구현 또는 외부 인수 전이다. 현재 앱은 로컬 Codex의 정의 생성만 요청하며 자동 QA 실행/임의 shell 실행 기능이 아니다. 서버/Agent alpha.6과 새 앱alpha.8의 게시 버전 차이는 명시 오류로 구분한다. 과거 보고서 전체 자동 복원은 하지 않으며 QA별 마지막 경로/결과만 저장한다. 배포 경로 이동 시 기기 receipt를 다시 생성하고 빌드해야 한다. 원격 commit/push나 기존 Release 교체는 하지 않았다.

## 저장소 최종 검사

`corepack pnpm run verify` exit0, `corepack pnpm run test:verification-gates`6/6 exit0를 확인했다. 로그는 artifacts/desktop-ai-verify.log 및 desktop-ai-verification-gates.log다. 기존 서버/웹 build·SDK/계약 검사·실제 browser routes가 포함되며 새 Flutter 전체는 위 별도 실제 명령과 영향 회귀로 인수했다. 새 change12/12를 정합했으며 최종 strict/foundation/diff 결과는 artifacts/desktop-ai-acceptance.json에 기록한다.
