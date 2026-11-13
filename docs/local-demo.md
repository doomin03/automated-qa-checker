# 로컬 기능 데모

동일 alpha.10 Desktop↔서버↔Agent 연결은 [새 서버 runtime 안내](server-runtime-alpha10.md)를 따른다. 이 문서의 아래 alpha.6 경로는 역사 회귀용으로 보존하며 새 runtime으로 덮어쓰지 않는다.

새 프로젝트/QA·실제 AI 작성 앱은 **[Desktop 시작 안내](desktop-ai-quickstart.md)**를 먼저 따른다. 아래 alpha.6 서버·웹 공유 절차는 기존 환경용이며 새 Desktop을 실행하기 위한 필수 단계가 아니다. `dev:app`은 현재 새 Desktop source를 시작하므로 앱 전용 설치를 먼저 수행한다.

Node24.18, pnpm10.34.8, Flutter3.47.5/Dart3.13.4와 Windows C++ build toolchain을 사용한다. 전역 설정을 바꾸지 않고 `corepack pnpm`으로 명령을 실행할 수 있다. 스크립트 내부 pnpm이 PATH에 없으면 ignored `.local/toolbin`에 `corepack enable --install-directory .local/toolbin pnpm`으로 shim을 만든 뒤 현재 터미널 PATH에만 추가한다.

1. `corepack pnpm install --frozen-lockfile`을 실행한다. Engine는 독립 배포 패키지다. 현재 `packages/contract/engine-runtime.json`에 고정한 alpha.6 tgz를 준비하고 `node scripts/install-engine-runtime.mjs <tgz 절대 경로>`로 SHA-256 확인 후 ignored `.local/engine`에 설치한다. 다른 버전 tgz를 같은 pin으로 사용하지 않는다.
2. `corepack pnpm dev:web`은 사용자 웹 `http://127.0.0.1:4318`을 시작한다. `corepack pnpm dev:app`은 앱 전용 alpha.8을 설치한 새 Flutter Windows source를 실행한다. 로컬 SDK 위치는 scripts/flutter.mjs 또는 `FLUTTER_SDK` 설정을 따른다.
3. **이전 alpha.6 Release**에서만 Node 실행 파일, `.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs`, 결과 폴더를 모두 절대 경로로 입력한다. 새 `dev:app`/desktop-ai-alpha8 Release에는 이 경로를 입력하지 않고 [앱 전용 설치와 자동 설정](desktop-ai-quickstart.md)을 사용한다. 두 앱 모두 로컬 실행은 서버 없이 가능하다.
4. 공용 서버는 [서버 환경 설정](../apps/server/PLATFORM.md)을 적용한 같은 터미널에서 `corepack pnpm dev:server`로 시작한다. 공유 주소는 `http://127.0.0.1:4319`, 프로젝트는 demo다. 자동 생성한 ignored identities 파일에서 역할별 token을 로컬 UI에만 입력한다. author가 초안 작성, 별도 reviewer가 검수, tester가 수신·실행 게시, viewer가 조회한다. 원문 token은 문서·로그·스크린샷에 넣지 않는다.
5. 웹에서 발행 버전을 확인하고 이전 alpha.6 Desktop 공용 패널에서 고정·수신한다. **동일 runtime의 앱·서버**에서 명시 실행 전에 진행 게시를 선택하면 웹에서 해당 run을 조회할 수 있다. 새 alpha.8 앱은 XML을 수신·검증할 수 있으나 기본 alpha.6 서버와 실행 게시 버전이 다르므로 게시 실패를 별도로 표시한다. 이번 격리 테스트의 alpha.8 서버 인수를 기본 서버 승격으로 해석하지 않는다. 네트워크/게시 실패가 로컬 결과를 바꾸지는 않는다.

실행 터미널의 상세 순서는 다음과 같다. `QA_ENGINE_TGZ`와 `FLUTTER_SDK`에는 준비한 실제 배포물/SDK 경로를 지정한다. 사용자 토큰을 명령 인자로 전달하거나 출력하지 않는다.

```powershell
# 저장소 루트: 설치와 도구 준비
corepack pnpm install --frozen-lockfile --ignore-scripts
New-Item -ItemType Directory -Force .local/toolbin | Out-Null
corepack enable --install-directory .local/toolbin pnpm
$env:PATH=(Join-Path (Get-Location) '.local/toolbin')+';'+$env:PATH
node scripts/install-engine-runtime.mjs $env:QA_ENGINE_TGZ
pnpm exec playwright install chromium
& ./packages/contract/generator/setup.ps1
node scripts/flutter.mjs pub get --enforce-lockfile
pnpm build
node apps/server/scripts/local-identities.mjs

# 서버 터미널 (생성된 identity 파일을 읽으며 원문을 출력하지 않음)
$env:NODE_ENV='development'
$env:HOST='127.0.0.1'
$env:PORT='4319'
$env:QA_AUTH_MODE='local'
$env:QA_DATA_DIR=(Join-Path (Get-Location) '.local/platform-data')
$env:QA_ENGINE_CLI=(Join-Path (Get-Location) '.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs')
$env:QA_ENGINE_MANIFEST=(Join-Path (Get-Location) 'apps/app/assets/engine-runtime.json')
$env:QA_LOCAL_IDENTITIES_JSON=[IO.File]::ReadAllText((Join-Path (Get-Location) '.local/platform-identities.json'))
$env:CORS_ORIGINS='http://127.0.0.1:4318'
pnpm dev:server
```

별도 저장소 루트 터미널에서 `pnpm dev:web`, 또 다른 터미널에서 `pnpm dev:app`을 실행한다. 서버4319는 `/api/v1/health?client=app`, 웹4318은 `/qa/blueprints`와 `/qa/shared`를 제공한다. identity 생성기는 기존 파일을 덮어쓰지 않으므로 이미 만들었다면 재사용한다. `author`/`reviewer`는 서로 다른 검수자, `tester`는 수신·실행, `viewer`는 조회 권한이다. 로컬 모드가 화면에 표시되며 production에서는 시작을 거절한다.

이전 alpha.6 공유 인수 앱은 저장소 아래 `artifacts/releases/alpha6-mvvm/Release/automated_qa_desktop.exe`로 실행한다. **Release 전체 폴더**를 함께 보존한다. DLL/data/app.so/embedded engine manifest가 필요하므로 exe만 복사하지 않는다. `artifacts/flutter-release-mvvm.json`이 전체14파일의 hash이며 같은 경로의 실제 native 창 초기화를 확인했다. 기존 working checkout의 `apps/app/build`는 이전 빌드일 수 있다. `pnpm app:build`는 현재 source의 **새 alpha.8 Desktop**을 빌드하며 이전 alpha.6 앱을 재생성하는 명령이 아니다. 그 결과인 `apps/app/build/windows/x64/runner/Release` 전체를 사용하며 새 앱의 설치 receipt·설정은 Desktop 시작 안내를 따른다. 이전 alpha.6 앱에는 Node와 고정 Engine 공개 패키지 경로를 별도로 설정한다. 독립 CLI도 `node <설치된 aqa.mjs> --help`, `validate <XML>`, `plan <XML>`, `run <XML> --json --report <결과절대경로>`로 Checker 서버 없이 사용할 수 있다.

production 웹 정적 실행은 `pnpm --filter @automated-qa-checker/web start`이며 기본4318이다. `/api`를 웹 index로 바꾸지 않으며 API origin은4319로 직접 지정한다. `verify:all`은 SDK 재생성 비교·수용된 HTTP 호환성 기준·JS/Flutter 검사·실제 브라우저·Windows build를 실행한다. 원격 CI 실행을 로컬 성공으로 간주하지 않는다. Windows CI는 고정 Engine tgz/Flutter/C++ toolchain이 준비된 self-hosted runner에서 별도 수동 workflow로 실행한다.

반복은 설정한 action/assertion 블록을 순서대로 복사하고 횟수를 지정해 authoring 문서를 만든다. 공개 expand는 원본·sourceMap·확장 XML을 결과 폴더에 보관하며 실행하지 않는다. 확장 XML을 확인하고 다시 검증 후 실행한다. 직접 `<authoring>` XML도 같은 전개 버튼을 사용한다.

디자인 기준은 [PNG·수치 입력](architecture/design-ux.md)을 따른다. Appium은 로컬 설정 파일 경로를 따로 입력하며 endpoint/UDID를 XML에 저장하지 않는다. 실제 모바일 기기 실행은 기기·서버·앱 준비 후 별도 인수한다. 조직 로그인과 업무/알림의 설정 및 인수 범위는 [조직 인증·업무 안내](architecture/organization-auth-workflow.md)를 따른다. 독립 Agent 실행·예약은 [Agent 운영 안내](../apps/server/AGENT.md)를 따른다. Agent는 Flutter를 종료해도 독립 프로세스로 실행하며 실제 서버 통합 인수는 검증 기록을 따른다.

현재 Checker와 Engine의 Playwright는 모두 1.64.1이므로 위 설치 한 번으로 같은 Chromium을 준비한다. 새 PC에서도 이 단계를 생략하지 않는다. `verify-fresh.mjs`는 node_modules/build를 재사용하지 않고 새 의존성 설치부터 검사하지만 운영체제·Flutter/C++ 도구 및 브라우저 다운로드 캐시는 공유한다. 새 OS 설치 검증이라고 해석하지 않는다.
