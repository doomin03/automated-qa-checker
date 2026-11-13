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

#### Scenario: Concurrent publication and restart
- **WHEN** 같은 버전이 동시에 발행되거나 같은 idempotency key를 재전송한 뒤 서버를 재시작한다
- **THEN** transaction과 unique constraint로 불변 버전 하나만 유지하고 같은 payload 재시도는 같은 응답, 다른 payload는409를 반환하며 데이터가 재시작 뒤에도 보존된다.

#### Scenario: Explicit pinned upgrade
- **WHEN** 사용자가 새 published version을 확인하고 업데이트를 요청한다
- **THEN** dependency manifest/version/hash와 이전 pin의 diff를 보여주고 명시 동의한 snapshot만 바꾼다. 기존 고정 snapshot은 오프라인에서도 유지하고 목록 pagination 및 변경 audit를 제공한다.

#### Scenario: Explicit local identity
- **WHEN** 로컬 기능 데모에서 등록한 개발 identity를 사용한다
- **THEN** 서버의 활성 사용자·프로젝트 역할을 확인하고 삭제 사용자와 타 프로젝트 접근을 거부한다. production에서는 local/test identity 구성이 있으면 startup을 거부한다.

### Requirement: Authenticated durable progress intake
서버 SHALL 인증된 HTTP polling과 영속 이벤트 수집을 제공하고 서버 run ID와 Engine run ID/attempt/snapshot을 고정한다. 수신된 외부 outcome과 증거 검증완료를 구분한다.

#### Scenario: Conflicting or late events
- **WHEN** 같은 sequence에 다른 payload, sequence gap 또는 terminal 이후 추가 이벤트가 전송된다
- **THEN**409를 반환하며 기존 이벤트를 변경하지 않는다. 같은 sequence의 같은 payload 재전송은 멱등이다.

#### Scenario: Evidence upload
- **WHEN** 권한 있는 Desktop이 결과 artifact bytes를 업로드한다
- **THEN** 서버는 크기/hash를 검증하고 서버 소유 경로에 원자 저장하며 result 참조와 모두 일치한 뒤에만 증거 검증완료로 표시한다. 클라이언트 경로를 서버 파일 경로로 사용하지 않는다.

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

