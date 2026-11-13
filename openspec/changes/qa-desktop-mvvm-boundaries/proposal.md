# Proposal

## Why

RunPanel은 Provider의 RunViewModel을 사용하지만 설정 정본·플랫폼 선택·여러 기능의 비동기 결과 적용까지 400줄 이상의 View에 모여 있다. 설정 재마운트 손실과 초안 변경 후 늦은 결과 적용을 막고, 공유 Repository를 특정 VM이 dispose하는 소유권을 composition root에서 명확히 해야 한다.

## What Changes

- immutable 실행 설정과 Provider 설정 VM을 분리하고 설정 revision·진단 대상의 정본을 화면 밖에 둔다.
- app workbench VM이 Scenario/Run/Design/Flow/Shared/Auth 액션을 조합한다. View의 source/apply 콜백과 직접 Repository 탐색을 제거하고 문서·설정 revision을 대조해 늦은 결과를 거절한다.
- RunPanel을 설정·액션·진단·결과 표시 컴포넌트로 분리한다. controller/focus/dialog/선택·드래그 상태는 필요한 작은 Stateful View에 남긴다.
- AppProviders에서 기본 생성한 Service/Repository의 소유·종료를 한 번만 처리하고 외부 주입 객체는 빌려 쓰는 것으로 명시한다. VM은 자신의 상태·구독만 정리한다.
- 관련 ScenarioEditor/SharedPanel/FlowEditor와 테스트 DI를 같은 경계로 정합한다. Engine/HTTP 계약과 기능·외관은 유지한다.

## Capabilities

### New Capabilities

- qa-desktop-workbench-state: 화면 재마운트와 비동기 작업에서 설정·문서 정본, 기능 간 액션 및 의존성 수명주기를 보존하는 Desktop 작업 공간.

### Modified Capabilities

없음. 아직 기준 specs로 archive하지 않은 기존 변경들의 기능 의미는 유지하며 새 인수는 화면 수명·작업 공간 상태 경계를 다룬다.

## Impact

- apps/app/lib/app/providers 및 app/workbench, run_review·scenario_editor·shared_scenarios·organization_login·server_connection 관련 VM/Views/Repository dispose와 앱 tests.
- dependsOn: qa-flow-editor, qa-user-web-desktop-handoff, qa-design-ux-demo, qa-auth-workflow, qa-shared-suites.
- counterpart: Engine 공개 CLI alpha.6 / execution contract0.3.0-draft.1. Checker HTTP/Agent artifacts의 bytes·hash 변경 없음.
- Flutter3.47.5/Dart3.13.4/provider6.1.5+1 유지, 새 상태관리·코드생성 패키지 없음.
- 기존 사용자 실행 PID22828과 artifacts/releases/alpha6는 보존한다. 새 빌드는 별도 Release 폴더로 인수한다. commit/push는 하지 않는다.
