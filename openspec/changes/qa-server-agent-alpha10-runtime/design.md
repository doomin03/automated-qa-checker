# Design

## Context

EngineContractService는 설치 파일 manifest와 version을 검증한다. Platform.createRun은 현재 runtime 및 snapshot exact match를 요구한다. Agent 등록은 당시 runtime/version/contract SHA를 고정하며 claim이 등록 triple을 비교한다. Scheduler는 준비된 옛 pin이 현재와 맞지 않으면 engine_pin_incompatible을 기록한다. 이 경계를 완화해서 연결하지 않는다.

## Decisions

### D1. Separate canonical server runtime

새 `packages/contract/runtime/engine-runtime.json`은 검증 alpha.10의 archive/version/contract/bundle/entrypoint/files exact pin을 담는다. 앱 desktop manifest와 package 파일 SHA를 대조한다. 기존 `packages/contract/engine-dependency.json`, generated legacy alpha.6 bundle, `apps/app/assets/engine-runtime.json` 및 engine-contract.json은 역사 소비/회귀 기준으로 보존한다. 서버 현재 runtime의 권위는 새 manifest이며 문서에서 legacy 계약 fixture와 명확히 구분한다.

새 준비 명령은 명시 archive 경로를 입력받아 pinned SHA를 먼저 확인하고 `.local/engine-server-alpha10`에 별도 설치한다. 기존 `.local/engine`/candidate/desktop 경로를 수정하지 않는다. 설치 후 manifest의 모든 package 파일·CLI version·contract/bundle SHA를 검증하고 local receipt를 쓴다. 설치가 이미 존재하면 검증해 재사용하고 불일치 시 자동 덮어쓰기 없이 거부한다. receipt의 절대 경로는 local ignored 파일에만 두며 배포 manifest에 개발 PC 경로를 넣지 않는다. 설치 helper는 shell 문자열로 입력 경로를 실행하지 않는다.

### D2. New demo lane; explicit existing deployments

agent-demo 및 agent-demo-admin의 기본 runtime은 새 서버 설치/manifest로 통일하고 새 demo directory 기본값 `agent-demo-alpha10`을 사용한다. 기존 명시 QA_ENGINE_CLI/QA_ENGINE_MANIFEST override는 보존하며 둘 중 하나만 주면 혼합 pin이 되지 않도록 명시 거부한다. 운영 bootstrap은 여전히 기존 환경 변수를 요구하고 사용자의 설정을 바꾸지 않는다. 새 앱 quickstart는 서버 준비·실행 시 같은 pin을 지정하도록 안내한다.

기존 Agent 등록의 runtime triple을 SQL UPDATE하거나 credential/state를 재사용해 승격하지 않는다. 새 검증 lane은 새 agent identity/provision/state/resource를 사용한다. 같은 이름의 기존 Agent가 다른 runtime이면 startup에서 진단 후 거부한다. 기존 job/lease/resource fence·receipt·불변 게시 버전·Run을 변경하지 않는다. active/unknown lease를 자동 recover 또는 성공으로 처리하지 않는다.

### D3. Actual sharing and history

실제 alpha.10 Chromium 실행에서 생성된 Blueprint/events/result/PNG를 Platform HTTP로 게시한다. snapshot/engineVersion·이벤트 순서·artifact SHA/size·evidence verified 및 다운로드 bytes를 검사한다. 업무 상태는 실행 판정과 독립이다. 인증/소유권 검사는 기존 경로를 사용한다.

동일 임시 DB에 alpha.6 실제 fixture의 게시 버전·Run을 먼저 저장하고 서버를 alpha.10으로 재시작한다. 기존 GET·events/result·artifact 상태와 저장된 version이 유지되는지 비교한다. alpha.6 신규 createRun은 현재 alpha.10과 맞지 않아 거부되어야 하며 잘못된 snapshot/version도 거부한다. 기존 Run의 후속 전송은 저장된 Run identity를 검사하는 현재 규칙을 보존한다. old GET이 새 엔진 실행 지원을 뜻하지 않는다.

### D4. Agent, Suite and schedule acceptance

실제 alpha.10 Agent 프로세스가 새 서버의 lease를 받아 로컬 Chromium을 실행하고 event/result/artifact delivery 및 receipt/cleanup confirmed를 완료하는 수직 경로를 인수한다. Suite는 두 case 순차 실행의 각각 runId/status를 확인하며 stopOnFailure의 미실행 case에 결과를 합성하지 않는다. 예약은 실제 Scheduler의 제어된 clock으로 due occurrence 한 번을 생성해 실제 Agent가 소비하도록 한다. 가짜 시간 사용은 명시하며 일주일 실제 대기를 주장하지 않는다.

취소 요청을 먼저 반환하고 Engine cancel/terminal 결과·전송·cleanup을 별도 관측한다. 취소/timeout/unsupported를 passed로 바꾸지 않는다. 실제 브라우저·소유 worker 프로세스 종료 및 bounded deadline을 기록한다. 기존 alpha.6 Agent 등록으로 alpha.10 claim을 시도하면 거부하며 기존 등록/lease/history bytes가 변하지 않아야 한다.

### D5. Compatibility and rollout limits

HTTP DTO/schema가 변하지 않으므로 A07에서 고정한 OpenAPI/SDK를 재생성하지 않는다. Agent protocol source SHA와 기존 execution schema bytes를 대조한다. 준비 명령/manifest 변경으로 실제 운영 배포나 기존 데이터 migration을 실행하지 않는다. 이 통합 완료 전까지 Desktop과 alpha.6 서버의 공유 제한 설명을 제거하지 않는다. 마지막 앱 Release는 앱 담당자의 현재 소비 source와 별도 검증한다.

## Validation

설치 archive/파일/CLI/bundle pins, tamper 거부, alpha.6 경로 보존; 실제 PNG 게시/다운로드; oldGET/newingestion mismatches; 실제 Agent Suite/예약/cancel/cleanup; 기존 서버 전체54 및 repository verify 회귀. 실제 외부 모바일·Slack·production은 수행하지 않는다. 승인 전에는 이 change의 제품 변경을 시작하지 않는다.
