# Agent 실행권

## Purpose

등록된 Agent와 부팅 instance에 실행권을 한정하고 기기 자원의 독점·만료·취소·정리 상태를 보존한다. 네트워크 재시도나 재시작으로 같은 물리 자원에서 두 실행이 겹치지 않도록 서버와 독립 Agent의 관측 가능한 계약을 정의한다.

## ADDED Requirements

### Requirement: Audited operator recovery
The Checker SHALL restrict operator recovery to project qa_managers and expired or quarantined leases. Recovery SHALL require explicit stopped-process/session confirmations, exact resource/fence, reason and idempotent request identity. It SHALL atomically audit recovery, increment the resource fence, release ownership and retire the old instance while preserving QA results and evidence status.

#### Scenario: Recovery is observed without execution rights
- **WHEN** a recovered lease appears in reconcile
- **THEN** its directive is observe and operatorRecovery contains id, confirmedAt, priorFence equal to lease.fence and a greater newFence; deliveryClosed is false and no execution permission is granted

#### Scenario: Wrong resource or active lease recovery
- **WHEN** a caller attempts recovery while the lease is active or a different lease now owns the resource
- **THEN** recovery is rejected and resource ownership remains unchanged

#### Scenario: Replayed recovery request
- **WHEN** the same authorized requestId and payload are submitted again
- **THEN** the immutable recovery record is returned without incrementing the fence again, while a changed payload is rejected

#### Scenario: Closed and recovered leases share an old instance
- **WHEN** an old instance owns a closed lease with an unacknowledged receipt and another lease with a verified operator recovery
- **THEN** release still verifies the actual closed receipt while excluding the recovered lease from required completion receipts, and never fabricates a receipt for the recovered lease

### Requirement: Registered agent identity and single instance ownership
서버 SHALL 사용자 세션과 구분한 등록 Agent credential을 검사하고 agentId, 활성 instanceId, 프로젝트·capability·resource allowlist를 강제한다. Agent는 부팅 UUID instanceId와 단일 writer 상태 저장소를 사용해야 하며 같은 credential을 다른 state root에서 사용해도 동시 실행권을 얻을 수 없어야 한다.

#### Scenario: Concurrent processes share credentials
- **WHEN** 같은 agentId/credential의 서로 다른 instanceId 두 개가 동시에 claim한다
- **THEN** 하나만 활성 owner가 되고 다른 instance는409/reconcile-only 상태로 남으며 lease나 실행권을 재발급받지 못한다.

#### Scenario: Deleted or unauthorized agent
- **WHEN** credential이 비활성화됐거나 등록 프로젝트·capability·resource 범위를 벗어난 요청을 한다
- **THEN**401 또는403으로 거부하고 token 원문 없이 audit를 기록한다.

#### Scenario: Production environment opt-in
- **WHEN** production 대상 실행을 배정받는다
- **THEN** 서버 executionPolicy.allowProduction과 Agent 명시 로컬 허용이 모두 true일 때만 실행한다. 어느 쪽이든 false 또는 누락이면 거부한다.

### Requirement: Durable idempotent claim
Agent SHALL claimRequestId UUID를 요청 전 영속화한다. 서버는 동일 agentId/instanceId/claimRequestId와 같은 payload에 동일 lease identity를 반환하고, 다른 payload 또는 다른 instance 재사용을409로 거부해야 한다. claim 재전송은 TTL을 연장하거나 두 번째 execution을 만들면 안 된다.

#### Scenario: Claim response is lost
- **WHEN** claim은 저장됐지만 응답이 유실되어 같은 요청을 재전송한다
- **THEN** 동일 executionId/leaseId/fence를 반환하며 현재 잔여 유효기간을 알려준다. Agent는 새 claim UUID로 다른 작업을 실행하기 전에 reconcile한다.

#### Scenario: Empty queue retry
- **WHEN** 작업 없는 claim의204 응답을 재전송한다
- **THEN** 같은 requestId는 동일 empty 결정을 유지하고 다음 정상 polling 주기는 새 requestId를 사용한다.

### Requirement: Canonical resource exclusivity and fencing
서버 SHALL canonical resourceKey를 전체 등록 Agent에 걸쳐 독점 배정하고 transaction으로 단조 증가 fence를 발급한다. Agent는 서버 allowlist와 로컬 resource mapping 교집합만 사용해야 한다. 모든 lease 변경·전송 요청은 agentId/instanceId/leaseId/fence에 결합돼야 한다.

#### Scenario: Two agents refer to the same physical device
- **WHEN** 서로 다른 로컬 별칭이 같은 canonical resourceKey에 대응하고 동시에 claim한다
- **THEN** 유효 실행권은 하나만 존재하고 다른 Agent는 해당 자원 작업을 시작하지 않는다.

#### Scenario: Stale holder uploads progress
- **WHEN** 이전 fence 또는 다른 instance의 요청이 도착한다
- **THEN**409로 거부하며 새 holder의 이벤트·결과·증거를 변경하지 않는다.

### Requirement: Conservative monotonic lease timing
lease TTL은30초, heartbeat 주기는5초, 요청 timeout은5초, 안전 여유는5초로 SHALL 시작한다. Agent는 성공 응답의 validForMs를 해당 요청 시작 monotonic 시각에 더해 유효기간을 보수적으로 계산해야 한다. wall clock이나 응답 수신 시각으로 권한을 늘리면 안 된다.

#### Scenario: Delayed heartbeat or clock adjustment
- **WHEN** heartbeat 응답이 늦거나 wall clock이 앞으로 또는 뒤로 바뀐다
- **THEN** 마지막 확인된 monotonic deadline-5초 이내에 협력 취소를 시작하며 네트워크 재시도는 기존 실행권을 연장하지 않는다.

#### Scenario: Lease expires during restart
- **WHEN** 서버 또는 Agent가 재시작하여 기존 lease의 유효 실행권을 확신할 수 없다
- **THEN** 자동으로 실행을 재개하거나 다른 holder에 재배정하지 않고 reconcile·취소·cleanup 확인을 수행한다.

### Requirement: Cleanup uncertainty quarantines resources
서버와 Agent SHALL lease 만료·취소·프로세스 변경 후 cleanupState unknown/failed인 자원과 instance를 quarantine한다. TTL 만료를 child 종료 증거로 취급하면 안 된다. 새 instance는 기존 child/resource 종료가 확인되거나 감사된 운영 해제 전 실행권을 받을 수 없어야 한다.

#### Scenario: Cleanup exceeds lease lifetime
- **WHEN** 취소 후 child 정리가 TTL 안에 끝나지 않는다
- **THEN** 추가 실행을 금지하고 quarantine을 유지한다. 성공 결과나 정리 완료를 합성하지 않는다.

#### Scenario: New instance discovers old ownership
- **WHEN** 새 instance가 이전 instance의 outstanding lease를 reconcile로 발견한다
- **THEN** 조회·정리 절차만 수행하고 기존 실행을 시작하거나 resume하지 않는다. 같은 claimRequestId도 실행권을 이전하지 않는다.

#### Scenario: Graceful owner release
- **WHEN** 기존 instance의 모든 lease cleanup과 terminal outbox ack가 완료되어 completion receipt를 제출한다
- **THEN** 서버는 모든 outstanding lease 상태를 transaction으로 대조한 뒤 owner를 해제한다. 확인 불가 상태는 인증된 관리자 절차와 감사 기록 없이는 해제하지 않는다.

### Requirement: Immutable case snapshots and bounded resources
claim SHALL executionId/jobAttempt와 ordered cases를 반환하고 각 caseId의 normalized Blueprint/hash 및 제한된 resource manifest를 고정한다. Engine runId/attempt는 실제 run.started 이후 매핑하며 서버 실행 ID로 덮어쓰면 안 된다. 리소스는 허용된 논리 이름·byte size·SHA-256으로 전달하고 임의 원격 URL·UNC·상위 경로 탐색을 허용하면 안 된다.

#### Scenario: First single-case execution
- **WHEN** Agent가 첫 실행권을 받는다
- **THEN** cases 길이1인 같은 계약을 사용하고 공개 Engine schema/hash/정확 버전을 확인한 후에만 실행한다. Suite 확장도 case 순서와 identity를 보존한다.

#### Scenario: Preflight cannot execute
- **WHEN** capability·자원·snapshot 검증이 실행 전에 실패한다
- **THEN** executionStatus blocked와 구조화 사유를 보고하고 가짜 Engine run/result를 만들지 않는다.

### Requirement: Authorized operational recovery metadata
사용자 실행 조회 응답은 resourceKey, fence, cleanupState, operatorRecovery 필드를 required nullable로 SHALL 제공한다. qa_manager 이상은 해당 실행의 실제 운영 값을 조회하고 그 아래 역할은 네 필드 모두 null을 받아야 한다. 운영자는 DB 직접 조회 없이 exact resource/fence와 사유·두 종료 확인을 recovery API에 제출할 수 있어야 한다. 복구 권한 검사는 조회 표시와 독립적으로 시행하며 원래 QA 결과와 cleanup 상태를 수정하면 안 된다.

#### Scenario: Manager inspects a quarantined execution
- **WHEN** qa_manager가 만료 또는 격리된 실행을 조회한다
- **THEN** 서버에 고정된 resource/fence와 원래 cleanup 및 별도 운영 복구 기록을 반환한다.

#### Scenario: Viewer cannot obtain recovery authority
- **WHEN** viewer 또는 qa_tester가 같은 실행을 조회하거나 복구를 요청한다
- **THEN** 운영 메타데이터는 null이고 복구 요청은 403으로 거절한다.

