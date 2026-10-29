# 사내 협업·예약·결과 관리

## ADDED Requirements

### Requirement: Shared XML distribution and automatic progress
사용자 웹과 Desktop은 공용 시나리오 XML의 권한별 버전 전달과 실행 진행 자동 수신을 SHALL 제공한다. 파일 handoff는 첫 단위이며 서버 전달·자동 동기화 인수로 대체하지 않는다.

#### Scenario: Receive a shared scenario
- **WHEN** 권한 있는 사용자가 공용 시나리오 버전을 Desktop으로 전달한다
- **THEN** version/hash를 검증한 정의를 받아 사용자 확인 후 편집·실행하며 수신만으로 실행하지 않는다.

#### Scenario: Reconnect progress stream
- **WHEN** Desktop/Agent 실행 중 웹이 재연결해 진행을 수신한다
- **THEN** 프로젝트 권한·run/attempt/snapshot을 확인하고 sequence 중복·gap을 처리해 실제 진행만 표시한다.

### Requirement: Scoped identity and immutable registry
서버는 OIDC 자체 session과 프로젝트 RBAC를 강제하고 발행 버전을 불변으로 SHALL 보관한다.

#### Scenario: Supported path
- **WHEN** 관리자가 검수된 Suite를 publish하고 허용된 사용자가 내려받는다
- **THEN** 같은 version/hash와 dependency manifest를 받고 버전을 고정한다.

#### Scenario: Rejected or failure path
- **WHEN** 승인되지 않은 workspace 또는 타 프로젝트 사용자가 요청한다
- **THEN** 로그인 또는 resource 접근을 거부하고 감사 기록을 남긴다.

### Requirement: Idempotent scheduled execution
scheduler는 timezone/DST 정책과 occurrence uniqueness 및 device lease를 SHALL 적용한다.

#### Scenario: Supported path
- **WHEN** 같은 schedule occurrence가 중복 전달된다
- **THEN** 논리 run 하나만 배정되고 유효 lease 한 개로 기기를 제어한다.

#### Scenario: Rejected or failure path
- **WHEN** Agent offline 또는 lease 상실이 발생한다
- **THEN** 미실행/환경오류를 기록하고 성공 결과를 만들지 않는다.

### Requirement: Replay and comparable reports
플랫폼은 event replay를 중복 제거하고 비교 가능한 baseline만 회귀 계산에 SHALL 사용한다.

#### Scenario: Supported path
- **WHEN** Agent가 동일 sequence를 다시 전송한다
- **THEN** 중복 event/result를 생성하지 않고 gap을 검사한다.

#### Scenario: Rejected or failure path
- **WHEN** Flow 버전/target/env가 정책상 비교 불가능하다
- **THEN** 비교 불가 사유를 표시하고 infra_error/unrun을 신규 테스트 실패로 집계하지 않는다.

### Requirement: Independent notification delivery
알림 서비스는 로그인 권한·전송 권한과 Run outcome을 분리해 SHALL 관리한다.

#### Scenario: Supported path
- **WHEN** Slack 알림 전송이 실패한다
- **THEN** 재시도/감사 상태만 바뀌고 Run outcome은 유지된다.

#### Scenario: Rejected or failure path
- **WHEN** artifact 접근권한이 없는 사용자가 다운로드한다
- **THEN** 다운로드를 거부하고 민감 증거를 노출하지 않는다.

