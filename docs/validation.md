# Blueprint UI 검증

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

