# 서버·생성 SDK 검증 인계

2026-10-31, 작업 시작 main / `4f97e920a399d4a5434ab1ecbe44c4d879d397a4`. 후속 관리 할당으로 qa-platform-services의 로컬 인증·영속 Registry·실행 공유를 구현했다. 공통 OpenSpec task 체크와 root scripts/lock은 Checker owner가 관리한다. commit/push는 하지 않았다.

## 후속 협업 API 인수

- `apps/server/test/platform.test.mjs`: 실제 Nest HTTP, SQLite 임시 DB, 설치된 공개 Engine alpha.5 / contract 0.3.0-draft.1을 소비한다. schema 실패, loopback failclosed, token hash, role/교차 프로젝트/삭제 사용자, 독립 검수, 동시 멱등 발행, immutable 버전, pin/diff/pagination/audit를 검증한다.
- run 시작 Blueprint/version/hash 고정, 원자 배치/중복/충돌/gap/terminal, node 시작·종료·재시도 규칙, result node/snapshot/outcome 일치, bytes/hash/MIME/quota, staging 실패 복구·재시작 증거 검증을 확인한다.
- `node packages/contract/generator/platform-integration.mjs`: 동일 Nest 프로세스에 TS와 Dart 공개 PlatformClient가 실제 검수·발행·pin·run 생성·이벤트 polling·result·403을 왕복했다. Engine 실행 자체는 fixture이며 실제 browser 실행이라고 보고하지 않는다.
- TS build 및 테스트 6개, Dart analyze clean 및 테스트 5개, generator 테스트 2개와 boundaries PASS. 최신 generate 이후 read-only check 재생성도 PASS.
- 공개 SDK는 서버 DTO → offline OpenAPI → pinned generator → TS/Dart 순서로 생성한다. 응답 검증에 쓰는 schema와 operation metadata도 같은 OpenAPI에서 생성한다. DTO 재정의·endpoint 복제는 없다.
- workStatus todo는 초기값이며 업무 전이 미구현. OIDC 실로그인/Slack, scheduler/Agent, baseline 승인, 확대 test-only fixture spike·base branch breaking gate는 별도 미완료다. 로컬 운영 방법과 동기 SQLite 규모 제한은 [PLATFORM.md](PLATFORM.md)에 있다.

아래는 최초 health foundation 인수 기록이다. 파일 수·fingerprint·health-only 경로는 그 당시 결과이며 최신 협업 API 산출물을 뜻하지 않는다.

## 실제 수행

| 명령·관측 | 결과 |
| --- | --- |
| `pnpm --filter @automated-qa-checker/server check` | TypeScript build, Nest 테스트 5개 PASS: mapper, 실제 health/query/error/schema/requestId, CORS, offline/runtime 동일, 시험 전용 body/path/numeric/UTC/list |
| `pnpm --filter @automated-qa-checker/api-client check` | SDK/adapter compile, TS 테스트 4개 PASS: null/required/enum/unknown field, 오류·timeout, origin, caller cancel |
| SDK 디렉터리 `dart pub get --enforce-lockfile` | 고정 Dart3.13.4, lock 유지 |
| SDK `dart analyze` / `dart test` | 분석 오류 없음, Dart 테스트 3개 PASS. analyzer는 생성 코드와 테스트를 제외하지 않음 |
| `node --test packages/contract/generator/contract-tools.test.mjs` | 2개 PASS: duplicate operation/ref 거부, 수정/삭제/추가/미생성 파일 비교 |
| `node packages/contract/generator/integration.mjs` | 실제 Nest 한 프로세스에 양 SDK null/web/app/HTTP400 호출 및 transport 분리 PASS |
| `contract-tools.mjs generate` 후 `check` | 같은 입력 재생성 일치, 저장소 출력 불변 |
| `node scripts/check-boundaries.mjs` | 공개 package/import 경계 PASS |
| `openspec validate refactor-server-web-app-monorepo --strict --no-interactive` | PASS |

마지막 generation/check의 대상 30파일을 path+bytes로 합산한 SHA-256은 `8d7fa200d0b59e564f8ded04e6076dfc0e9d9df6bd302a853849e37dfb29a603`이며 check 전후 동일했다. 개별 파일 SHA가 아니라 검사 대상 전체 fingerprint다. 생성 소스와 pin은 [generator 안내](../../packages/contract/generator/README.md)를 참조한다.

실제 production main에 PORT=0/API_DOCS=true를 주고 curl.exe로 확인했다. `health?client=web`은 200 정상 DTO, `health?client=desktop`은 400 VALIDATION_ERROR와 client detail, `/api/openapi.json`은 200/OpenAPI3.0.3 및 production health 경로 하나를 반환했다. 시험 프로세스는 확인 후 종료했다. Windows GUI나 웹 화면 클릭의 검증을 의미하지 않는다.

## 관리 검토용 작업 대응

- 4.1~4.6: 서버 기반 구현 및 실제 인수 근거 확보. 4.5 시험 controller의 HTTP 검증은 생성 SDK 확대 spike와 구분한다.
- 5.2: server build→offline export→동일 OpenAPI TS/Dart generation→build_runner 순서와 재현성 확인. root 명령 연결은 owner 작업이다.
- 5.4: 양 adapter HTTP 오류/transport/timeout/unknown field 검증.
- 5.5: 격리 재생성, 모든 생성 파일 비교 및 실제 read-only check. root alias 연결은 owner 작업이다.
- 7.1: 같은 실제 서버를 TS/Dart 생성 SDK가 호출한 증거 확보.
- 1.4, 7.2: **미완료**. body/path/numeric/UTC/list/optional의 확대 fixture를 양 SDK로 생성·왕복하는 spike 및 수용된 base branch 대비 breaking gate가 남았다.
- 5.1 전체 fixture 세트·최초 baseline 수용, 5.3 web UI, 6.2~6.5 Flutter 소비·실행, full CI/전체 통합은 별도 인수한다. 이 보고로 전체 monorepo 완료를 표시하지 않는다.

## 후속 의존 계획

관리 검토 이후 OIDC/JWKS identity→프로젝트 RBAC→Registry revision/hash→run/progress append→scheduler/Agent 순서로 명세와 계약을 구체화한다. 관리 제안의 node:sqlite 영속 Repository 및 migration/transaction은 아직 구현하지 않았다. 외부 Slack credentials 부재와 테스트용 인증을 production 로그인 완료로 간주하지 않는다.
