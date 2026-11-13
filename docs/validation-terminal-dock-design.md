# VS Code 스타일 터미널 도크 적용

2026-11-13. 사용자가 확인한 하단 목업을 실제 Flutter `TerminalDock`에 적용하고 main push를 요청했다.

## 변경

- #1e1e1e 배경, 파란 선택 밑줄, 평평한 세션 탭과 상태 점을 적용했다.
- 왼쪽 패널 열기/접기와 오른쪽 새 세션·분할·확대·선택 종료·세션 메뉴를 분리했다. 아이콘에는 툴팁을 제공한다.
- 이름 변경·Ctrl+C·종료 후 목록 제거는 세션 메뉴로 이동했다. 추가 버튼은 기존 실행 파일 선택·진단과 명시 시작 경로를 그대로 사용한다.
- 실제 `Pty.spawn`, 입출력, 종료·cleanup, writer·QA 소속·revision 보호를 변경하지 않았다. 세션별 controller·스크롤·clipboard 소유도 유지한다.
- 큰 글자와 낮은 화면의 확대 패널은 44px 헤더 높이를 제외해 계산한다. 첫 검사에서 발견한 800×600 패널의 3~10px overflow를 수정했다.

## 확인

이 PC에 있는 Flutter 3.47.9 / Dart 3.13.7을 `FLUTTER_SDK` 환경변수로 지정했다. 저장소 SDK나 lockfile은 변경하지 않았다. 기본 스크립트의 이전 3.47.5 경로와 구분한다.

- `node scripts/flutter.mjs analyze --no-pub`: 오류·경고 없음.
- `node scripts/flutter.mjs test --no-pub --concurrency=1 test/multi_terminal_dock_test.dart test/adaptive_workbench_test.dart test/terminal_environment_dialog_test.dart test/terminal_readiness_test.dart test/multi_terminal_test.dart`: 최종 13개 PASS. 첫 실행은 도크/적응형 2개 FAIL을 보존하며 수정 후 동일 5파일을 재실행했다.
- 실제 변경한 메뉴가 선택 세션에만 Ctrl+C를 전달하고, 접기 후 세션이 살아 있으며, 재개 시 controller가 유지됨을 기존 dock 검사에 추가했다. 이 테스트의 서비스는 fixture이며 실제 CLI 실행 증거로 사용하지 않는다.
- HTML 목업의 터미널 43·홈 14·편집기 16·portal 94·디자인 25개 검사: 192개 PASS. 이전 결과를 덮지 않는 `verification-dock-design*.json`과 [목업 안내](../design/mockups/xml-block-studio/README.md)를 따른다.
- 두 관련 OpenSpec change strict, 소스 lint·경계 검사와 `git diff --check`를 확인했다.
- `node scripts/flutter.mjs build windows --release --no-pub`: 로컬 junction 준비 후 exit0, `apps/app/build/windows/x64/runner/Release/automated_qa_desktop.exe` 생성. 엔진을 포함한 portable 배포물이 아닌 UI 개발 빌드다.

## 환경과 제한

Git에서 제외하는 `desktop-installation.json`과 `desktop-portable-runtime.json`이 이 PC에는 없었다. UI 검증을 위해 런타임 경로가 없는 명시적 `configured:false` 설정을 로컬에 생성했다. 설치된 엔진·portable runtime이 있다는 receipt로 취급하지 않으며 Git에 포함하지 않는다. 검증 후 이 임시 설정은 제거한다.

초기 pub get/build는 Windows 개발자 모드가 꺼져 플러그인 심볼릭 링크 생성에 실패했다. 시스템 설정을 바꾸지 않고 generated `flutter/ephemeral/.plugin_symlinks`에 실제 Pub cache를 가리키는 로컬 junction을 준비하여 `--no-pub` 빌드를 재시도했다. 이 링크도 Git에 포함하지 않는다.

저장소 전체 `pnpm run verify`는 기존 문서가 참조하는 Git 제외 과거 로그 `artifacts/multi-terminal-planning/repository-verify-initial.log`가 없어 foundation에서 중단됐다. 이번 작업의 전체 verify 성공으로 보고하지 않는다. 실제 AI 모델·새 엔진 실행·portable 배포 인수는 이번 UI 변경의 완료 근거에 포함하지 않는다.
