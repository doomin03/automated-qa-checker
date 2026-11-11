# Agent 증거 전달

## Purpose

독립 Engine이 생산한 사건과 결과를 변경하지 않고 서버에 전달하며 요청 유실·재시작·부분 업로드를 추적한다. 서버 수신 상태, 실제 Engine 판정, 기기 정리 상태와 증거 정합성을 구분해 미실행이나 전달 실패가 성공으로 표시되지 않게 한다.

## ADDED Requirements

### Requirement: Independent transport and engine identities
전송 envelope SHALL executionId/leaseId/fence와 caseId/deliverySequence를 소유하고 Engine event의 runId/attempt/sequence를 불변 보존한다. case의 실제 run.started 이후 해당 run identity와 Blueprint hash를 고정해야 한다. Engine 실행 schema는 공개 배포물로 검증하며 Checker가 재정의하면 안 된다.

#### Scenario: Ordered cases use separate Engine runs
- **WHEN** 배정의 각 case가 독립 Engine runId와 attempt1로 시작한다
- **THEN** case별 identity를 별도로 고정하고 deliverySequence는 배정 전체에서1부터 증가한다. 서버 jobAttempt로 Engine attempt를 덮어쓰지 않는다.

#### Scenario: Case identity switches midstream
- **WHEN** 같은 case가 다른 Engine runId/attempt/hash 또는 미등록 caseId의 event를 전달한다
- **THEN**409로 배치를 거부하고 기존 mapping을 유지한다.

### Requirement: Durable atomic event acknowledgement
Agent SHALL event를 네트워크 전송 전에 outbox에 영속화하고 서버는 batch를 원자적으로 저장한 뒤 acceptedThrough를 반환해야 한다. 같은 deliverySequence/정규화 payload는 멱등이며 다른 payload·gap·Engine sequence/state 오류는409다. 확인 전 outbox를 삭제하면 안 된다.

#### Scenario: Response loss after append
- **WHEN** batch 저장 후 응답이 유실되어 Agent가 같은 outbox를 재전송한다
- **THEN** 새 event를 만들지 않고 동일 또는 더 높은 저장 cursor를 반환한다. Agent는 확인된 cursor 이하만 제거한다.

#### Scenario: Invalid tail in a batch
- **WHEN** 앞 event는 유효하지만 뒤 event에 gap 또는 잘못된 node transition이 있다
- **THEN** 전체 batch를 거부하며 이전 acceptedThrough를 유지한다.

### Requirement: Reconcile before restart execution
Agent SHALL 부팅 후 claim/실행 전에 reconcile하고 서버는 요청에 나열된 lease뿐 아니라 해당 Agent의 서버 측 outstanding lease도 반환해야 한다. 응답은 resume/cancel/quarantine/observe 결정과 서버 cursor를 명시해야 한다. 새 instance에는 실행 resume을 허용하면 안 된다.

#### Scenario: Local state lost a successful claim
- **WHEN** Agent 상태에 lease가 없지만 서버에 성공한 claim이 존재한다
- **THEN** outstanding lease를 응답에 포함하고 Agent는 새 실행을 시작하지 않는다. 기존 owner 확인·취소·정리가 먼저다.

#### Scenario: Expired delivery remains durable
- **WHEN** 만료된 lease의 미전송 outbox나 terminal result가 발견된다
- **THEN** 정상 실행 event/result로 몰래 수용하거나 삭제하지 않고 reconcile에서 요약·정리 상태를 보고하며 격리된 local 증거를 보존한다.

#### Scenario: Quarantined historical evidence
- **WHEN** expired/quarantined/closed lease의 원본 증거를 historical-evidence 경로로 전송한다
- **THEN** 등록 Agent와 원래 owner/lease/fence/case/schema를 검증해 별도 history receipt로 멱등 보관한다. 정상 cursor, 실행권, TTL, 자원 lock과 정리 확정 상태는 변경하지 않는다.

### Requirement: Completion separates execution and cleanup
complete SHALL caseResults와 executionStatus, cleanupState, artifactManifest를 분리하고 동일 canonical body 재시도를 멱등 처리한다. 실제 Engine terminal event/result가 있는 case만 caseResults에 포함해야 한다. 완료 수신을 증거 bytes 검증완료나 cleanup 성공으로 간주하면 안 된다.

#### Scenario: Preflight blocked before Engine start
- **WHEN** target/resource/preflight가 실패해 run.started가 없다
- **THEN** executionStatus blocked와 사유만 보고하고 caseResults는 빈 배열이다. 가짜 Engine result나 passed outcome은 생성하지 않는다.

#### Scenario: Cleanup unknown after terminal event
- **WHEN** 실제 Engine terminal 결과를 받았지만 child/resource 종료를 확정하지 못한다
- **THEN** 결과는 외부 수신 상태로 보존하고 execution/resource는 quarantine으로 남으며 다음 claim을 허용하지 않는다.

### Requirement: Case scoped bounded artifact transfer
artifact SHALL caseId, 논리 이름, byte size, SHA-256, MIME, lease/fence에 결합돼야 한다. 서버 opaque artifactId만 저장 경로를 결정하며 파일당10MiB·execution당64MiB·HTTP body16MiB 제한과 원자 bytes 저장을 적용해야 한다. complete 수신과 artifact 업로드 완료는 별도 상태다.

#### Scenario: Partial upload and retry
- **WHEN** 일부 artifact만 업로드한 뒤 연결이 끊겼다가 동일 holder가 재전송한다
- **THEN** 동일 ID/hash bytes는 멱등 수용하고 누락된 증거는 missing으로 유지한다. 다른 case/fence/hash의 덮어쓰기는 거부한다.

#### Scenario: External path or wrong bytes
- **WHEN** artifact에 절대 경로·UNC·상위 경로 또는 hash/size 불일치 bytes가 있다
- **THEN**400 또는413으로 거부하고 임의 서버 파일을 읽거나 이전 증거를 변경하지 않는다.

### Requirement: Versioned contract and explicit verification status
Checker SHALL versioned HTTP 계약·fixture·hash를 공개하고 Engine은 공개 artifact만 소비해야 한다. protocolVersion 불일치를 실행 전에 거부하고 외부 Engine outcome, executionStatus, cleanupState, evidenceStatus를 구분해야 한다. verified는 제출 증거 정합성일 뿐 원격 실행 신뢰 보증이 아니다.

#### Scenario: Contract or release mismatch
- **WHEN** Agent protocolVersion 또는 허용 Engine version/contract/manifest hash가 맞지 않는다
- **THEN**claim을409로 거부하며 child를 실행하지 않는다.

#### Scenario: Evidence not yet complete
- **WHEN** terminal outcome은 passed지만 필수 artifact bytes가 없다
- **THEN**reportedOutcome은 보존하되 evidenceStatus는 missing으로 표시하고 검증완료를 합성하지 않는다.
