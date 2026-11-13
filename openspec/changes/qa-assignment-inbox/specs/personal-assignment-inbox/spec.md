# Personal assignment inbox

## ADDED Requirements

### Requirement: Assignments pin published targets without execution

서버 SHALL 고정 QA/Suite version/hash와 활성 담당자를 별도 assignment로 저장하고 생성·수신으로 Engine Run/job/lease를 만들지 않아야 한다.

#### Scenario: Manager assigns an immutable Suite

- **WHEN** manager가 같은 프로젝트의 active 사용자에게 정확한 Suite version/hash를 배정한다
- **THEN** 개인 inbox에 그 고정 항목이 나타나고 실행은0건이며 다른 사용자의 inbox에는 노출되지 않는다

### Requirement: Work review is distinct from engine outcome

서버 SHALL assignment의 업무검토/반려/완료를 revision으로 관리하고 담당자의 자기검수를 거부해야 한다. 완료/반려는 기존 Engine 판정을 바꾸지 않아야 한다.

#### Scenario: Failed test is reviewed as completed work

- **WHEN** 다른 manager가 실패 근거를 확인한 뒤 in_review 업무를 completed로 전이한다
- **THEN** 업무는 완료되지만 linked Run의 failed 결과와 evidence는 불변이다

#### Scenario: Reassignment invalidates stale recipient actions

- **WHEN** 담당자가 바뀐 후 이전 담당자가 이전 revision으로 수신/검토요청한다
- **THEN** 요청은 거부되고 새 담당자의 업무와 기존 이력은 보존된다

### Requirement: Receipts and links require concrete identity

서버 SHALL 수신 receipt를 명시 acknowledgment로 기록하고 Run 연결 시 실제 owner/project/version을 검증해야 한다. Suite 일부 실행을 전체 완료 판정으로 합성해서는 안 된다.

#### Scenario: Fake or foreign run is linked

- **WHEN** 사용자가 존재하지 않거나 다른 프로젝트/담당자/version의 Run을 연결한다
- **THEN** 연결을 거부하고 업무 완료나 테스트 성공을 합성하지 않는다

### Requirement: Lifecycle and authorization remain current

서버 SHALL 새로운 배정·수신·링크에 현재 lifecycle과 active membership을 검사하고 폐기/비활성의 기존 이력을 삭제하지 않아야 한다.

#### Scenario: Target is withdrawn after assignment

- **WHEN** 배정된 고정 target이 폐기된다
- **THEN** 새로운 수신/실행 연결은 차단되고 담당자와 manager는 사유/원본 이력을 확인해 명시 업무 조치를 한다
