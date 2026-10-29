# Spec Delta

## Purpose

사용자가 웹의 공용 테스트 시나리오를 Flutter Desktop으로 전달하고, 자신의 XML 테스트를 작성·수정하여 실제 엔진으로 실행하며 근거가 있는 진행과 결과를 확인한다.

## ADDED Requirements

### Requirement: User application roles

시스템 SHALL 웹을 사용자용 공용 시나리오와 진행 확인 앱으로 제공하고 Desktop을 개별 테스트 개발·실행 앱으로 제공한다. 관리 기능은 역할별 후속 기능으로 구분한다.

#### Scenario: Shared scenario handoff
- **WHEN** 사용자가 웹의 공용 XML을 내려받아 Desktop에서 연다
- **THEN** 시나리오를 편집할 수 있고 가져오기만으로 테스트를 실행하지 않는다

### Requirement: User authored XML

Desktop SHALL 사용자 지정 XML 전체를 붙여넣고 편집·저장할 수 있게 한다. 실행 스키마와 계획 검증은 고정된 엔진 계약을 이용하며 임의 스크립트 실행을 제공하지 않는다.

#### Scenario: Custom scenario
- **WHEN** 사용자가 XML을 수정하고 검증을 요청한다
- **THEN** 엔진의 validate와 plan 결과 또는 구체적인 오류를 표시한다

#### Scenario: Invalid scenario
- **WHEN** 선언되지 않은 action 또는 잘못된 XML을 입력한다
- **THEN** 검증 실패를 표시하고 실행을 시작하지 않는다

### Requirement: Web XML authoring export

웹 SHALL 현재 편집하고 계약 검증한 Blueprint를 엔진 공개 XML 표현으로 내려받게 한다. 정적 샘플에 한정하지 않으며 파싱·실행계획·adapter 제어는 엔진 책임이다.

#### Scenario: Edited blueprint export
- **WHEN** 사용자가 JSON의 이름이나 노드 설정을 수정하고 XML 내보내기를 요청한다
- **THEN** 수정 내용을 보존한 XML을 받고 엔진 import 결과가 해당 Blueprint와 의미상 같으며 자동 실행하지 않는다

### Requirement: Explicit local execution

Desktop SHALL 명시적 실행 요청에만 엔진을 인자 배열과 shell 비활성으로 호출하고 JSONL 이벤트와 결과를 표시한다. 가져오기·편집·저장·검증은 실행을 시작하지 않는다.

#### Scenario: Pass and fail
- **WHEN** 사용자가 유효한 웹 테스트의 실행을 요청한다
- **THEN** 실제 이벤트와 종료 결과를 표시하고 assertion 실패를 성공으로 처리하지 않는다

#### Scenario: Missing engine
- **WHEN** CLI 경로가 없거나 버전이 호환되지 않는다
- **THEN** 오류를 표시하며 실행 성공을 만들지 않는다

### Requirement: Evidence based progress

웹 SHALL Desktop이 생성한 실행 파일의 이벤트를 가져오거나 따라가며 진행을 표시한다. 첫 전달 방식은 파일 교환으로 표시하고 서버 동기화처럼 표현하지 않는다.

#### Scenario: Observe result
- **WHEN** 사용자가 같은 실행의 blueprint.json과 events.jsonl을 웹에서 연다
- **THEN** 기존 snapshot/run/sequence 검증 후 노드 진행을 표시한다
