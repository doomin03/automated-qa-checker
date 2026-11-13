# Registry review lifecycle

## ADDED Requirements

### Requirement: Draft changes invalidate review atomically

서버 SHALL revision 조건의 수정·반려·재제출을 제공하고 내용 변경 시 기존 독립 승인을 무효화해야 한다. published 초안은 수정하지 않아야 한다.

#### Scenario: Edited reviewed draft cannot publish using stale plan

- **WHEN** 검수된 초안의 publish plan 대기 중 내용이나 revision이 변경된다
- **THEN** publish는409로 거부되며 오래된 plan으로 새 내용을 게시하지 않는다

#### Scenario: Rejected draft requires explicit resubmission

- **WHEN** manager가 다른 작성자의 초안을 사유와 함께 반려한다
- **THEN** 승인 정보는 해제되고 명시 수정/재제출 전에는 review가 거부된다

### Requirement: Withdrawal preserves immutable historical data

서버 SHALL 게시 폐기를 원문과 분리된 lifecycle로 저장하고 XML/Suite/hash/pin/기존 결과를 수정하거나 삭제하지 않아야 한다.

#### Scenario: Historical receipt remains readable

- **WHEN** 기존 pin이 가리키는 version을 manager가 withdraw한다
- **THEN** 허용 사용자는 원문과 폐기 이유를 조회할 수 있고 기존 SHA/Run/증거는 유지되지만 새 pin/배정/실행은 거부된다

### Requirement: Lifecycle is rechecked at scheduling and claim boundaries

서버 SHALL version/Suite/case 출처를 고정하고 신규 queue와 schedule occurrence 및 claim 직전에 lifecycle을 재검사해야 한다. 이미 claimed인 실행을 폐기만으로 terminal 처리해서는 안 된다.

#### Scenario: Queued version is withdrawn before claim

- **WHEN** 고정 게시물을 사용하는 queued job이 claim 전에 폐기된다
- **THEN** job은 publication_withdrawn 사유로 차단되고 새 Engine Run/lease를 만들지 않는다

#### Scenario: Withdrawal occurs during an active execution

- **WHEN** 이미 claimed인 실행의 게시물에 withdrawal이 기록된다
- **THEN** 기존 lease의 취소/cleanup/보고 계약과 원본 판정을 유지하고 중지가 필요하면 별도 명시 취소를 요구한다

### Requirement: New moderation contracts preserve existing public shapes

서버 SHALL 별도 moderation/lifecycle 계약을 사용하고 구 version/draft 상태와 Agent/Engine schema를 무음 변경하지 않아야 한다.

#### Scenario: Old consumer reads a published version

- **WHEN** 새 관리 기능 적용 후 기존 SDK가 이전 version을 읽는다
- **THEN** 기존 응답 필드/원문/hash 의미가 유지되고 새 관리 상태가 Engine outcome으로 섞이지 않는다
