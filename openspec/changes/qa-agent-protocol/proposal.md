# Proposal

## Why

Checker의 로컬 Registry·실행 공유는 구현됐지만 원격 Agent에 작업을 배정하고 연결 상실·프로세스 재시작·중복 요청에서 같은 기기의 실행권을 보존하는 계약은 없다. 서버 정본 HTTP 계약을 먼저 확정해 Engine이 Checker 소스 없이 독립 패키지로 소비하도록 한다.

## What Changes

- 등록 Agent credential, 부팅 instanceId, durable claimRequestId, executionId/jobAttempt와 Engine runId/attempt를 분리한다.
- claim/heartbeat/events/complete/reconcile 및 case-scoped 증거 업로드의 versioned HTTP 초안을 정의한다.
- canonical resourceKey의 전역 독점, monotonic fence, TTL, 협력 취소, cleanup 불명 quarantine을 저장한다.
- immutable Engine Blueprint/event/result envelope와 별도 deliverySequence로 단일case 및 published Suite ordered case snapshots를 전달한다.
- 재시작 outbox, 응답 유실, 동일 credential의 두 프로세스, stale fence와 부분 업로드를 실제 실패 인수로 고정한다.
- published snapshot을 고정한 주간 IANA timezone 예약, DST gap/overlap, occurrence unique, 재시작 catch-up/missed와 취소를 구현한다.
- 감사 가능한 qa_manager 운영 복구로 실제 정리 확인 후 fence를 증가시키며 원래 QA 결과와 증거 상태를 보존한다.
- 임의 cron 문법은 지원하지 않는다. 외부 OIDC 실로그인, Slack 알림, baseline 승인·비교는 qa-platform-services의 별도 담당 작업이다.

## Capabilities

### New Capabilities

- qa-agent-leases: Agent instance 인증, 실행권·resource 독점, TTL/fence와 cleanup 격리.
- qa-agent-delivery: Engine 원본 event/result 전송, outbox 재연결, case별 증거 정합성과 수신 상태.
- qa-weekly-scheduler: published execution snapshot, 주간 시간대 recurrence, DST와 occurrence unique/missed/취소.

### Modified Capabilities

없음. 현재 archive된 main spec은 없다. 진행 중 qa-platform-services의 Agent 목표를 구체화한다.

## Impact

- integrationId: automated-qa-agent-protocol
- contractVersion: 0.1.0-draft.1 (Checker HTTP; Engine 실행 contract 0.3.0-draft.1과 별개)
- dependsOn: qa-platform-services의 영속 identity/Registry/run/artifact, refactor-server-web-app-monorepo의 offline OpenAPI/생성 SDK, 검증된 Engine alpha.5
- counterpartRepoChange: automated-qa-engine의 qa-agent-protocol (관리 에이전트가 정확 경로와 소비 hash를 교차 확인)
- phase: P4 Agent 배정·복구·Suite 소비·주간 예약
- 소유: Checker apps/server의 Agent DTO/Repository/API와 packages/contract/agent-protocol의 versioned 초안. Engine은 독립 Agent CLI·local mapping·single-writer lock·monotonic clock·outbox/child 정리를 소유한다.
- 현재 제품 OpenAPI에는 구현된 route만 유지한다. 승인된 초안을 DTO로 구현한 뒤 offline export를 정본으로 승격하며, 수작업 초안과 제품 계약을 동시에 편집하는 상태를 남기지 않는다.
