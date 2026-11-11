# qa-shared-suites

## ADDED Requirements

### Requirement: Ordered pinned Suite input

시스템은 동일 프로젝트의 published Blueprint version/hash를 고유 caseId의 ordered 목록으로 고정하고 stopOnFailure를 보존해야 한다(SHALL). 호환하지 않는 Engine 버전과 중복 caseId는 거부해야 한다(SHALL).

#### Scenario: 잘못된 고정 입력

- **WHEN** 다른 프로젝트·잘못된 hash·미게시 또는 호환하지 않는 버전으로 Suite 초안을 요청한다
- **THEN** 저장하지 않고 오류를 반환하며 어떤 테스트도 실행하지 않는다

### Requirement: Independent review and immutable publication

시스템은 작성자와 다른 활성 qa_manager의 검수를 발행 transaction에서 재확인하고 발행된 Suite를 변경·삭제하지 못하게 해야 한다(SHALL). 같은 idempotency key는 같은 payload만 허용해야 한다(SHALL).

#### Scenario: 동시 발행과 검수자 권한 해제

- **WHEN** 같은 발행 요청이 반복되거나 검수자의 membership이 해제된다
- **THEN** 반복 요청은 같은 발행본을 반환하고 권한 없는 검수에 의존한 신규 발행은 거부한다

### Requirement: Explicit execution materialization

Suite 조회·pin·수신은 실행하지 않아야 한다(SHALL). 명시 실행 요청만 ordered Registry XML을 공개 Engine plan으로 검증한 뒤 기존 Agent queue에 고정해야 한다(SHALL).

#### Scenario: Suite pin 후 실행 요청

- **WHEN** 사용자가 Suite 버전을 pin하고 이후 별도로 실행을 요청한다
- **THEN** pin만으로 실행하지 않고 요청된 버전/hash/순서/policy를 Agent 입력에 보존한다
