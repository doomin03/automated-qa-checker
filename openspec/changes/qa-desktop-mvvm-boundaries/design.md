# Design

## Context

현재 RunPanel은 EngineSettings를 매번 controller에서 만들고 source/apply 콜백으로 다른 feature의 비동기 결과를 적용한다. ScenarioEditorView의 controller와 ScenarioEditorViewModel.draft가 각각 원문을 보관하여 외부 적용·재마운트 동기화가 View 수동 처리에 의존한다. EngineRepository는 Run/Design VM이 공유하지만 Run VM이 dispose한다. Shared/Server/Organization VM도 주입 Repository를 종료하며 기본 생성과 외부 주입 소유권이 구분되지 않는다.

## Goals / Non-Goals

**Goals:** 설정·초안의 작업 공간 수명 보존, 늦은 결과의 안전한 폐기, 단순한 명시적 DI와 종료 순서, View의 표시·입력 역할 분리.

**Non-Goals:** 프로세스 재시작을 넘는 설정 영속화, 토큰 저장, 새 상태관리 라이브러리, 실행 DSL/HTTP 변경, 모든 StatefulWidget 제거, 외관 재설계.

## Decisions

### D1. 단일 설정과 문서 정본

EngineSettings를 별도 model로 분리하고 immutable copy/value 비교를 둔다. EngineSettingsViewModel은 설정·진단 platform·revision을 소유한다. 변경은 값을 실제 바꿀 때만 revision을 증가시킨다. ScenarioEditorViewModel은 문서 revision을 노출하며 파일 열기/외부 적용도 정본 문서를 변경한다. 원문 controller는 Provider의 현 문서를 투영하고 입력만 VM에 전달한다. controller/selection/focus/IME는 VM으로 옮기지 않는다. 화면 재마운트는 같은 Provider scope의 설정·문서를 보존하지만 AppProviders 전체 제거 후 새 scope는 초기값이다.

### D2. 상위 작업 공간 조합

`app/workbench/view_models/workbench_view_model.dart`에 업무 순서만 조합하는 coordinator를 둔다. 기존 VM의 plan/events/result/auth/공유 상태를 복사하지 않고 주입된 VM에 위임하며 자기 작업의 generation/적용 오류만 소유한다. 실행 설정 snapshot+문서 revision+작업 generation을 잡은 뒤 await하고, dispose/문서 변경/설정 변경/새 작업이면 결과를 적용하지 않는다. 문자열이 이전 값으로 돌아와도 revision 변경으로 오래된 결과를 거부한다. 수신→초안, 기준 연결→초안, preset/repeat/export→초안, Flow→원문, 로그인↔공유 연결을 이 계층에서 조합한다.

낮은 feature에서 app coordinator를 import하지 않는다. RunPanel/SharedPanel/전체 편집 화면처럼 여러 기능을 조립하는 상위 View를 `app/workbench/views`로 옮긴다. run_review 하위 View는 설정·진단·액션·결과를 표시하는 작은 컴포넌트다. FlowEditor는 동일 feature의 편집 VM을 사용하고 작업 공간에 대한 명시 입력/명령 callback으로만 연동한다. 이 콜백은 소스 정본 getter나 임의 apply 실행권이 아니라 `원문 불러오기/계획 불러오기/Flow 적용` 같은 사용자 명령이다.

### D3. UI 수명과 비동기 수명 분리

RunPanel은 Stateless 조합 View를 목표로 한다. 동기화된 입력 field는 작은 Stateful View에서 controller를 소유하고 값이 달라질 때만 투영한다. dialog는 View가 열고 typed 결과를 coordinator 명령에 전달한다. 취소된 dialog는 업무를 시작하지 않는다. Flow의 선택/drag preview, JSON dialog 편집 오류는 UI 상태로 유지한다. ServerPanel의 origin 입력 초안과 SharedPanel의 원문 token은 제출 전 UI 입력이며 전역 영속 설정으로 승격하지 않는다. SharedPanel은 repository.identity/token을 탐색하지 않고 auth VM의 읽기용 getter와 coordinator의 인증된 연결 명령을 사용한다.

### D4. composition root의 자원 소유권

Provider가 기본 생성한 EngineCliService/OrganizationService/SharedRepository/ServerRepository를 Provider dispose callback에서 정확히 한 번 정리한다. Repository가 빌려 받은 Service를 종료하지 않는다. ChangeNotifierProvider는 VM을 종료하지만 VM은 자기 listener·generation만 정리한다. Design과 Run이 공유하는 EngineRepository는 한 VM 제거로 종료되지 않는다. 외부 주입한 Service/Repository/Catalog는 기본 borrowed이며 호출자가 종료한다. 테스트는 이 규약을 따른다. lazy 생성되지 않은 자원은 임의 생성해 dispose하지 않는다. Provider 선언 순서를 service→repository→VM→coordinator로 두어 상위 구독부터 역순으로 해제한다.

### D5. 관련 화면 조사와 적용 범위

| 현재 위치 | 관찰 | 적용 |
| --- | --- | --- |
| RunPanel | 설정·플랫폼과 Run/Design/Flow 조합·결과 렌더가 혼재 | 상위 workbench 조합 + 설정 VM + 작은 결과/진단/입력 View |
| ScenarioEditorView | 원문 controller와 draft 수동 이중 동기화 | 상위 화면 배치, draft projection·revision, 파일 확인 dialog 유지 |
| SharedPanel | Auth Repository 탐색·token 선택·disconnect/login·XML apply | 상위 조합 View, auth getter 및 coordinator 명령; token은 UI 메모리 |
| FlowEditorView | 원문 parse/plan 불러오기/apply 및 graph 표시 | feature 편집·gesture 유지, 작업 공간 연동은 명시적 입력/명령 |
| ServerPanel | controller와 한 VM connect 호출 | UI 수명 유지, Repository dispose만 composition root로 이동 |
| AppProviders | 외부 주입과 기본 생성의 종료 책임 불명확 | 소유/borrowed 구분과 exactly-once 종료 테스트 |

### D6. 계약·빌드 보존

Engine alpha.6/contract0.3.0-draft.1와 HTTP/Agent hash는 불변이다. 기존 PID22828과 `artifacts/releases/alpha6`를 종료/덮어쓰지 않는다. 새 앱 release는 별도 `artifacts/releases/alpha6-mvvm/Release`로 보존하고 전체 파일/app.so hash와 직접 시작한 별도 프로세스의 native smoke만 기록한다.

## Risks / Trade-offs

- [Provider scope를 넓히면 상태 유지가 길어짐] → 앱 세션 수명만 유지하고 token/secret은 설정 model에 추가하지 않는다.
- [coordinator가 새 거대 VM이 될 수 있음] → 기존 기능 상태를 복제하지 않고 순서·snapshot guard·위임만 담당한다.
- [controller 동기화가 selection/IME를 바꿀 수 있음] → 동일 text면 갱신하지 않고 외부 변경 때만 유효 selection을 적용하는 field 단위 테스트를 둔다.
- [기존 VM 직접 생성 테스트의 cleanup 규약 변경] → 소유자가 명시 정리하도록 테스트를 바꾸고 borrowed/exactly-once/하위 VM 제거 회귀를 함께 둔다.

## Migration Plan

명세 strict와 관리 검토 → 설정/DI/coordinator → 화면 조립 및 stale guard → 집중 회귀와 기존 Flutter 전체 analyze/test → 별도 Windows release·사용자 프로세스 보존 → 문서·실제 task 완료 갱신 순서다. 기존 stable release는 그대로 남겨 복귀 가능하게 한다.
