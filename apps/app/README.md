# apps/app

현재 프로젝트/QA·실제 Codex 작성 앱은 [Desktop 시작 안내](../../docs/desktop-ai-quickstart.md)를 따릅니다. 앱 전용 Engine pin은 engine-runtime-pin.json의 alpha.8이며 서버/Agent와 기존 Release는 alpha.6을 보존합니다. [신규 인수 기록](../../docs/validation-desktop-ai.md)과 [이전 검증 기록](../../docs/validation.md)을 구분합니다.

Flutter 사용자 Desktop의 기능별 MVVM/Provider 기반이다. pnpm workspace가 아니다. Flutter3.47.5/Dart3.13.4, provider6.1.5+1을 사용한다. toolchain.json과 pubspec.lock에 버전·해석 결과를 기록한다.

사용자가 블록/Flow 또는 XML으로 개별 테스트를 만들고 편집·저장·검증·명시 실행한다. 웹에서 받은 공용 XML도 같은 Engine compile 경로로 처리한다. 원문·노드·연결·반복 편집, 공개 CLI 검증/계획/실행/취소/결과, 디자인/UX 비교, Registry·Suite 수신과 진행 게시, 선택 조직 로그인을 제공한다. 구현과 실제 인수 상태는 [로컬 엔진 안내](../../docs/architecture/local-engine.md)와 [검증 기록](../../docs/validation.md)을 따른다. 실제 Slack 계정 및 Android/iOS 기기 인수는 로컬 fixture와 구분하며 Desktop 전체 Suite 일괄 실행을 구현했다고 표시하지 않는다.

app/providers가 MultiProvider로 Service→Repository→ChangeNotifier ViewModel→workbench coordinator를 조립하고 생성 자원을 종료한다. 실행 설정과 문서는 Provider VM이 소유하고, app/workbench의 상위 View가 기능을 조합한다. features의 models/views/view_models/repositories/services와 UI controller 수명은 분리한다. 상세 소유권·실행·검증은 [Flutter MVVM 안내](../../docs/architecture/flutter-mvvm.md)를 참고한다. 앱 자체는 서버 없이 실행되며 저장 성공을 테스트 성공으로 표시하지 않는다.

