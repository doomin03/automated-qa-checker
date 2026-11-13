# apps/app

현재 소스는 D08 다중 PTY와 공개 Engine templates/compose를 사용하는 alpha.10 작성 작업실이다. 프로그램 선택·준비 진단 및 실행 파일 옆 Node/Engine/Chromium을 검증하는 portable 경로를 추가했다. 새 배포는 `artifacts/releases/desktop-portable-alpha10/Release/automated_qa_desktop.exe`이며 최종 gate 상태는 [portable 인수 기록](../../docs/validation-desktop-readiness-portable.md)을 따른다. [portable 시작 안내](../../docs/portable-desktop-quickstart.md)에 따라 Release 폴더 전체를 옮긴다. `app:build`만으로는 portable payload를 만들지 않으며 `node scripts/build-portable-desktop.mjs`가 전용 빌드·기록 경로다.

이전에 인수한 alpha.9 다중 터미널 배포는 `artifacts/releases/desktop-multi-terminal-alpha9/Release/automated_qa_desktop.exe`로 보존한다. [다중 터미널 시작 안내](../../docs/multi-terminal-quickstart.md)와 [당시 인수](../../docs/validation-multi-terminal-workbench.md)는 과거 고정 배포 기준이다. 아래 alpha.8 경로도 이전 Release이며 덮어쓰지 않는다. 서버/Agent alpha.10 승격은 별도 서버 계약/인수에 따르며, 연결 서버와 runtime이 다른 결과의 게시를 자동 허용하지 않는다.

2026-11-12 기획 D01–D08 대응과 작은 창/큰 글자 보완은 [반응형 인수 기록](../../docs/validation-planning-responsive.md)을 따른다. ScreenUtil 없이 제약 기반 배치와 영역별 스크롤을 사용한다. 좁은 창의 탐색/속성/AI 및 낮은 창의 터미널/결과는 별도 패널에서 열 수 있다. `작업실로`는 터미널을 숨기며 `종료`는 실제 세션 정리를 요청한다. 역할과 Engine 정보는 연결 서버에서 조회하고, 기본 alpha6 서버와 alpha8 앱의 공유 호환성 오류는 로컬 실행과 별도로 표시한다.

이전 반응형 인수 실행 파일: `artifacts/releases/desktop-planning-responsive-alpha8/Release/automated_qa_desktop.exe`(repo 기준). Release 폴더 전체가 필요하며 기존 앱/Release는 보존한다. native 사용자 경로와 전체74회귀/1조건부skip, 실제 창 크기/textScaler 및 SDK를 포함한 manifest는 위 반응형 인수 기록에서 확인한다.

기존 프로젝트/QA·Codex 후보 작성 앱의 사용 흐름은 [Desktop 시작 안내](../../docs/desktop-ai-quickstart.md)를 참고합니다. 현재 앱 전용 pin은 `engine-runtime-pin.json`의 alpha.10이며 이전 alpha.6/alpha.8/alpha.9 설치와 Release를 보존합니다. 과거 [후보 작성 인수](../../docs/validation-desktop-ai.md)와 [초기 검증 기록](../../docs/validation.md)을 구분합니다. 이번 interactive Codex 모델 시험은 계정 사용량 제한으로 파일 수정에 도달하지 못했고 Claude는 로컬 미설치입니다. 준비 가이드와 실행 파일 탐지를 실제 모델 성공으로 표시하지 않습니다.

Flutter 사용자 Desktop의 기능별 MVVM/Provider 기반이다. pnpm workspace가 아니다. Flutter3.47.5/Dart3.13.4, provider6.1.5+1을 사용한다. toolchain.json과 pubspec.lock에 버전·해석 결과를 기록한다.

사용자가 블록/Flow 또는 XML으로 개별 테스트를 만들고 편집·저장·검증·명시 실행한다. 웹에서 받은 공용 XML도 같은 Engine compile 경로로 처리한다. 원문·노드·연결·반복 편집, 공개 CLI 검증/계획/실행/취소/결과, 디자인/UX 비교, Registry·Suite 수신과 진행 게시, 선택 조직 로그인을 제공한다. 구현과 실제 인수 상태는 [로컬 엔진 안내](../../docs/architecture/local-engine.md)와 [검증 기록](../../docs/validation.md)을 따른다. 실제 Slack 계정 및 Android/iOS 기기 인수는 로컬 fixture와 구분하며 Desktop 전체 Suite 일괄 실행을 구현했다고 표시하지 않는다.

app/providers가 MultiProvider로 Service→Repository→ChangeNotifier ViewModel→workbench coordinator를 조립하고 생성 자원을 종료한다. 실행 설정과 문서는 Provider VM이 소유하고, app/workbench의 상위 View가 기능을 조합한다. features의 models/views/view_models/repositories/services와 UI controller 수명은 분리한다. 상세 소유권·실행·검증은 [Flutter MVVM 안내](../../docs/architecture/flutter-mvvm.md)를 참고한다. 앱 자체는 서버 없이 실행되며 저장 성공을 테스트 성공으로 표시하지 않는다.

