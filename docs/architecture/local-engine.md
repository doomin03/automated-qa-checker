# Desktop 로컬 엔진 연결

실서비스 적용을 위한 프로세스·출력 제한과 플랫폼별 인수 범위는 [서비스 소비 점검](engine-service-readiness.md)을 따른다. 고정 preview package의 로컬 검증과 실제 운영/실기기 준비를 구분한다.

Flutter는 기능별 MVVM/Provider를 유지하며 run_review의 ViewModel→Repository→CLI Service에서 독립 Engine를 호출한다. 앱이 Playwright/Appium 실행기를 직접 구현하지 않는다. 웹과 Desktop은 같은 공개 Blueprint/XML 계약을 작성하고 실행은 Engine validate/plan 경로를 따른다.

## 설치와 입력

현재 소비는 공개 local-preview Engine alpha.6 / contract0.3.0-draft.1이다. [runtime pin](../../packages/contract/engine-runtime.json)과 [contract pin](../../packages/contract/engine-dependency.json)에 정확한 version/hash가 있다. 원격 npm 게시나 완성된 설치 프로그램을 의미하지 않는다.

검증된 tgz를 전달받은 뒤 저장소 루트에서 실행한다. 외부 저장소 소스 경로는 의존성으로 커밋하지 않는다.

```powershell
node scripts/install-engine-runtime.mjs <검증된-automated-qa-engine-0.1.0-alpha.6.tgz-절대경로>
```

설치기는 tgz SHA-256을 확인하고 ignored `.local/engine`에 npm install --ignore-scripts로 설치한다. 앱 asset manifest에는 배포판 자체 파일들의 SHA-256을 기록한다. Flutter는 CLI 호출 전 package 파일과 exact version을 확인한다. 이 manifest는 Engine package 내부 파일 범위이며 중첩/외부 node_modules dependency 전체를 실행 때 다시 검증하지 않는다. npm이 설치하는 의존 패키지는 npm lock/integrity 범위이며 별도 배포 hardening은 후속이다.

앱 오른쪽 입력에 Node 실행 파일, `.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs`, 결과 폴더의 절대 경로를 지정한다. 개발 PC의 절대 경로나 실제 secret은 프로젝트 문서/초안에 저장하지 않는다. secretRef가 있으면 Engine의 환경 변수 방식으로 주입한다.

## 작성·검증·실행

XML/JSON 원문을 붙여넣거나 파일을 연다. 블록/Flow 화면은 공개 예제 또는 Engine가 검증한 plan을 내부 Blueprint 편집 모델로 사용한다. node/action/params/branch와 target/selector/변수/TC 기본 폼, 연결 추가·삭제, 노드 이동, undo/redo를 제공하며 고급 JSON은 보조다. 위치는 metadata.presentation에만 기록한다. Flow를 원문에 적용한 뒤 공개 CLI export로 XML을 생성할 수 있다.

검증·계획은 테스트를 실행하지 않는다. 입력 snapshot을 저장하고 Engine validate/plan을 요청한다. 정규화된 문서를 저장한 뒤 다시 Engine plan을 호출해 hash를 확인하므로 Dart와 JavaScript 숫자 직렬화 차이를 자체 canonical 알고리즘으로 추측하지 않는다. 실행 직전 snapshot을 재검증한다.

테스트 실행은 명시 버튼으로 요청한다. capability와 대상 지원을 확인하고 인자 배열/runInShell=false로 CLI를 실행한다. run/attempt/sequence, 시작 snapshot, terminal·exit code와 결과 파일, executed version/flow/blueprint hash를 대조한다. report와 artifact의 realpath containment 및 실제 bytes SHA-256을 검증한다. 누락/모순은 환경 오류이며 성공으로 합성하지 않는다.

alpha.6 취소는 `--control-stdin`에서 JSONL `{"type":"cancel"}`을 전송한다. 요청 상태와 실제 cancelled terminal/result·exit5를 분리한다. 프로세스 강제 종료/timeout/결과 누락은 정상 취소가 아니다. run 준비 중 취소도 latch로 보존하여 뒤늦은 실행을 막는다. stderr 진단 원문과 비밀값을 화면에 누적하지 않는다.

결과 경로의 blueprint.json/events.jsonl을 웹에서 열거나 파일 따라가기로 관찰할 수 있다. 파일 교환은 서버 자동 동기화가 아니다. Flutter graph는 같은 snapshot에만 실행 상태를 표시하고 편집본이 달라지면 읽기 전용 실행 snapshot으로 전환해 확인한다.

## 서버 연결과 현재 한계

서버 연결은 선택 기능이다. 웹 `VITE_API_BASE_URL`, Flutter `--dart-define=API_BASE_URL=http://127.0.0.1:4319` 또는 화면 origin 입력을 사용한다. 생성 SDK가 endpoint와 DTO를 소유하며 origin에 /api/v1을 중복 입력하지 않는다. 별도 웹 origin은 서버 `CORS_ORIGINS`에 정확히 등록한다.

현재 서버는 OIDC/Registry/진행 자동 수신/업무/Suite/예약·Agent를 구현했다. alpha.6은 디자인/UX·Appium adapter·authoring·독립 Agent 공개 계약을 포함한다. 실제 Slack 계정과 모바일 기기 실행은 로컬 provider/adapter fixture 검증과 분리하여 미검증으로 남긴다. 설치된 브라우저 확인과 native 정적 지원·설정 상태를 실제 기기 연결로 혼동하지 않는다.

## 검증 경로

- `node --test tests/xml.test.mjs`: 웹 serializer→공개 CLI XML roundtrip.
- `node --test tests/ui.test.mjs`: 실제 브라우저 XML 다운로드/이벤트 관찰 및 Nest cross-origin 연결.
- Flutter `test/engine_bridge_test.dart`: 실제 Engine PASS/FAIL/cancel, 잘못된 입력·버전·snapshot·준비 중 취소.
- Flutter `test/engine_ui_test.dart`: Provider widget 입력→실제 CLI→결과 표시. OS 데스크톱 UI 직접 조작 E2E와 구분한다.
- Flutter `test/flow_editor_test.dart`: graph 편집/branch/undo/redo/좌표 및 Engine XML roundtrip.

실행 결과·정확한 명령·현재 통과 여부는 [검증 기록](../validation.md)에 인수 후 기록한다. 로컬 `.local` package가 없는 새 환경은 위 설치 단계를 먼저 수행해야 한다.
