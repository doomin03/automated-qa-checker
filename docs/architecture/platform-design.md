# 플랫폼 API·데이터·권한 설계

상태: P3/P4 설계 초안. 현재 서버/DB/API 구현이나 migration은 없다.

웹은 사용자 공용 QA·XML 전달·진행 앱이며 관리자 게시/승인/권한 업무를 역할에 따라 제공한다. Flutter Desktop은 블록/Flow 또는 XML 개별 테스트 개발·실행 앱이다. 모노레포 health/OpenAPI/SDK 기반은 [이관 설계](../../openspec/changes/refactor-server-web-app-monorepo/design.md)에서 별도 bootstrap으로 추적한다. 이 bootstrap은 P3/P4 완료가 아니며 Desktop 로컬 실행은 서버를 요구하지 않는다.

전체 목표에는 권한을 확인한 공용 XML 버전 전달과 Desktop/Agent 진행 자동 수신이 포함된다. XML handoff의 파일 교환은 첫 단위이며 서버 전달의 대체 완료 조건이 아니다. 자동 수신은 run/attempt/sequence 및 snapshot 일치·재연결/gap·권한 검증을 통과해야 한다.

## 데이터와 책임

| 집합 | 주요 엔티티·제약 |
| --- | --- |
| 인증/조직 | Organization, User(Slack workspace/user ID), Team, Membership, ProjectRole; disable/revoke 감사 |
| Registry | Package, Draft, PublishedVersion, Review; (packageId, version) 유일, 발행 snapshot/hash 불변, draft/published/deprecated |
| QA | TestCase/Flow/Suite engine payload + projectId/owner 등 업무 metadata; upstream pin과 local revision 분리 |
| 배정 | Assignment, Assignee, progress(todo/in_progress/in_review/completed/blocked); run outcome과 독립 |
| 실행 | Run, Attempt, RunEvent, Artifact; (runId, attempt, sequence) 유일, idempotency key와 payload hash |
| 실행기 | Agent, Heartbeat, Device, Lease; Agent auth와 프로젝트 권한 분리, lease fencing token |
| 예약 | Schedule, Occurrence; (scheduleId, scheduledInstantUTC) 유일, timezone/IANA zone·recurrence 보존 |
| 운영 | ReportBaseline, AuditEvent, NotificationDelivery; 알림 실패와 Run 판정 분리 |

DB는 unique constraint/transaction이 가능한 관계형 저장소를 우선 검토한다. Queue/storage 제품과 ORM 버전은 P3/P4의 운영 요구 검증 뒤 결정한다.

## HTTP 규약

참조 설계의 /api/v1, 고유 operationId, 직접 response DTO, 오류 {code,message,requestId,details:[{field,code,message}]}를 채택한다.
목록은 limit(기본 50/최대 100) + opaque cursor로 페이지 처리하고 nextCursor를 반환한다. 입력 unknown field를 거부하고 날짜는 UTC RFC3339로 직렬화한다.
POST run/release/occurrence는 Idempotency-Key와 정규화 payload hash를 보관한다. 같은 key에 다른 payload는 409다. timeout 후 재전송은 동일 객체를 반환한다.
서버 DTO/controller → OpenAPI 3.0.3 export → TS/Dart SDK 생성. generator 버전/checksum은 P3 이전 작은 nullable/required/enum fixture로 확정한다.

| API 초안 | 권한/주요 검증 |
| --- | --- |
| GET /me, /projects | 유효 자체 세션, project membership |
| GET /projects/:id/testcases, /suites | 프로젝트 viewer 이상, pagination |
| GET /registry/packages 및 /:id/versions/:version | 조직·프로젝트 접근권한, immutable version |
| POST /registry/packages/:id/releases | qa_manager, reviewer 승인, schema/hash 검증, audit |
| POST /runs, GET /runs/:id/events, POST /runs/:id/cancel | qa_tester 이상 생성, 프로젝트 scoped 조회/취소; capability/환경 gate |
| GET /runs/:id/artifacts | 프로젝트 권한 + 짧은 수명의 artifact 접근권한 |
| POST /agents/register, /agents/:id/heartbeat | Agent 전용 credential/identity, 별도 scope |
| POST/GET/PATCH /schedules, GET /schedules/:id/occurrences | qa_manager, IANA timezone, target/lease 정책 |

관리자 UI를 위한 별도 backend를 만들지 않는다. 모든 route는 server-side RBAC가 권위다.

## 인증 흐름

시스템 브라우저 → Slack OIDC → backend callback에서 state/nonce/issuer/audience/signature/expiry/workspace 검증 → 자체 session 발행.
Desktop callback은 사전 등록한 callback 방식과 일회용 교환 code로 처리하고 최종 URI/scheme/PKCE 지원 조합은 P3에서 공식 문서 및 플랫폼 실제 검증으로 확정한다. Slack token/client secret을 Desktop이나 로그/DB 평문에 넣지 않는다.
로그인 scope와 Slack 알림 scope는 별도다. 개발 fake identity는 test 구성에서만 허용하며 운영에서 활성화되면 startup을 실패시킨다.

## 예약·Agent·재연결

Schedule은 timezone과 recurrence를 저장한다. DST gap은 missed로 기록하고 자동 이동하지 않는다. overlap은 earlier offset의 occurrence 한 번만 만든다. timezone database 버전과 계산 UTC instant를 기록한다. 정책 변경은 명시적 migration이다.
transactional occurrence 생성과 unique key로 중복 enqueue를 막는다. Queue는 at-least-once이므로 Agent도 project+idempotencyKey를 검사한다.
lease는 TTL/heartbeat 갱신과 fencing token을 가진다. stale Agent는 lease를 잃으면 정지/cleanup하며 서버는 stale token 결과를 정상 수용하지 않는다. lease 없이 같은 기기에 동시 실행하지 않는다.
Agent offline/기기 없음/배정 지연은 occurrence가 missed 또는 blocked 사유를 남기며 성공 Run을 합성하지 않는다. 실행 중 장애는 infra_error다.
Event replay는 (runId,attempt,sequence)로 dedupe하고 gap을 감지한다. artifacts 업로드 완료/hash 검증과 result 확정을 구분한다.

## 주간 비교와 보존

비교키: TC 및 Flow published version, target platform/profile, env, branch, app-build 비교 정책, selector/target snapshot. 정책상 비교할 수 없는 변경은 비교 불가와 사유로 표시한다.
신규 실패는 비교 가능한 이전 passed → 현재 failed다. infra_error/skipped/blocked/missed/unrun을 회귀 실패로 집계하지 않는다.
화면에는 업무 progress, 테스트 outcome, occurrence 상태를 각각 표시한다. 알림 전송 실패는 재시도/감사에 남기고 Run을 변경하지 않는다.
스크린샷/log는 프로젝트 권한을 적용하고 민감 필드 masking, 보존 기간, 삭제 감사, 다운로드 권한을 P3에서 운영 정책으로 확정한다.

