# Design

## Context

versions/suite_versions는 SQLite trigger로 UPDATE/DELETE가 금지된다. Registry publish는 await plan 뒤 최종 DB 상태를 읽으며, Suite와 scheduler는 고정 case/version/plan을 저장한다. 수정 API를 도입하면 plan을 시작한 내용과 publish 시점 내용 사이 race를 새로 방어해야 한다.

## Goals / Non-Goals

초안 수정·반려·재검수, 게시물 신규 이용 중지, 과거 검증자료 보존을 제공한다. 게시 원본 삭제/덮어쓰기·Engine 결과 수정·이미 실행 중인 외부 앱의 자동 강제 중단은 제공하지 않는다. 업무 배정 반려는 별도 assignment 상태다.

## Decisions

### D1. Draft revision and moderation

Registry/Suite별 별도 moderation row에 revision, state `submitted | rejected`, nullable reason, actor/time을 저장한다. 기존 draft response state enum draft/reviewed/published는 유지하며 추가 정보는 `GET .../drafts/:id/moderation`에서 조회한다. 구 draft는 revision0/submitted로 해석해 migration한다.

신규 `PATCH .../drafts/:id`는 내용+revision, `POST .../drafts/:id/reject`는 reason+revision, `POST .../drafts/:id/resubmit`은 revision을 받는다. 경로는 registry와 suites 각각에 둔다. PATCH는 작성자이면서 현재 qa_editor 이상 또는 현재 qa_manager 이상만 허용하며 published 초안은 거부한다. reject는 작성자와 다른 qa_manager, resubmit은 현재 작성자/editor 또는 manager이며 거부 사유를 이력에 보존한다.

PATCH 성공은 draft.state=draft/reviewer=null로 승인 무효화, moderation=submitted, revision증가와 audit을 원자 수행한다. reject는 draft.state=draft/reviewer=null, moderation=rejected로 만들고 approve는 rejected인 동안 거부한다. resubmit 후 독립 검수를 다시 받아야 한다. 내용이 바뀌지 않는 재제출도 revision을 증가시킨다. 사유는 bounded1..2000자로 제한하고 서버 로그/외부알림에 원문을 자동 복사하지 않는다.

review/publish 기존 signature는 유지한다. publish는 await 전 draft revision/hash/내용을 capture하고 await 후 transaction에서 동일한지 검사한다. reviewer 현재권한·작성자 분리와 dependencies/lifecycle을 다시 확인한다. 같은 publish idempotency key가 이미 만들어진 불변 응답을 돌려줄 때도 현재 조회/관리 권한을 먼저 확인하되 기존 version을 다시 만들지 않는다.

### D2. Immutable publication lifecycle

`publication_lifecycle(project_id,kind,version_id,state,revision,reason,actor_id,updated_at)`와 append-only audit을 추가한다. kind는 registry/suite, state는 active/withdrawn이며 기존 row는 active/revision0다. `GET .../versions/:id/lifecycle`, `POST .../versions/:id/withdraw`를 추가한다. manager 권한·reason·revision/idempotency 필수, 대상프로젝트와 kind 일치를 검사한다. withdrawn은 되돌리지 않고 다시 제공하려면 새 version을 publish한다.

GET version/Suite/기존 pins/원본 receipt/run/evidence는 기존 권한 아래 읽기 가능하다. 반환 XML/Suite JSON/hash는 절대로 변경하지 않는다. 새 pin·새 Suite case 사용·새 assignment·새 실행/예약 생성·수신 action은 withdrawn이면 거부한다. 수신 차단은 새 정책을 소비하는 UI의 명시 요청 경로이며 raw historical GET 자체는 삭제하지 않는다. 같은 bytes를 별도 새 version으로 복사하는 행위는 기존 명시 작성·검수·게시 절차다.

### D3. Scheduling and claim eligibility

publish origin을 알 수 있는 prepared execution과 job에 별도 서버 소유 origin-reference 목록(kind/id/hash)을 보존한다. Engine schema/event/result는 변경하지 않는다. registry 단일/Suite 루트 및 case 각각이 대상이다. 신규 origin pin은 정확한 버전을 가리킨다.

신규 요청의 prepare await 후/queue transaction에서 lifecycle 재검사, schedule occurrence의 enqueue 직전 및 queued job claim 직전에 재검사한다. withdrawn이면 신규 Run을 합성하지 않고 execution blocked 및 이유 `publication_withdrawn`, occurrence의 기존 의미상 missed/차단 이유를 기록한다. 이미 claimed인 lease는 같은 실행/cleanup/report 계약을 유지하며 운영자가 원하면 기존 explicit cancel을 별도로 요청한다.

기존 saved schedule.config의 version/Suite 정보에서 origin을 복원한다. 기존 queued job은 저장 suite/case 원본을 통해 확증 가능한 참조만 backfill한다. 참조 없는 trusted 직접 blueprint job은 `unversioned`로 명시해 기존 허용 정책을 유지한다. 게시 출처가 있다고 주장하지만 확증할 수 없는 legacy job은 blocked로 분리하며 이력을 삭제하지 않는다.

### D4. API and consumers

기존 version/draft enum과 조회 schema를 깨지 않는 별도 lifecycle/moderation DTO를 생성한다. 목록 UI는 선택된 페이지에 한해 lifecycle 정보를 bounded batch 조회하거나 기존 상태 API를 제한된 동시성으로 호출한다. 새 batch endpoint를 만들면 최대100개/project scope를 명시한다. 웹은 archived/withdrawn을 테스트 failed와 구분하고 이전 pins를 무음 삭제하지 않는다.

## Validation

실제 DB/HTTP로 edit→review→edit approval invalidation, rejected approve거부/resubmit, plan 지연중 edit/publish race, 자기검수/권한철회/다른project/revision/idempotency를 검사한다. withdrawal 전후 bytes/SHA/기존 pin/Run불변, queued/claim race·future occurrence·이미 claimed 보고완료를 별도 확인한다. 기존 Engine/Agent protocol 및 SDK signature 보존을 compatibility gate로 인수한다.
