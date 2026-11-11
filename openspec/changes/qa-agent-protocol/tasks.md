# Tasks

## 1. 계약 고정과 소유 경계

- [x] 1.1 HTTP OpenAPI 초안·성공/거절 예시를 lint/schema 검증하고 관리 수용 hash를 Engine counterpart에 전달해 같은 bytes 소비를 확인한다.
- [x] 1.2 Agent DTO/controller를 승인 draft 의미에 맞게 구현하고 offline export·생성 SDK·read-only drift로 제품 계약 전환을 검증한다. Engine DSL은 envelope로 유지한다.

## 2. 영속 실행권과 복구

- [x] 2.1 migration2의 Agent/instance/job/resource/lease/claim journal을 구현하고 기존 migration1 보존·재시작·unique/transaction 테스트로 검증한다. 동기 SQLite 제한을 문서화한다.
- [x] 2.2 등록 Agent credential·server executionPolicy∩local capability/resource scope를 구현하고401/403·두 credential·같은 credential 두 instance·다른 state root 동시 claim 테스트를 통과한다.
- [x] 2.3 durable claimRequestId·remaining TTL 재계산·resource monotonic fence를 구현하고 응답유실 재시도·다른 body409·오래된30000 재생 금지·closed lease만 resource 회수 테스트를 통과한다.
- [x] 2.4 heartbeat/cancel/reconcile byte pagination과 TTL30/5/5/safety5 정책을 구현하고 서버 재시작·wall clock변경·지연응답·서버 outstanding 누락 방지·만료 quarantine 테스트를 통과한다.
- [x] 2.5 instance release 누적 receipt ack와 인증된 로컬 관리 provisioning/recovery CLI를 구현하고100개 초과 이력·미정리 child·미확인 증거 해제 거부·감사·token 무출력 인수를 문서화한다.

## 3. 실행 증거 전달

- [x] 3.1 deliverySequence와 case Engine identity/sequence/state 검증 및 원자 outbox ack를 구현하고 중복·상이payload·gap·invalid tail rollback·stale fence 테스트를 통과한다.
- [x] 3.2 complete/reporting/receipt와 case result/artifact manifest 정합성을 구현하고 preflight blocked 빈 result·정상 terminal·missing bytes·cleanup unknown·동일complete 재전송을 검증한다.
- [x] 3.3 bounded resource download와 case-scoped artifact upload를 구현하고10MiB/64MiB/16MiB 한도·hash·font/subdir·traversal/UNC/symlink·실패원자복구를 검증한다.
- [x] 3.4 historical-evidence를 별도 영속 보관하고 expired/quarantined/closed 증거 재전송이 정상 cursor/TTL/실행권/resource lock을 변경하지 않는 회귀 테스트와 문서를 제공한다.

## 4. 독립 Engine 통합과 후속 종료 기준

- [x] 4.1 동일 고정 HTTP artifact를 소비하는 독립 Engine Agent와 실제 서버 단일 case 실행·claim 응답유실·event ack유실·cancel·cleanup·partialartifact를 인수하고 release version/hash를 기록한다.
- [x] 4.2 published Suite ordered version refs·stopOnFailure를 canonical case snapshots로 정규화하고 Desktop Suite 수신/version pin 및 여러case 실행 identity/순서를 실제 검증한다. Desktop 실제 Provider/Nest 2-case 수신·개별 실행 경로와 독립 Agent 순차 실행 증거를 결합하며 Desktop 일괄 실행 구현을 뜻하지 않는다.
- [x] 4.3 scheduler timezone/recurrence/DST/occurrence unique·queue·missing 감지의 후속 명세를 확정하고 같은 occurrence1회 실행·미실행 사유·재시작 인수까지 수행한다.
- [x] 4.4 비교 가능한 previous baseline/regression·triage/assignment·Slack local fixture 알림은 qa-platform-services 및 owner의 auth/workflow 범위와 연계해 결과 독립성·권한·실패재시도를 인수한다. 외부 실계정은 별도 pending으로 남긴다.
- [x] 4.5 전체 실패 matrix 및 OpenSpec strict·server/SDK/Engine contract tests를 교차 검토하고 실제 완료와 미검증 실기기·외부연동을 문서화한다.

## Workflow follow-up

- 관리 검토와 실제 인수 전 archive하지 않는다. Stage3/4 전체 종료를 단일 Agent case 또는 문서 생성만으로 표시하지 않는다.
- 원격 push/merge와 commit은 사용자 별도 지시 없이 수행하지 않는다.

## 인수 근거

[acceptance.md](acceptance.md)의 contract hash·DB/artifact·Engine matrix와 실제/fixture 범위 구분을 따른다. Desktop Suite는 artifacts/flutter-shared-ui/verification.json, 업무 비교·알림은 workflow-web-verification.json에 근거를 보존한다. 최종 전체 fresh 검증과 미검증 외부 환경을 별도로 기록한다.
