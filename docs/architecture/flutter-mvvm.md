# Flutter MVVM과 Provider

2026-10-29 사용자 요청을 반영했다. 원본 모노레포 data/domain/presentation 책임을 기능별 MVVM으로 구체화했으며 원본 [이관 출처](../../openspec/changes/refactor-server-web-app-monorepo/integration.md)는 보존한다.

```text
apps/app/lib/
  main.dart
  app/qa_app.dart
  app/providers/app_providers.dart
  core/errors/draft_file_exception.dart
  features/scenario_editor/
    models/scenario_draft.dart
    views/scenario_editor_view.dart
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
| Service | 파일 IO. 후속 HTTP/엔진 CLI도 별도 service에서 처리 |
| app/providers | MultiProvider composition root. Service→Repository→ChangeNotifierProvider 조립과 VM dispose 소유 |

원본 data는 repositories/services, domain은 models와 필요한 업무 규칙, presentation은 views/view_models로 매핑한다. 현재 필요 없는 빈 network/use-case/config 계층은 생성하지 않았다. [Flutter 공식 MVVM 설명](https://docs.flutter.dev/app-architecture/guide)과 [Provider 문서](https://pub.dev/packages/provider)를 참고하며 Riverpod로 바꾸지 않는다.

현재 초안 원문을 편집하고 사용자가 입력한 .xml/.json 경로에서 파일을 열거나 저장한다. 저장하지 않은 초안을 다른 파일로 바꿀 때 확인한다. 첫 경량 구현은 경로 입력 방식이며 OS filepicker plugin은 사용하지 않는다. 서버와 엔진은 필요하지 않다. 엔진 문법 검증·실행·block builder는 미구현이고 성공 placeholder를 제공하지 않는다.

파일은 UTF-8 1 MiB 제한이다. 읽기는 최대 1 MiB+1 byte만 읽어 초과를 거부한다. 저장은 같은 디렉터리의 임시 파일에 flush 후 rename하며 쓰기/교체 실패 시 기존 파일을 보존한다. Windows 파일 잠금 상황의 실패 보존을 테스트했다. 문서 원문과 예외 내부 내용을 로그에 출력하지 않는다. 저장 버튼은 기존 경로를 사용자가 명시한 저장 요청으로 덮어쓰므로 필요한 다른 버전은 다른 경로를 입력한다.

ViewModel은 busy 중 중복 파일 액션을 거부하고 수정 입력을 막는다. 실패하면 초안/dirty를 유지하고 성공 때만 저장 기준을 바꾼다. 비동기 완료 전에 Provider가 dispose하면 결과를 적용하거나 notify하지 않는다. View controller는 View가 정리한다.

## 도구와 실행

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

출력 exe는 apps/app/build/windows/x64/runner/Release/automated_qa_desktop.exe다. 배포할 때 exe만 복사하지 말고 같은 Release 디렉터리의 DLL/data를 함께 유지한다. 실제 검사 결과는 [검증 기록](../validation.md)에 남긴다. 이 shell 인수는 상위 모노레포 task6.1 및 qa-flow-editor2.1의 공통 증거이며 생성 SDK/API/엔진 연결 또는 전체 P2 완료가 아니다.
