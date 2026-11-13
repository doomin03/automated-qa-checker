# Flutter MVVM과 Provider

2026-10-29 사용자 요청을 반영했다. 원본 모노레포 data/domain/presentation 책임을 기능별 MVVM으로 구체화했으며 원본 [이관 출처](../../openspec/changes/refactor-server-web-app-monorepo/integration.md)는 보존한다.

```text
apps/app/lib/
  main.dart
  app/qa_app.dart
  app/providers/app_providers.dart
  app/workbench/view_models/workbench_view_model.dart
  app/workbench/views/{scenario_editor_view,run_panel,shared_panel}.dart
  core/errors/draft_file_exception.dart
  core/widgets/model_text_field.dart
  features/scenario_editor/
    models/scenario_draft.dart
    views/flow_editor_view.dart
    view_models/scenario_editor_view_model.dart
    repositories/scenario_repository.dart
    services/scenario_file_service.dart
```

| 책임 | 규칙 |
| --- | --- |
| Model | immutable 편집 상태. 엔진 DSL/schema를 재정의하지 않음 |
| View | UI/controller 수명과 사용자 확인. 파일/네트워크/Process 직접 접근 금지 |
| ViewModel | ChangeNotifier 상태와 액션, busy/dirty/error/notice. BuildContext/IO 객체 비의존 |
| Repository | 데이터 읽기·저장 경계. Service 결과를 모델로 전달 |
| Service | 파일 IO와 독립 engine CLI. HTTP는 생성 SDK를 Repository가 소비 |
| app/providers | MultiProvider composition root. Service→Repository→ChangeNotifierProvider→workbench 조립, 생성 자원 dispose 소유 |
| app/workbench | 여러 기능의 사용자 작업 순서를 조합하는 VM과 상위 조합 View. 기능 상태를 복제하지 않음 |

원본 data는 repositories/services, domain은 models와 필요한 업무 규칙, presentation은 views/view_models로 매핑한다. 현재 필요 없는 빈 network/use-case/config 계층은 생성하지 않았다. [Flutter 공식 MVVM 설명](https://docs.flutter.dev/app-architecture/guide)과 [Provider 문서](https://pub.dev/packages/provider)를 참고하며 Riverpod로 바꾸지 않는다.

현재 초안 원문을 편집하고 사용자가 입력한 .xml/.json 경로에서 파일을 열거나 저장한다. 저장하지 않은 초안을 다른 파일로 바꿀 때 확인한다. 첫 경량 구현은 경로 입력 방식이며 OS filepicker plugin은 사용하지 않는다. 원문 파일 편집에는 서버와 엔진이 필요하지 않다. run_review는 고정 Engine CLI validate/plan/run/cancel을, Flow ViewModel은 공개 schema 기반 기본 폼·연결·undo/redo를 제공한다. server_connection은 선택 health 확인, shared_scenarios는 Registry·Suite 수신과 진행 게시, organization_login은 선택 조직 인증을 담당한다. 실제 Slack 계정과 모바일 기기 인수는 로컬 fixture 검증과 구분한다. [로컬 엔진 연결](local-engine.md)을 따른다.

파일은 UTF-8 1 MiB 제한이다. 읽기는 최대 1 MiB+1 byte만 읽어 초과를 거부한다. 저장은 같은 디렉터리의 임시 파일에 flush 후 rename하며 쓰기/교체 실패 시 기존 파일을 보존한다. Windows 파일 잠금 상황의 실패 보존을 테스트했다. 문서 원문과 예외 내부 내용을 로그에 출력하지 않는다. 저장 버튼은 기존 경로를 사용자가 명시한 저장 요청으로 덮어쓰므로 필요한 다른 버전은 다른 경로를 입력한다.

ViewModel은 busy 중 중복 파일 액션을 거부하고 수정 입력을 막는다. 실패하면 초안/dirty를 유지하고 성공 때만 저장 기준을 바꾼다. 비동기 완료 전에 Provider가 dispose하면 결과를 적용하거나 notify하지 않는다. View controller는 View가 정리한다.

## 2026-10-31 작업 공간 경계 리팩터

`RunPanel`은 상위 workbench의 Stateless 조합 View다. 실행 설정·진단 플랫폼은 `EngineSettingsViewModel`, 문서 정본은 `ScenarioEditorViewModel`이 소유한다. `ModelTextField`는 정본을 표시하는 controller·selection·IME 수명만 소유하며 같은 값이면 controller를 다시 쓰지 않는다. 화면 재마운트는 같은 Provider scope의 값을 유지한다. 앱 종료 후 디스크 영속화는 추가하지 않았다.

Workbench VM은 validate/run/cancel과 기준 연결·preset·반복·수신·Flow 적용·조직 로그인/공유 연결을 조합한다. 실행 결과나 인증 상태를 중복 보관하지 않는다. 변환 시작과 dialog 시작의 문서/설정 revision을 확인하므로 같은 문자열로 되돌아오는 ABA 변경, 이전 설정의 진단 응답·오류, 종료 이후 완료를 현재 결과로 적용하지 않는다. 실행 계획은 설정 변경 후 다시 검증해야 한다.

하위 feature는 app/workbench를 import하지 않는다. feature의 기본 폼·graph gesture·dialog·선택 상태는 그대로 유지하며 StatefulWidget 자체를 오류로 취급하지 않는다. SharedPanel의 제출 전 token/입력, ServerPanel의 연결 주소 초안은 UI 수명에 속한다. 실제 token을 설정 model이나 파일에 추가 저장하지 않는다.

AppProviders가 기본 생성한 Engine/Organization Service와 Shared/Server/Organization Repository는 composition root가 종료한다. Repository가 주입 Service를 종료하거나 VM이 주입 Repository를 종료하지 않는다. VM은 자기 구독과 알림만 정리한다. 외부 `engineService`/`organizationService`/`repository`/`blueprintCatalog`는 borrowed이며 호출자가 소유한다. `engineServiceFactory`의 반환 객체는 앱 소유다. 주입은 같은 AppProviders scope 안에서 고정이며 교체할 때 새 key/scope를 만든다. Provider.create가 인자 변경마다 서비스를 교체한다고 가정하지 않는다. 생성되지 않은 lazy 자원은 종료를 위해 생성하지 않는다.

진행·인수는 [qa-desktop-mvvm-boundaries](../../openspec/changes/qa-desktop-mvvm-boundaries/tasks.md)를 따른다. 이전 alpha.6 실행 중 앱과 stable Release를 보존하고 새 빌드는 별도 `artifacts/releases/alpha6-mvvm/Release`로 검증한다.

## 도구와 실행

### 다중 터미널과 공개 작성 기능 (2026-11-12)

`TerminalWorkbenchViewModel`은 QA별 writer epoch와 최대 8개 세션의 수명만 관리한다. 각 `TerminalSessionViewModel`은 별도 TerminalService/Terminal/감시·후보를 소유하며 숨김/다른 QA 선택은 프로세스 종료가 아니다. pool은 새 factory Service를 종료하고 외부 주입 첫 Service는 composition root의 기존 borrowed 정책을 따른다. dock의 keyed registry는 세션별 UI controller를 소유하며 dialog/inline 중 활성 view 하나에만 연결한다. 문서/설정·writer·모드 revision은 후보의 최종 적용 gate이며 단순 화면 선택은 실행 의미를 바꾸지 않는다.

앱 전용 alpha.9 작성 기능은 `DocumentTemplateViewModel`과 `DocumentAuthoringRepository`가 공개 `EngineDocumentAuthoring` 인터페이스로 소비한다. 별도 Service는 실행 중인 RunVM의 표시/취소 상태를 침범하지 않는다. Engine가 생성·합성·검증 의미를 소유하고 Checker는 폼/asset 출처/sidecar/후보 stale/사용자 저장을 소유한다. Dart 합성 compiler fallback은 없다. [설계와 실제 검증](../validation-multi-terminal-workbench.md)을 따른다.

Flutter3.47.5의 공식 tag revision `6a19cca56475dbfba1478ee68d7bd0c2ef891da1`, 내장 Dart3.13.4, provider6.1.5+1 exact와 lockfile을 사용한다. Provider의 공식 SDK 범위 Dart>=2.12.0<4.0.0/Flutter>=1.16.0 안에서 pub get/analyze/test로 확인한다.

저장소 루트에서 로컬 SDK로 실행한다. 글로벌 PATH나 Flutter config를 변경하지 않는다.

```powershell
Set-Location apps/app
& C:/workspace/QA/.tools/flutter-3.47.5/bin/flutter.bat pub get --enforce-lockfile
& C:/workspace/QA/.tools/flutter-3.47.5/bin/flutter.bat analyze
& C:/workspace/QA/.tools/flutter-3.47.5/bin/flutter.bat test
& C:/workspace/QA/.tools/flutter-3.47.5/bin/flutter.bat build windows --release
& C:/workspace/QA/.tools/flutter-3.47.5/bin/flutter.bat run -d windows
```

출력 exe는 apps/app/build/windows/x64/runner/Release/automated_qa_desktop.exe다. 배포할 때 exe만 복사하지 말고 같은 Release 디렉터리의 DLL/data를 함께 유지한다. 실제 검사 결과는 [검증 기록](../validation.md)에 남긴다. 최초 shell 인수는 상위 모노레포 task6.1 및 qa-flow-editor2.1의 공통 증거이며 후속 엔진·SDK·Registry·작업 공간 리팩터 인수와 각각 구분해 기록한다.
