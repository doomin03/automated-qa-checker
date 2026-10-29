# Checker 담당 인계

2026-10-29. 사용자의 원본 MD 프로세스와 관리 에이전트/저장소별 담당 배정에 따른 기록이다. 관리 에이전트는 원본 기준, 우선순위, 교차 저장소 계약과 인수를 조정한다. Checker 담당은 이 저장소의 구현·검증·OpenSpec 상태를 보고하며 Engine이나 참조 저장소를 수정하지 않는다.

## 최신 관리 상태

후속 사용자 MVVM/Provider 요청과 관리 할당으로 최소 Flutter shell 구현을 재개해 완료했다. 기능별 Model/View/ViewModel/Repository/Service를 app MultiProvider에서 조립하며 provider6.1.5+1 exact를 사용한다. 원문 초안 편집·경로 입력 파일 열기/저장까지만 제공하고 엔진/블록/API는 미연결이다. [MVVM 구조·재현 명령](flutter-mvvm.md)과 [검증 증거](../validation.md)를 따른다.

Flutter3.47.5/Dart3.13.4 고정 SDK는 `C:/workspace/QA/.tools/flutter-3.47.5`, build artifact는 `C:/workspace/QA/automated-qa-checker/apps/app/build/windows/x64/runner/Release/automated_qa_desktop.exe`다. pub get --enforce-lockfile/analyze/7tests/release build 성공, Hidden exe의 native 창 초기화 smoke 확인(직접 OS UI 조작 검증 아님). 모노레포1/39, qa-flow-editor4/10, handoff1/9로 shell task만 완료했다. handoff3.4 제품 실행 인수와 전체 P2는 미완료다. 아래는 앞선 명세 이관 당시 기록이며 최신 shell 상태는 이 문단을 우선한다.

2026-10-29 후속 사용자 지시로 원본 모노레포 OpenSpec 전체 이관·정합을 제품 구현보다 먼저 한다. 아래의 이전 P2 착수 제안은 현재 구현 재개 지시가 아니다. 최신 역할은 웹=사용자 공용 XML·진행, Desktop=블록/Flow 또는 XML 테스트 개발·실행이며 관리업무는 권한별 기능이다.

이관본은 [refactor-server-web-app-monorepo](../../openspec/changes/refactor-server-web-app-monorepo/proposal.md)와 [출처·적용표](../../openspec/changes/refactor-server-web-app-monorepo/integration.md)에 있다. 기준은 원본 origin/feature325ca65, 후속 monorepo-setup2e515c는 비교 참고다. 5 capability·7결정·원본 번호별39task를 옮겼으며 제품 tasks는 0/39다. XML 첫 단위 qa-user-web-desktop-handoff는 0/9다. 새 제품 구현은 관리 검토·할당 후다.

현재 미검증 중간 제품 수정은 apps/web/src/entities/blueprint/xml.mjs와 apps/web/src/pages/blueprint/BlueprintPage.jsx 두 파일이다. 손실 없이 보존하고 테스트 완료로 표시하지 않았다. Flutter SDK는 QA .tools/flutter-3.47.5에 공식 tag6a19cca56475dbfba1478ee68d7bd0c2ef891da1로 초기화했고 --version은 Flutter3.47.5/Dart3.13.4를 반환했다. 앱 생성·analyze·Windows build는 수행하지 않았다. 과거 .tools Dart3.13.7 spike는 별도다.

## 기준과 판정

원본 위치: `C:/Users/Domin/Downloads/automated_qa_codex_instructions/automated_qa_codex_instructions`. README 및 master/checker/contracts/phases/worktree MD를 읽고 대조했다.

| 구분 | 내용 |
| --- | --- |
| 원본 고정 원칙 | 엔진 독립, Checker Flutter Desktop·관리자·단일 백엔드 모노레포, 실행 schema의 엔진 소유, 계약→엔진 검증→Checker 순서, 실제 E2E와 단계별 인수 |
| 원본 제안 | API route, schema 예제의 필드/명칭, transport 세부와 일부 상태 enum. 예제를 현재 지원 계약으로 간주하지 않음 |
| 이전 작업의 선택 | pnpm/Turbo, apps/app·web·server와 packages 경로, React/Nest 목표. 원본의 강제 기술 선택이 아닌 조사 후 채택 기록 |
| 현재 구현 | 웹 Blueprint JSON 검사/편집/내보내기, 노드·이벤트 재생/파일 따라가기, 공개 엔진 계약 version/hash 검사, JS 모노레포 검증 |
| 미구현 | Flutter 생성/빌드·노드 CRUD·로컬 CLI bridge, Nest API·OIDC·Registry·Scheduler·Agent. 원본 P2~P4 인수 미완료 |

[모노레포 정책](monorepo-policy.md)은 새 구조를 승인하는 문서가 아니라 위 구분과 현재 경계 검사 규칙을 모은 문서다. [플랫폼 설계](platform-design.md)의 세부 서버 정책도 실제 구현/인수와 구분한다. AI 입력 및 GUI의 역할은 [AI 정책](../ai-blueprint-policy.md)에 있으며 AI가 만든 결과만으로 PASS를 판정하지 않는다.

## 이번 인수

- `main`, HEAD `60b32ecdcbd9508865bae0cbd0a99cfacdec51ed`. 기존 작업은 미커밋 파일로 보존했다. 새 branch/worktree, commit/push, 참조 변경 없음.
- 관리 에이전트의 전체 `verify` 결과: 경계 회귀 6개, 이벤트 모델 7개, 실제 Chromium UI 1개, OpenSpec strict 4개, JS build 통과. 담당 인계 후 root dev HTTP와 문서/명세를 추가 확인했다. 구체 증거와 검증 한계는 [검증 기록](../validation.md)에 남긴다.
- `qa-monorepo-policy`는 JS 경계 검사·명령·문서 정비 범위다. 완료해도 `qa-flow-editor`의 Flutter 인수나 `qa-platform-services`의 서버 인수로 확대하지 않는다. 이번에는 spec sync/archive하지 않는다.

## P2 다음 최소 작업과 선행결정

1. 관리 에이전트는 Engine 담당 및 교차 확인에서 local-preview artifact/hash와 실제 브라우저 PASS/FAIL 증거를 확인하여 P2 준비 착수 게이트 통과로 결정했다. Engine 인계의 로컬 참고 경로는 `C:/workspace/QA/automated-qa-engine/docs/architecture/manager-handoff.md`다. 현재 Checker public contract pin은 `0.1.0-alpha.1`, SHA-256 `b9e125e56685243c82ab7e90a2f574a2538e0ea014f23f6d4035ff75fd0953f6`이며 `local-preview`, `runtimeIntegrationEnabled=false`다. 이 결정은 P2 완료, 정식 release 인수, 원격 배포 또는 CLI 통합 완료를 뜻하지 않는다.
2. Checker 담당의 다음 할당은 `qa-flow-editor` 2.1이다. 기존 `apps/app` 경로를 유지하면서 정확한 Flutter SDK 버전·내장 Dart·Windows 빌드 도구를 검증하고 최소 Desktop 앱을 생성한다. 기능 중심으로 진행하며 Flutter 분석/테스트와 Windows 실제 빌드를 각각 보고한다. 확인 전 임의 SDK 버전/Visual Studio 설치 상태를 단정하지 않는다.
3. SDK 생성 다음 최소 수직 단위는 공개 엔진 fixture 읽기→검증→인자 배열 CLI 호출→JSONL 이벤트/결과 표시다. Engine 담당과 CLI 실행 진입점/배포 artifact hash, 지원 version/schema, 인자·종료 코드·취소 및 artifact 경로 계약을 먼저 확인한다. 새 필드가 필요하면 Engine 계약 변경 절차로 돌린다.
4. 배포판 설치 방식은 관리 에이전트가 Engine 담당의 결과에 따라 선택한다. 개발 중 경로가 필요하면 untracked local config로만 설정하고 CI/release는 고정 artifact를 사용한다. 엔진 소스 복사나 커밋된 `file:` dependency는 추가하지 않는다.
5. 이 최소 단위 후 TC/Flow CRUD·drag/drop·undo/redo·capability 선택과 실제 PASS/FAIL round trip을 이어간다. 앱 shell이나 이벤트 화면만으로 원본 P2 exit criteria를 완료 처리하지 않는다. Nest/OIDC/예약은 후속 단계다.

현재 `flutter`, `dart`는 PATH에서 발견되지 않는다. 이전 Engine spike용 로컬 Dart `C:/workspace/QA/.tools/dart-3.13.7/dart-sdk/bin/dart.exe`의 실행 버전은 3.13.7로 확인했다. 독립 Dart SDK는 Flutter SDK/Windows Desktop toolchain의 대체 증거가 아니다. Flutter 또는 Visual Studio를 새로 설치하거나 전체 디스크에서 SDK를 찾는 작업은 이번 인계에 포함하지 않았다.
