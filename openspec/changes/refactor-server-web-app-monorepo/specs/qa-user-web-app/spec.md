# QA User Web App

## Purpose

웹을 사용자 공용 테스트 시나리오와 실행 진행을 다루는 앱으로 제공한다. Flutter Desktop으로 전달하는 선언형 정의와 실제 이벤트를 연결하면서 실행 엔진과 UI 상태의 소유를 분리한다.

## ADDED Requirements

### Requirement: Web UI dependency direction
웹 SHALL app/pages/widgets/features/entities/shared 방향과 slice 공개 API를 사용하며 공용 생성 SDK 및 domain adapter로 서버 데이터를 소비한다.

#### Scenario: Import a sibling slice or internal path
- **WHEN** 같은 레이어의 다른 slice 내부나 상위 레이어를 import한다
- **THEN** 경계 검사가 위치를 보고하며 실패한다

#### Scenario: Access server data
- **WHEN** 화면이 server health 또는 QA registry를 요청한다
- **THEN** UI가 endpoint/transport schema를 중복 정의하지 않고 공용 SDK 경계를 사용한다

### Requirement: User scenario distribution and role separation
웹 SHALL 사용자 공용 시나리오 선택·확인·XML 전달과 테스트 진행 조회를 제공한다. 관리자 게시·승인·권한 업무는 별도 권한 기능으로 구분한다.

#### Scenario: Export a user edited scenario
- **WHEN** 사용자가 공용 또는 직접 편집한 Blueprint를 XML로 내려받는다
- **THEN** 엔진 계약에 맞는 XML을 전달하고 실행은 시작하지 않는다

#### Scenario: Server unavailable during local observation
- **WHEN** 서버 연결이 실패한 상태에서 로컬 Blueprint/이벤트 파일을 연다
- **THEN** 파일 관찰은 가능하며 게시·공유 상태는 연결 실패로 표시한다

### Requirement: Explicit execution and subscription ownership
웹 SHALL 실행 판단을 엔진 결과에 위임하고 UI의 파일 구독·타이머·요청만 소유한다. 가져오기 또는 화면 진입만으로 엔진/driver를 생성하지 않는다.

#### Scenario: Import without mounting or execution
- **WHEN** 문서 모델을 import하거나 화면에서 QA 파일을 연다
- **THEN** 테스트 프로세스나 driver를 시작하지 않는다

#### Scenario: Repeated navigation and cleanup
- **WHEN** 진행 화면 진입·이탈·cleanup을 반복한다
- **THEN** 활성 구독/타이머는 한 화면의 것만 남고 반복 cleanup은 새 자원이나 예외를 만들지 않는다

### Requirement: Cancellation safe observation
웹 SHALL 비동기 파일 읽기 도중 문서를 바꾸거나 화면을 떠난 경우 이전 응답이 최신 화면 상태를 덮어쓰지 못하게 한다.

#### Scenario: Leave before reading completes
- **WHEN** 이벤트 읽기 완료 전에 문서 변경 또는 화면 해제가 발생한다
- **THEN** 이전 읽기의 결과를 무시하고 종료된 구독을 다시 시작하지 않는다

#### Scenario: Development remount
- **WHEN** React 개발 모드 setup/cleanup/setup이 반복된다
- **THEN** 최신 문서의 구독만 활성화한다

### Requirement: Evidence based and responsive progress
웹 SHALL container에 맞는 Blueprint 진행을 표시하며 실제 run/snapshot/sequence에 근거하지 않은 성공을 만들지 않는다. 변경 없는 polling만으로 전체 상태를 무제한 누적하지 않는다.

#### Scenario: Observe a failed run
- **WHEN** 실제 실패 이벤트와 실행하지 않은 분기가 있다
- **THEN** 실패와 미실행을 구분하고 업무 완료 여부와 테스트 판정을 혼합하지 않는다

#### Scenario: Resize and unchanged polling
- **WHEN** 화면 크기가 바뀌거나 동일 파일을 반복 읽는다
- **THEN** 그래프와 로그가 사용 가능하고 중복 이벤트가 누적되지 않는다
