# Design

2026-10-31 Desktop Suite 인수: 생성 HTTP SDK로 ordered members와 고정 Suite version/hash를 수신·pin하고 사용자가 case를 선택하면 기존 개별 XML 수신/검증/명시 실행 경로를 사용한다. 수신만으로 실행하지 않는다. 전체 Suite 순차 실행/stopOnFailure는 독립 Agent가 소유하며 Desktop 일괄실행을 구현한 것으로 보고하지 않는다. 연결 교체 generation을 검사해 이전 응답이 다른 origin/project의 pin/cache가 되지 않도록 한다.

## Context

동기는 [proposal.md](proposal.md)를 따른다. 착수 시 Nest PlatformService는 Registry/run, SQLite migration1, 원자 batch replay와 bytes storage를 제공했고 Agent API는 없었다. 현재 범위는 Agent 영속 배정·복구, published Suite의 ordered snapshots 소비 및 시간대 주간 예약이다. Engine은 독립 CLI/public schema로만 소비한다. 기존 alpha.5 앱 pin은 유지하며 Agent 교차 인수에는 별도 설치한 관리 검증 alpha.6 후보를 사용한다.

설계 정본 초안은 `packages/contract/agent-protocol/v0.1.0-draft.1/openapi.json`이다. 실제 제품 `packages/contract/openapi.json`에는 미구현 route를 넣지 않는다. 초안 승인 후 명시 Agent DTO/controller로 구현하고 offline export의 해당 endpoint/components가 승인된 draft와 의미적으로 같은지 검증해 제품 정본으로 전환한다. 이 문서의 protocolVersion은 HTTP 버전이며 Engine schemaVersion과 독립이다.

## Goals / Non-Goals

**Goals:** 등록 Agent의 단일/ordered Suite 실행 배정, identity/lease/delivery/storage, 감사 가능한 운영 복구 및 주간 시간대 예약을 구현한다. 실행은 Engine이 소유한다. 단일 SQLite 서버에서 중복·응답유실·취소·재시작·DST·missed occurrence를 실제 검증한다.

**Non-Goals:** 임의 cron 문법, 원격 URL의 Engine 코드/파일 다운로드, Checker 내부 interpreter, raw Suite XML parser와 실제 Android/iOS 기기 인수는 포함하지 않는다. 비교·업무 상태·Slack local fixture와 OIDC는 qa-platform-services의 owner 담당 범위이며 외부 실계정 인수는 별도다. 초기 단일case checkpoint는 전체 Suite/예약 인수를 대체하지 않는다.

## Decisions

### Identity and immutable assignment

사용자 bearer와 Agent bearer를 다른 인증 경계로 둔다. 등록 Agent는 token hash, project/capability/resource allowlist, pinned engine version/contract/public bundle hash를 가진다. engineContractSha256은 공개 `contracts/releases/qa-contract-<engineVersion>.json`의 원본 bytes SHA-256이며 runtime manifest나 npm tarball hash가 아니다. 설치 runtime 파일 무결성은 Agent의 trusted local manifest 검증이 별도로 책임진다. Agent 요청의 agentId는 credential identity와 일치해야 한다. capabilities는 platforms(web/android/ios)와 고정 Engine의 정규 actions 이름 집합이다.

Lease.executionPolicy는 resourceKey/platform/allowedOrigins/nativeApps(appId,activities)/secretRefs를 필수로 갖는다. 모든 allowlist의 기본값은 빈 집합이며 권한을 허용하지 않는다. Agent는 서버 policy∩서버 등록 scope∩로컬 origin/app/secret/device mapping∩공개 Engine capability를 적용하고 같은 resourceKey 물리기기만 사용한다. web URL은 정확한 HTTP(S) origin으로 검사한다. Appium endpoint와 secret 원문은 trusted local config만 결정하며 서버 payload의 임의 URL로 바꾸지 않는다.

executionPolicy.allowProduction은 필수 boolean/default false다. production 환경 실행은 이 서버 값과 Agent의 명시 로컬 --allow-production 두 opt-in이 모두 true일 때만 허용한다. 누락된 응답은 false 또는 계약 오류로 거부하고 권한을 추정하지 않는다.

부팅마다 새 instanceId UUID를 생성한다. 서버 active instance owner는 자동 TTL 교체하지 않는다. 같은 agentId/credential의 다른 instance가 같은 claimRequestId를 보내도409이며 observer/reconcile만 가능하다. Engine은 별도로 state root의 single-writer OS lock과 기록한 child owner identity를 검증한다. 서로 다른 state root 두 프로세스는 서버 instance owner로 차단한다.

claimRequestId UUID를 요청 전에 journal에 기록한다. DB unique(agentId,claimRequestId)와 canonical request hash를 저장한다. 같은 holder/payload 재전송은 같은 assignment identity를 반환하고 validForMs는 현재 잔여시간으로 계산한다. 새 UUID를 사용한 claim은 기존 outstanding lease가 있으면 거부한다.204도 저장된 empty 결정으로 재현한다.

executionId/jobAttempt는 배정 identity다. `cases[{caseId,blueprintJson,blueprintSnapshotHash,resources}]` 순서를 고정한다. Engine runId/attempt는 각 case의 실제 run.started를 받아 고정하며 jobAttempt를 Engine attempt로 바꾸지 않는다. Engine CLI가 생산하는 runId를 서버가 미리 지정하지 않는다.

suitePolicy는 stopOnFailure와 published Suite version/hash, 각 case의 publishedVersion pin을 보존한다. 첫 단위1 case 뒤 실제 published Suite의 ordered version refs를 공개 Engine plan의 canonical snapshots로 정규화하는 단위가 남는다. Suite 수신/version pin과 Stage3/4 전체 종료 조건을 단일 case 성공으로 완료 처리하지 않는다.

### HTTP lifecycle

| Endpoint | 상태·검증 |
| --- | --- |
| POST /agent/claims | 등록 범위+single instance, atomic resource lease,200 또는 durable204 |
| POST /agent/leases/{leaseId}/heartbeat | holder/fence active·reporting만 TTL 갱신, cancelRequested 반환 |
| POST /agent/leases/{leaseId}/events | Engine 원본 JSON문자열, execution deliverySequence와 case Engine sequence 별도 원자검증 |
| PUT /agent/leases/{leaseId}/complete | immutable caseResults/executionStatus/cleanupState/manifest 수신, missing bytes와 completion 구분 |
| POST /agent/reconcile | known leases와 서버 outstanding 전체 합집합, cursor 페이지를 모두 확인한 뒤 claim 판단 |
| GET /agent/leases/{leaseId}/resources/{resourceId} | 등록 manifest의 bytes만, 경로·URL 입력 없음 |
| PUT /agent/leases/{leaseId}/artifacts | opaque ID/case/fence/hash/size/MIME 검증 후 원자 bytes 저장 |
| POST /agent/leases/{leaseId}/historical-evidence | 만료·격리·종료 holder의 역사증거 별도 보관, 정상 cursor/권한/TTL/lock 변경 없음 |
| POST /agent/instances/release | 모든 terminal receipt와cleanup confirmed를 대조해 owner해제 |

공통 prefix는 `/api/v1`, 오류는 기존 ApiErrorResponse다. unknown field를 거부한다. Agent 요청 timeout5초이며 백오프가 heartbeat·stdout drain·cancel watchdog을 막으면 안 된다. credential/Engine payload를 요청 로그에 남기지 않는다.

### Timing and resource fencing

canonical resourceKey는 프로젝트/Agent를 넘어 같은 물리 기기·browser slot에 대해 하나다. SQLite transaction으로 resource row의 fence를 증가시키고 outstanding lease가 없는 경우에만 claim한다. expiresAt이 지났다는 이유만으로 lock을 해제하지 않는다.

TTL30초, heartbeat5초, request timeout5초, safety5초. Agent는 성공 응답의 validForMs를 **해당 요청 시작 monotonic 시각**에 더한 deadline을 사용한다. 응답이 이미 deadline-safety보다 늦으면 실행을 시작/유지하지 않는다. 실패 응답·network timeout·wall clock 변경은 deadline을 늘리지 않는다. 서버 재시작 시 active/reporting lease는 보수적으로 expired/quarantined로 재조정하고 heartbeat로 부활시키지 않는다.

이 시간 계산은 claim·heartbeat·reconcile 모두 동일하다. 저장된 claim 응답의 오래된30000을 재생하지 않고 각 응답 시 잔여 TTL을 재계산한다. resource는 cleanup 확인과 완료 조건을 만족해 closed로 바뀐 lease에서만 회수한다. expiresAt 경과 자체로 재배정하지 않는다.

만료·cancelRequested·owner 충돌 시 Engine 협력 취소를 먼저 요청한다. cleanup이 TTL 내 완료된다고 가정하지 않는다. child owner를 검증하지 못하거나 종료/기기 해제를 확인하지 못하면 cleanupState unknown/failed와 quarantine을 유지한다. 오래된 PID 번호만으로 다른 프로세스를 kill하지 않는다.

### Delivery, completion and late evidence

events는 `{deliverySequence,caseId,engineEventJson}`이다. JSON envelope는 byte/depth 제한과 고정 공개 Engine schema로 검증한다. canonical JSON hash로 멱등 비교하며 Engine timestamp/runId/attempt/sequence/content는 재작성하지 않는다. deliverySequence는 execution 전체1부터 연속이고 case별Engine sequence는 각자1부터 연속이다. batch100개·2MiB 제한이며 한 항목 실패 시 전체 rollback한다.

complete는 case별 실제 terminal result와 별도 executionStatus를 수신한다. preflight blocked는 caseResults=[]이며 reason 필수다. 실제 run 시작된 case는 terminal event/result/visited·unvisited/snapshot을 검증한다. artifactManifest는 case result의 artifact집합과 정확히 일치해야 한다. run 결과의 외부판정과 전달·cleanup·bytes 검증은 각각 저장한다.

complete metadata 수신 후 missing bytes가 있으면 lease는 reporting 상태로 남고 holder는 heartbeat·업로드를 계속한다. cleanup confirmed와 모든 bytes verified가 된 뒤 complete를 같은 body로 재호출하면 completionReceipt를 반환하고 deliveryClosed=true로 resource를 해제한다. 최초 metadata 응답의 nullable receipt를 완료 ack로 간주하지 않는다. 이미 closed인 동일 complete 재전송은 immutable receipt만 재현하고 실행권을 복원하지 않는다. 다른 body는409다. 모든 lease의 receipt와 acceptedThrough를 서버에 대조한 뒤 instance release가 가능하다.

InstanceRelease.receipts는 전체 이력이 아니라 미확인 completion receipt의 최대100개 batch다. 서버가 ack를 누적 저장하고 모든 소유 lease의 terminal/cleanup/evidence를 독립적으로 대조한다. 잔여 receipt가 있으면 released=false/remainingReceipts를 반환하고 owner를 유지한다. 따라서100회를 넘게 실행한 instance도 bounded batch로 정상 해제할 수 있다.

complete 응답 유실 후 재시작을 위해 reconcile decision은 completionReceipt/deliveryClosed/evidenceStatus와 lease.acceptedThrough를 반환한다. release는 reportingInstanceId와 ownerInstanceId를 분리한다. ownerStopped=true는 정상 동일instance에서는 모든 Engine child 종료·추가claim중단을 의미하며 ACK대기 supervisor 자체 종료를 요구하지 않는다. 다른 reporter는 이전 owner OS process 부재까지 확인해야 한다. 서버는 같은Agentcredential, oldowner의모든leaseclosed/cleanupconfirmed/evidenceverified/receiptack를대조하고확인불가면거부한다. 해제된 ownerInstanceId는 영구 retired tombstone으로 남아 늦은 oldprocess claim으로 소유권이 복원되지 않는다.

expired/quarantined lease는 정상 events/complete/업로드를 거부한다. historical-evidence는 해당 Agent의 원래 owner/lease/fence/case mapping과 공개 schema를 검사해 별도 history table/storage에 evidenceRequestId 멱등 receipt로 보관한다. 새 instance도 reportingInstanceId와 원래 ownerInstanceId를 명시해 보존 증거를 보고할 수 있다. 이 receipt는 실행권·cleanup 확정·기기 해제·정상 acceptedThrough를 변경하지 않는다. history는 원격 실행 성공 검증이 아니다.

### Bounded resource materialization

claim/reconcile response는각8MiB, 단일 serialized Lease는7MiB로 제한한다. reconcile은 개수100과 총 byte budget 모두로 page를 나누고 모든 cursor를 읽은 뒤 claim 여부를 판단한다. 하나의 Lease가 반드시 한 page에 들어가도록 배정 전 size를 검증한다. Blueprint/event/result JSON은각1MiB·depth40, resource/artifact file은10MiB, execution 전체64MiB, HTTP JSON body16MiB로 제한한다.

resource manifest는 서버 opaque ID/안전한 ASCII 상대 경로/size/SHA-256/MIME를 갖는다. 하위 경로와 png/json/woff/woff2/ttf/otf(font/* MIME)를 허용한다. Agent는 lease manifest의 ID만 정해진 same-origin endpoint로 받아 제한된 임시 document root에 atomic write한다. 절대/UNC/역슬래시/상위 경로·symlink escape·대소문자 충돌·임의 원격 URL은 거부하고 받기 전후 byte/hash를 확인한다. resource 다운로드 실패는 preflight blocked이며 가짜 Engine result를 만들지 않는다. result artifact 논리 이름은 별도 Engine schema의 png/json 제한을 따른다.

### Persistence and audited operator recovery

migration2에 agents, agent_instances, execution_jobs/cases, resources, leases, claim_requests, deliveries, completions, historical_evidence를 추가한다. resource row의 current lease와 fence, agent active instance, claim identity, delivery PK/sequence는 transaction/unique constraint로 보호한다. 기존 Desktop runs/events/migration1 의미는 유지하고 Agent case intake를 서비스 경계에서 연결한다.

trusted provisioning은 수동 SQL 편집 지시로 제공하지 않는다. 명시 local/test에서 인증된 qa_manager 이상의 로컬 관리 CLI를 제공해 Agent 등록/해제와 quarantine recovery를 검증·감사한다. 토큰은 ignored 권한제한 파일에만 생성하고 출력하지 않는다. 해제는 resource/old owner/child 종료 확인 자료와 운영자 사유를 요구하며 확인 불가 시 거부한다. 운영자가 확인한 회복과 자동검증을 구분해 기록한다. 해당 관리 UI는 필수 범위가 아니다.

운영 복구 API는 `POST /projects/{projectId}/executions/{executionId}/recovery`이며 qa_manager, requestId UUID, 원래 resourceKey/fence, 필수 reason, ownerProcessesStopped=true, externalSessionsStopped=true를 요구한다. 대상은 expired/quarantined lease이고 현재 canonical resource의 leaseId/fence가 정확히 같아야 한다. requestId와 같은 body는 동일 recovery를 반환하고 다른 body는409다. transaction은 operator_recoveries에 actor/확인시각/priorFence/newFence를 감사 저장하고 lease를 recovered로 바꾸며 old instance를 영구 retired, Agent owner를 해제하고 resource fence 증가와 소유 해제를 원자적으로 수행한다. 다른 job이 자원을 소유하거나 active lease면 거부한다. 자동 TTL 회수는 여전히 금지하며 이 절차는 명시 운영 확인을 거친 예외다.

사용자 execution 조회의 resourceKey/fence/cleanupState/operatorRecovery는 required nullable 필드다. qa_manager 이상은 실제 운영 값을 조회하고 낮은 역할은 null을 받는다. 복구 API는 별도로 권한을 검사한다. 로컬 recover CLI도 live HTTP를 사용해 서버가 보유한 monotonic 만료 상태를 적용하며 별도 프로세스의 빈 deadline map으로 DB를 조작하지 않는다.

reconcile decision은 모든 상태에서 nullable required operatorRecovery를 반환한다. recovered일 때 {id,confirmedAt,priorFence,newFence}, directive=observe, deliveryClosed=false다. priorFence===lease.fence, newFence>priorFence이며 기존 cleanup/evidence/outcome/result/receipt를 변경하지 않는다. Engine은 old OS process 부재와 전체 reconcile, recovery identity/fence를 확인한 후 로컬 이력을 닫을 뿐 재실행하지 않는다. 새 실행은 별도 명시 job/instance/lease를 요구한다. recovered historical 보고는 원래 owner/fence로 계속 수용하며 실행권/자원해제를 변경하지 않는다. 복구 테스트는 로컬 fixture만 수행한다.

## Risks / Trade-offs

### Weekly scheduler and occurrence identity

예약은 실행 DSL이 아닌 Checker 업무 메타데이터다. `POST /projects/{projectId}/schedules`는 정확 published Blueprint version 또는 published Suite version, resourceKey와 executionPolicy, IANA timezone, weekdays(ISO 1=월요일..7=일요일), localTime(HH:mm), latenessSeconds(1..86400), enabled를 받는다. Suite/Blueprint 참조는 서로 배타적이며 생성 시 정규화한 ordered case plan과 suitePolicy를 저장한다. 이후 Registry 내용 또는 pin 변경으로 이미 생성된 예약 snapshot을 바꾸지 않는다. 변경은 enabled만 허용하고 실행 구성 변경은 새 예약으로 만든다. `GET schedules`, `GET schedules/{id}/occurrences`, `PUT schedules/{id}/enabled`를 제공하며 모든 읽기는 viewer, 생성/변경/실행취소는 qa_tester 이상이다.

스케줄러는 단일 서버의 1초 tick과 명시 테스트 tick을 사용한다. lastScannedAt UTC를 영속 저장하고 생성 시각 이후부터 현재까지의 local calendar day를 검사한다. 서버가 오랫동안 중지된 경우 최근 7일 이전 구간은 집계 missed audit로 남기고 최근 7일 occurrence는 각각 저장한다. 일상 재시작 catch-up은 latenessSeconds 이내이면 queued, deadline을 지났으면 missed(reason=scheduler_late)다. queued occurrence가 deadline 전에 적합 Agent/device를 얻지 못하면 missed(reason=no_eligible_agent_or_resource)로 기록하며 Engine assertion failure와 구분한다.

IANA timezone의 localTime은 그날 UTC offset 후보를 검사해 정확히 역변환한다. DST gap에 해당하는 존재하지 않는 localTime은 실행하지 않고 missed(reason=dst_nonexistent_time), overlap은 이른 UTC instant 하나만 선택한다. scheduleId+localDate와 scheduleId+정규화 UTC occurrenceAt에 각각 unique constraint를 둔다. 같은 tick 두 번, 시계 역행, 서버 재시작은 중복 job을 만들지 않는다. scan cursor 갱신, occurrence insert, job enqueue는 하나의 SQLite transaction이다. 정규화 plan은 미리 고정되어 tick 안에서 CLI/네트워크를 호출하지 않는다.

prepared snapshot과 job은 Engine version/contract version/contract bytes SHA를 별도로 고정한다. queue와 claim 모두 현재 pin 및 등록 Agent와 대조하며 불일치는 `engine_pin_incompatible` 미실행으로 남긴다. 과거 target을 자동 재컴파일하지 않는다. 예약별 SAVEPOINT로 오류를 격리해 한 예약의 설정 오류가 다른 예약 또는 서버 timer를 종료하지 않게 한다. deadline 경계는 `<= now`로 일치시키고 enabled 동일값 재전송은 scan cursor를 변경하지 않는다.

disable은 future occurrence 생성을 중단하고 아직 queued인 작업을 cancelled로 바꾼다. 이미 claim된 lease에는 cancelRequested=true를 보내며 cleanup 확인 전 resource를 풀지 않는다. 예약을 다시 enable하면 비활성 기간을 소급 실행하지 않고 새로운 scan cursor에서 시작한다. 개별 execution cancel도 동일한 의미다. execution 상태/미실행 사유는 외부 Engine outcome 및 증거 검증 상태와 별도로 반환한다.

- SQLite 동기 API와 단일 서버 제한 → bounded payload·batch, 단일 프로세스 인수 후 Repository 경계에서 운영 DB를 교체한다.
- 만료 후 자원 이용 불가가 길어질 수 있음 → 안전한 quarantine을 유지하고 인증된 운영 회복 절차를 제공한다. 가용성을 위해 동시 실행을 허용하지 않는다.
- 실제 원격 child 종료를 서버가 직접 증명할 수 없음 → Agent owner 확인·cleanup 보고와 감사된 운영 확인을 구분하고 역사증거만으로 lock을 풀지 않는다.
- 초안과 코드 정본 이중화 → DTO 구현 시 승인 초안 semantic 비교 후 offline export만 편집 가능한 정본으로 승격한다.

## Migration Plan

HTTP 초안/hash를 관리 검토하고 Engine counterpart가 같은 계약을 pin한다. Checker migration2/DTO/API와 Engine outbox/worker를 각 저장소에서 구현한 뒤 실제 HTTP 단일 case→응답유실→두 Agent/두 instance→restart/TTL/quarantine/부분artifact 순서로 인수한다. 최종 서버 OpenAPI와 Engine release hash를 다시 고정한다. P4 미검증 상태는 task를 열어두며 원격 게시·commit·push는 수행하지 않는다.
