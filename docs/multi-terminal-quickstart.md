# 다중 터미널 작업실 시작

새 앱은 `artifacts/releases/desktop-multi-terminal-alpha9/Release/automated_qa_desktop.exe`다. DLL·data를 포함한 **Release 폴더 전체**를 유지한다. 이전 alpha.8 Release와 기본 서버/Agent alpha.6은 바꾸지 않는다. 실제 완료/제약/검증 결과는 [인수 기록](validation-multi-terminal-workbench.md)을 따른다.

1. 프로젝트와 QA를 연다. 새 workspace는 포함된 설치 receipt의 Node/alpha.9 CLI와 사용자 reports 경로로 초기화한다. 이전에 저장한 실행 경로가 있다면 **실행 환경 / 연결**에서 `.local/desktop-engine/0.1.0-alpha.9/09d0669d247c18cf88c7967156f801d15e2a871eb2e2b6d740ba245d7ca933e6/installation.json`의 `nodePath`·`cliPath`를 확인해 지정한다. 구 runtime mismatch는 자동 우회하지 않는다.
2. **파일 → 템플릿으로 새 QA**에서 템플릿과 대상 URL/testId 등을 입력하고 생성·검증한다. 미리보기 후 새 QA로 저장한다. 기존 XML/JSON을 파일 블록으로 가져와 연결하는 방법도 같다. 생성/저장만으로 실행되지 않는다.
3. 터미널을 열고 **추가**에서 공급자·설치 경로를 확인한 뒤 시작한다. 같은 공급자도 여러 번 열 수 있다. Codex/Claude는 기존 CLI 로그인과 자체 신뢰/업데이트 화면을 사용한다. 앱은 API 키를 저장하지 않는다. 설치되지 않은 Claude는 준비 필요로 남는다.
4. 각 세션은 시작 QA에 묶인 별도 사본이다. **자동 반영 작성자**는 QA당 하나다. 이전 작성자는 살아 있는 검토 세션으로 유지할 수 있다. 터미널에서 `scenario.xml` 또는 `scenario.json`을 편집하면 직접 문서 모드에서 유효·충돌 없는 변경만 반영한다. 파일 블록 합성 모드는 후보를 보류하므로, 원문을 편집하려면 명시적으로 **직접 문서 / Flow**로 전환한다.
5. 탭 전환·분할·접기·확대는 프로세스 종료가 아니다. 크기 조절선은 드래그 또는 포커스 후 방향키/Home/End로 조작한다. 좁은 창은 한 pane/별도 작업 패널에서 접근한다. **종료**만 해당 세션 정리를 요청한다. 정리 미확인 오류가 있으면 writer 권한을 재사용하지 않는다.
6. 검증한 문서를 **실행**하여 결과·진행·PNG를 확인한다. 셸에서 사용자가 직접 실행한 명령은 앱 QA 결과가 아니다. 기본 alpha.6 서버에 alpha.9 결과를 자동 게시하지 않으며 호환성 오류는 로컬 판정과 분리한다.

## 로컬 대상 데모

저장소에서 `node scripts/desktop-demo.mjs`를 실행하고 출력된 XML을 가져온다. 이 명령은 고정 로컬 대상과 공개 Engine XML을 제공한다. 4339가 사용 중이면 기존 프로세스를 임의 종료하지 말고 충돌을 해결한다. 앱용 template의 시작 URL도 해당 데모 주소로 지정할 수 있다. 데모 종료 후 해당 URL의 테스트는 실행되지 않는다.

## 다른 PC / 개발 checkout

Node·고정 Flutter/Windows toolchain과 승인된 Engine archive가 필요하다. `node scripts/install-desktop-engine.mjs <승인 tgz 절대경로> <verification.json 절대경로>`가 pin/full SHA와 payload를 검증하고 앱 전용 설치·asset을 생성한다. 이 checkout의 고정 Playwright와 Engine 버전은 같으며, Chromium은 `node node_modules/playwright/cli.js install chromium`으로 별도 설치한다(설치 스크립트는 npm lifecycle을 실행하지 않는다). 개인 설치 receipt는 배포 검증 자료이며 Git의 credential 저장소가 아니다. Windows 앱을 다시 만들 때 `node scripts/flutter.mjs build windows --release`를 사용한다.

현재 인수는 PowerShell/cmd 실제 명령·파일 수정과 Codex TUI 시작까지다. Codex 모델의 이 작업 skill discovery/파일 편집 성공 및 Claude 실제 실행은 별도 인수이며 준비 배지만으로 완료를 주장하지 않는다.
