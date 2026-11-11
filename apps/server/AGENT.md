# Agent 서버와 예약

Agent는 독립 Engine CLI이며 서버는 등록 credential, published snapshot, 실행권, 전달 cursor 및 증거 저장을 소유한다. 사용자 token과 Agent token은 별도이고 DB에는 hash만 저장한다. SQLite는 단일 서버의 동기 Repository 구현이다. 다중 서버 운영 DB 인수는 이 구현의 범위가 아니다.

## 계약과 검증 상태

- 검토된 Agent HTTP `0.1.0-draft.1`: `packages/contract/agent-protocol/v0.1.0-draft.1/openapi.json`, SHA `8c25e3c853f3b8d24003464d2ddc55a20675b7ac3f741a46c238a50ce4149490`.
- Nest DTO/controller → offline OpenAPI → 고정 generator TS/Dart SDK가 제품 편집 경로다. `check-agent-slice.mjs`는 request/success schema를 참조 해제해 검토 artifact와 비교한다.
- 기존 alpha.6 candidate1의 실제 PASS/FAIL/claim 응답유실/event ACK유실/cancel은 이전 HTTP SHA `754b35...f9de`의 별도 checkpoint다. `.local/agent-demo-alpha6/server-verification.json`은 DB event/result/PNG bytes/hash를 대조한 로컬 근거다. 새 wire/candidate와 혼합해 완료로 표시하지 않는다.
- 실제 lifecycle·재시작·TTL·동시 complete·receipt 유실·retired owner·운영 복구 회귀는 `test/agent.test.mjs`, DST·중복 tick·재시작·missed·disable은 `test/scheduler.test.mjs`에서 검증한다. 독립 Engine의 추가 crash/recovery/Suite/예약 counter 인수는 OpenSpec tasks에 따라 별도로 기록한다.
- candidate2 archive SHA `0dce64bf4b3be2bab09cce56c96e394f1cfa759eae3b7535f5fbc7e8ae908c45`와 현재 Agent wire의 실제 설치 CLI 인수: idle204 후 crash/restart, 다른 state root의 동일 credential 동시 실행 거부, 순서 있는 FAIL→PASS 두 case/stopOnFailure/cancel, recovered-only 및 closed receipt+recovered 혼합 owner, PNG reference 다운로드 후 assertImage를 통과했다. `.local/agent-demo-alpha6-candidate2/server-verification.json`은 12 executions/13 artifact byte hash/2 operator recovery를 DB와 대조한다.
- 실제 예약 인수는 published Blueprint를 다른 reviewer가 검수·발행하고 한 case Suite를 발행·pin한 뒤 UTC occurrence 하나를 설치 Agent가 실행했다. 대상 POST는 1회, occurrence 1개, receipt ACK 후 재시작도 중복 실행이 없었다. 두 case 순서 검증과 이 한 case published 예약 인수는 별도 항목이다. 모든 fixture 서버·target은 인수 후 종료했고 DB/증거는 보존했다.

## 실행권과 증거

최종 alpha6 archive SHA `33dbcacea025fb98a52fb0411af05cb113bc85e47e84a98463912b6aace1acef`도 별도 실제 Nest 인수에 사용했다. `scripts/agent-artifact-loss.mjs`가 첫 artifact PUT의 서버 저장 후 응답을 한 번 유실시켰다. Agent는 complete/receipt를 다시 조회해 이미 저장된 한 파일을 확인하고 나머지 세 파일을 전송했다. 최종 네 파일의 size/SHA, closed/confirmed, receipt ACK와 대상 POST 한 번을 확인했다. 같은 durable state로 재시작해도 QA는 중복 실행되지 않았다. 이 경로는 동일 PUT 재전송을 강요하지 않으며 서버의 동일 본문 업로드 멱등 회귀와 구분한다. 근거는 `.local/agent-artifact-loss-final/matrix-247e7680-ef18-4a4b-ad8f-64081b58e3f5/verification.json`이며 관리자가 DB/실제 파일을 독립 대조했다.

리소스 경로 인수는 Checker의 opaque ID·bytes/hash/크기 검증과 Engine의 파일 materialize 경계를 구분한다. Engine `tests/agent-protocol.test.mjs`의 UNC/절대경로 5형식 거부 회귀는 resource HTTP 요청 0회를 확인했다. 같은 파일의 font/subdir·hash 회귀, `tests/design.test.mjs`의 실제 Windows junction escape 거부, `tests/input-evidence.test.mjs`의 외부 absolute/junction 거부를 함께 참조한다. Engine `docs/validation-alpha.6.md`에 근거가 있으며 UNC 회귀 추가는 test-only로 최종 배포 archive bytes를 바꾸지 않았다.

같은 Agent는 unresolved lease 하나만 가질 수 있다. 새 instance는 이전 owner를 자동으로 대체하지 않는다. 같은 durable claim request는 같은 배정을 반환하되 remaining TTL은 매번 재계산한다. TTL30초/heartbeat5초/request5초/safety5초이며 Agent는 요청 시작 monotonic 시각에서 안전기한을 계산한다.

서버 재시작, 만료 또는 cleanup 불명은 resource를 quarantine한다. 자동 회수는 closed lease만 허용한다. 명시 qa_manager 운영 복구는 현재 resource/lease/fence와 프로세스·외부 세션 종료 확인, 사유, requestId를 검사하고 fence를 증가시킨다. 원래 QA outcome/result/cleanup/evidence는 보존한다. recovered는 성공이나 verified가 아니며 새 job을 자동 생성하지 않는다. retired owner는 다시 claim할 수 없다.

사용자 ExecutionResponse의 resourceKey/fence/cleanupState/operatorRecovery는 required nullable이다. qa_manager 이상에게만 운영 값이 보이며 viewer/tester는 null이다. 복구 endpoint는 별도로 qa_manager 권한과 정확한 현재 fence를 검사한다. HTTP metadata 조회부터 복구까지 DB 직접 편집 없이 사용할 수 있다. 101개 closed lease의 reconcile pagination과 100+1 receipt 누적 ACK도 실제 HTTP 회귀로 검증한다.

case의 실제 run.started부터 Engine runId/attempt/snapshot을 고정한다. 전송 순서는 execution deliverySequence이며 Engine 원본 sequence를 덮어쓰지 않는다. batch는 같은 payload 멱등, 다른 payload/gap409 및 원자 rollback이다. Suite 순서와 stopOnFailure를 검사한다. complete metadata, artifact bytes, cleanup, immutable receipt를 분리한다. 원격 outcome을 수신했다고 외부 실행의 진실성을 보증하지 않는다.

resource/file10MiB, execution artifact64MiB, HTTP body16MiB, claim/reconcile8MiB의 한도가 있다. opaque ID만 서버 파일을 선택한다. 리소스는 안전한 상대 하위경로·hash·size·PNG/JSON/font MIME를 가지며 서버 임의 URL/filesystem proxy는 없다. historical 증거는 live cursor/TTL/권한을 변경하지 않는다. history artifact는 case/path에 따라 bytes를 중복 제거하고64MiB, metadata는 execution8MiB로 제한한다.

## 주간 예약

사용자는 published Blueprint 또는 published Suite의 정확 version/hash를 선택한다. 예약은 canonical case plans와 Engine version/contract/hash를 고정한다. 업그레이드 후 pin이 다르면 미실행 사유로 표시하며 자동 재컴파일하지 않는다.

IANA timezone, ISO weekday1..7, HH:mm, latenessSeconds로 주간 occurrence를 계산한다. DST gap은 missed, overlap은 이른 instant 한 번이다. schedule+local date 및 normalized UTC instant unique와 scan cursor를 transaction에 저장한다. tick 반복/재시작/시계 역행으로 중복 생성하지 않는다. catch-up7일 이전은 집계 audit, 기한이 지나면 scheduler_late 또는 no_eligible_agent_or_resource다. disabled 구간은 다시 enable해도 소급 실행하지 않는다. 이미 claim된 작업 취소는 cleanup까지 resource를 유지한다.

## 로컬 관리 fixture

`node apps/server/scripts/agent-demo.mjs`는 loopback 개발용이다. `.local/<QA_AGENT_DEMO_NAME>`에 별도 DB/config/token 파일을 만들며 token 값을 출력하지 않는다. `PORT`, `QA_DEMO_TARGET_ORIGIN`, `QA_ENGINE_CLI`, `QA_ENGINE_MANIFEST`를 프로세스 환경으로 지정할 수 있다. production에서는 시작을 거부한다. 설치된 public Engine package/검토된 manifest만 사용한다.

`agent-demo-admin.mjs <command> ABS_INPUT_JSON ABS_MANAGER_TOKEN_FILE`은 등록된 manager 인증과 project role을 확인하고 audit를 남긴다. enqueue는 한 public Blueprint JSON, enqueue-cases는 검증용 ordered cases/stopOnFailure, cancel은 projectId/executionId, provision은 scope와 별도 출력 token 파일을 받는다. 이 local fixture는 제품 Suite publish를 대체하지 않는다. recover는 새 wire 환경에서만 사용하며 로컬 fixture의 실제 정리를 확인한 후 호출한다. 운영 기기에 대한 강제 복구는 인수하지 않았다.

recover helper는 실제 실행 중인 demo 서버의 인증 HTTP를 호출한다. 별도 프로세스의 빈 monotonic clock map으로 live lease를 만료 처리하지 않는다. enqueue resources는 `{name,base64,sha256,mimeType}`를 bounded Buffer로 바꿔 공개 Engine 검증을 거친다. `agent-schedule-demo.mjs ABS_INPUT_JSON ABS_MANAGER_TOKEN_FILE`은 별도 scheduler-worker/resource와 reviewer를 사용해 공개 XML→Registry→Suite publish/pin→다음 UTC 분 예약을 구성하는 로컬 인수 도구다. 토큰은 ignored 파일에만 기록한다.

공유 Registry/예약의 현재 published XML 경로는 외부 PNG/font가 필요 없는 시나리오 범위다. PNG reference 전송 실제 인수는 trusted fixture enqueue의 bounded resource manifest 경로이며 공유 자산 패키지 게시 UI가 구현되었다는 뜻이 아니다.

검증 명령은 Checker 저장소 루트에서 `corepack pnpm --filter @automated-qa-checker/server build`, `node --test apps/server/test/agent.test.mjs apps/server/test/scheduler.test.mjs`, `node packages/contract/agent-protocol/validate-draft.mjs`, `node packages/contract/generator/check-agent-slice.mjs`다. Auth/Workflow/Suite 소유 테스트는 `apps/server` cwd에서 실행한다.
