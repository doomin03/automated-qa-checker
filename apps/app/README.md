# apps/app

Flutter 사용자 Desktop의 기능별 MVVM/Provider 기반이다. pnpm workspace가 아니다. Flutter3.47.5/Dart3.13.4, provider6.1.5+1을 사용한다. toolchain.json과 pubspec.lock에 버전·해석 결과를 기록한다.

제품 목표는 사용자가 블록/Flow 또는 XML으로 개별 테스트를 만들고 편집·저장·검증·명시 실행하는 것이다. 웹에서 받은 공용 XML도 같은 엔진 compile 경로로 처리한다. 현재 구현은 원문 초안 편집과 경로 입력 기반 XML/JSON 파일 열기·저장까지다. 엔진 검증·실행, 블록 editor, 서버 API는 연결하지 않았다.

app/providers가 MultiProvider로 Service→Repository→ChangeNotifier ViewModel을 조립한다. features/scenario_editor의 models/views/view_models/repositories/services를 따른다. 상세 책임·실행·검증은 [Flutter MVVM 안내](../../docs/architecture/flutter-mvvm.md)를 참고한다. 앱 자체는 서버 없이 실행되며 저장 성공을 테스트 성공으로 표시하지 않는다.

