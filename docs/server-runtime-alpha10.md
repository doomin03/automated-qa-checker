# 서버·Agent alpha.10 연결

새 현재 lane은 `packages/contract/runtime/engine-runtime.json`을 사용한다. 기존 `packages/contract/engine-runtime.json`, `.local/engine`, 앱 legacy engine-runtime/engine-contract assets는 alpha.6 역사 회귀용으로 보존한다. 새 Desktop의 로컬 실행과 공유를 연결하려면 새 서버를 사용한다. alpha.6 서버에 대한 Desktop의 불일치 차단을 해제하는 설정은 없다.

## 준비

저장소 루트에서 승인 archive의 절대 경로를 전달한다. SHA256은 `0476445261b2596954167f335968d8bbb0a513867c930553604ba9b2b1c780e3`이다.

```powershell
node apps/server/scripts/prepare-server-runtime.mjs '<승인된 alpha.10 tgz 절대 경로>'
```

명령은 별도 `.local/engine-server-alpha10`에 npm 의존성을 설치하고 package 167파일과 CLI·bundle을 검증한다. 이미 있는 설치는 검증해 재사용하며 파일/receipt가 다르면 자동 교체하지 않는다. 실패한 stage는 진단을 위해 보존한다. 성공 receipt는 해당 설치 안의 `installation.json`에 있다. 개발 PC 절대 경로는 ignored receipt에만 저장한다.

Node24.18 및 Playwright Chromium은 서버 PC의 실행 전제다. 준비 명령 자체는 OS 브라우저 설치나 새 PC 인수를 뜻하지 않는다. Chromium이 없으면 아래 명령으로 이 설치가 요구하는 버전을 준비한다.

```powershell
node .local/engine-server-alpha10/node_modules/playwright/cli.js install chromium
```

## 사용자 서버 연결

기존 [로컬 서버 identity 준비](local-demo.md)를 따르되 새 DB와 새 runtime 경로를 사용한다. identity 파일을 출력하지 않는다. 이 예시는 로컬 개발용이며 운영 인증 설정을 바꾸지 않는다.

```powershell
$env:NODE_ENV='development'
$env:HOST='127.0.0.1'
$env:PORT='4319'
$env:QA_AUTH_MODE='local'
$env:QA_DATA_DIR=(Join-Path (Get-Location) '.local/platform-alpha10-data')
$env:QA_ENGINE_CLI=(Join-Path (Get-Location) '.local/engine-server-alpha10/node_modules/automated-qa-engine/packages/cli/aqa.mjs')
$env:QA_ENGINE_MANIFEST=(Join-Path (Get-Location) 'packages/contract/runtime/engine-runtime.json')
$env:QA_LOCAL_IDENTITIES_JSON=[IO.File]::ReadAllText((Join-Path (Get-Location) '.local/platform-identities.json'))
$env:CORS_ORIGINS='http://127.0.0.1:4318'
pnpm dev:server
```

웹/새 Desktop에 서버 주소와 해당 역할의 로컬 token을 입력하고 프로젝트를 선택한다. `GET /api/v1/projects/:projectId/context`에서 현재 `engineVersion`, `contractVersion`, `contractSha256`, `archiveSha256`를 확인할 수 있다. source XML을 게시하려면 author 작성·별도 reviewer 검수·권한 있는 게시 절차를 유지한다. 실행 결과 게시에는 실제 실행 snapshot과 현재 runtime이 일치해야 한다. 앱은 서버 없이도 로컬 실행할 수 있다.

## 독립 Agent demo

`node apps/server/scripts/agent-demo.mjs`, `agent-demo-admin.mjs`, `agent-schedule-demo.mjs`는 기본 `.local/agent-demo-alpha10`의 새 DB/identity/state 및 새 runtime을 사용한다. 기존 demo 폴더를 자동 승격하지 않는다. 명시 override는 QA_ENGINE_CLI와 QA_ENGINE_MANIFEST를 함께 설정해야 한다. 기존 폴더에 다른 runtime Agent 등록이 있으면 DB 조정·lease 복구 전에 read-only 검사로 거부한다.

demo가 기록한 agent-config.json과 token 파일은 로컬 신뢰 경계다. Agent는 별도 프로세스에서 실행하며 원문 token을 로그/문서에 출력하지 않는다.

```powershell
$env:AQA_AGENT_TOKEN=[IO.File]::ReadAllText((Join-Path (Get-Location) '.local/agent-demo-alpha10/agent-token.txt')).Trim()
node .local/engine-server-alpha10/node_modules/automated-qa-engine/packages/cli/aqa.mjs agent --config .local/agent-demo-alpha10/agent-config.json
```

로컬 테스트 대상도 먼저 실행해야 한다. demo 기본 대상은 `http://127.0.0.1:4317`이며 `QA_DEMO_TARGET_ORIGIN`은 명시 loopback origin만 허용한다. Agent 토큰/state 또는 기존 lease/fence를 새 runtime에 재사용하지 않는다. 취소 요청은 최종 결과가 아니며 cleanup unknown은 성공이 아니다.

## 이력과 계약 경계

기존 alpha.6 Run·게시 버전은 원본 runtime/hash로 조회한다. 새 서버의 신규 ingestion과 새로운 게시/Suite 실행은 현재 pin을 검사한다. 구 등록을 새 실행 파일로만 바꾸면 claim이 거부된다. 기존 runtime rows·불변 버전·lease·receipt를 SQL로 일괄 덮어쓰는 migration은 제공하지 않는다.

alpha.6과 alpha.10의 Agent HTTP protocol SHA는 동일하지만 Engine runtime triple은 다르다. execution schema는 alpha.6 대비 result의 visitedNodes/unvisitedNodes 상한 확장이 있으므로 raw schema SHA가 동일하다고 주장하지 않는다. 이번 Checker 변경은 Engine schema나 고정 A07 OpenAPI/SDK를 편집하지 않는다.

## 검증 명령

```powershell
node --test apps/server/test/server-runtime.test.mjs
node apps/server/scripts/verify-runtime-integration.mjs --history-only
node apps/server/scripts/verify-runtime-integration.mjs
```

마지막 명령은 실제 로컬 Chromium과 Agent를 실행하므로 앱 native/전체 회귀와 실행 시간을 분리한다. 매회 별도 포트·서버 DB·Agent state·artifact 디렉터리를 생성하며 `artifacts/runtime-alpha10/run-*/verification.json`에 결과와 관측한 소유 PID를 기록한다. 과거 Run은 실제 기록 fixture, 과거 lease는 명시 blocked 프로토콜 fixture다. 새 Suite/예약/취소는 실제 Agent 인수이며 예약 clock은 제어된 시간이다. 관측 PID 잔존 검사는 전체 OS 누수 검증이 아니다.
