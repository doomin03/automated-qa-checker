# Product backend context 검증

2026-11-12, Checker main `3e73cd1f14b0aab658748e9c9b5c1be4a87794ad`에서 시작했다. 제품 변경은 서버/HTTP 계약/TS·Dart SDK와 관련 테스트·문서다. Flutter 변경은 별도 담당자의 `qa-desktop-planning-responsive`이며 아래 서버 인수가 앱 반응형·Windows Release 인수를 대신하지 않는다.

OpenSpec `qa-product-planning-backend-context` proposal/design/specs/tasks를 먼저 작성하고 strict PASS와 관리 apply 승인 후 구현했다. API는 기존 48 경로에 context/members 2경로와 기존 Suite pins 경로의 GET 1개를 추가했다. Engine DSL/alpha.6 서버·Agent/alpha.8 Desktop pin, 인증 설정, DB migration, 기존 mutation 의미는 변경하지 않았다.

## 실제 인수

| 명령 / 실행 위치 | 결과 | 근거 |
| --- | --- | --- |
| `corepack pnpm --filter @automated-qa-checker/server build` / repo | PASS | tsc exit 0 |
| `node --test test/*.test.mjs` / apps/server | 44 tests PASS | artifacts/product-backend-context/server-tests.log |
| `node --test test/workflow.test.mjs` / apps/server | 최종 inactive assignee 거부 추가 후 6 PASS | workflow-final.log |
| `node packages/contract/generator/contract-tools.mjs generate` / repo | PASS | 고정 generator JAR/Java/Dart 검증 및 TS/Dart 생성 |
| `node packages/contract/generator/contract-tools.mjs check` / repo | PASS, 생성물 drift 없음 | contract-check.log |
| `corepack pnpm --filter @automated-qa-checker/api-client build` / repo | PASS | tsc exit 0 |
| `node --test packages/api-client/test/*.test.mjs` / repo | 10 PASS | ts-tests.log |
| 고정 Dart `analyze`, `test` / packages/api_client_dart | 분석 오류 없음, 8 PASS | dart-analyze.log, dart-tests.log |
| `node packages/contract/generator/platform-integration.mjs` / repo | 실제 Nest HTTP TS/Dart 모두 PASS | platform-sdk-integration.log |
| `node scripts/check-api-compatibility.mjs --base-ref HEAD` 및 기본 accepted baseline | 모두 compatible | baseline SHA f705acfa8a30d4c89ec8f588a2d85bd49a837ee1084d93fa273a725f3a09ef90 |
| `node scripts/check-boundaries.mjs` | PASS | monorepo 경계 검사 |
| `node --test packages/contract/generator/contract-tools.test.mjs tests/api-compatibility.test.mjs tests/boundaries.test.mjs` | 13 PASS | 계약 lint/drift/compatibility negative/경계 테스트 |

고정 Dart 경로는 `C:/workspace/QA/.tools/flutter-3.47.5/bin/cache/dart-sdk/bin/dart.exe`다. 기본 shell PATH에 pnpm이 없어 `corepack pnpm run contract:generate`의 내부 pnpm 호출이 실패했다. 동일 서버 build와 공식 generator를 직접 순서대로 실행했고 생성기/제품 스크립트는 변경하지 않았다. 전체 verify에는 artifacts 아래 로컬 corepack shim을 생성하여 해당 프로세스 PATH에만 추가한다.

최초 Dart 인수 테스트가 생성 enum에 없는 `.toJson()`을 사용해 analyze와 통합이 실패했다. 테스트를 실제 생성 enum의 `.value`로 수정하고 analyze/unit/실제 HTTP 모두 재검증했다. 생성 코드를 수동 수정하거나 실패를 성공으로 집계하지 않았다.

## 확인한 경계

- context: 인증 없음/비활성 401, 다른 프로젝트 403, 5역할별 정확한 action 집합, 실제 contract bytes SHA 대조, archive 없는 manifest의 null, secret/경로 미노출, 조회 동안 Engine plan 호출 없음.
- members: manager만 허용, active 프로젝트 회원 100개 초과를 두 페이지로 중복 없이 조회, 다른 프로젝트 및 inactive 제외, nullable 이름, 잘못된 cursor/limit 거부. 기존 업무 테스트에서 inactive/다른 프로젝트 assignee, concurrent revision, 결과 불변을 확인했다.
- Suite pins: 현재 사용자/프로젝트 격리, 정확한 package/version/hash, paging, 재시작 복원, runtime 불일치에도 저장 pin 보존, 같은 불일치 pin 쓰기는 기존 409, 조회·게시 동안 run 생성 0.
- SDK: actual HTTP의 context actions/runtime, member null, Suite draft/review/publish/pin/list를 두 언어로 왕복했다. 단위 테스트는 null archive 허용과 잘못된 action/누락된 engine 거부도 확인한다.
- 기존 Registry/Suite 독립 검토, workflow 판정 분리, Agent/Scheduler 회귀는 서버 전체 테스트로 유지한다. 역할 action은 진입 힌트이며 mutation 성공을 보장하지 않는다.

## 범위와 남은 제약

archiveSha256은 설치 pin metadata이고 현재 archive bytes 재검증이 아니다. 개인 Suite paging은 snapshot이 아니며 조회 사이 pin 변경이 반영된다. displayName은 현재 DB가 이름을 저장하지 않아 null이다. A03 회원 조회 계약을 제공하지만 이번 Desktop에는 업무 배정 편집 UI를 추가하지 않았다.

기본 서버 alpha.6과 Desktop 로컬 alpha.8 불일치 차단은 유지한다. 공용 수신/로컬 실행 가능과 서버 결과 공유 가능은 다르다. 실제 Slack 계정, Appium 실기기, 운영 배포, 새 개인 배정 기능, 사용자 관리 CRUD는 이 인수에 포함하지 않는다. work done, Engine outcome, evidence, execution/lease, occurrence, Desktop 전송 상태를 합치지 않았다.

## 최종 기록

전체 저장소 `pnpm run verify`가 exit 0으로 완료됐다. 로그는 `artifacts/product-backend-context/verify.log`다. foundation/lint/monorepo 경계, TypeScript, package checks(최종 서버 44 tests 포함), 전체 OpenSpec strict, server/web build, 실제 web UI 및 production/development route 회귀를 통과했다. Flutter Windows build/analyze/반응형 인수는 이 명령에 포함되지 않는다.

독립 담당자도 새 HTTP 6/6, 기존 OpenAPI operation/schema 불변, TypeScript action 10개/null roundtrip 및 malformed 응답 거부를 재검증했다. 관리 근거는 `coordination/product-implementation-20261112/backend-independent-review.md`다.

최종 변경 파일과 Engine pin 7개 SHA, OpenAPI 신규 operation, 로그 해시는 `artifacts/product-backend-context/evidence.json`에 기록한다. `snapshot.mjs`로 같은 범위를 재수집할 수 있다. artifact 경로는 로컬 검증 산출물이며 제품에 새 실행 의존성을 만들지 않는다.

`git diff --check`는 정식 generator가 출력한 TS API 주석 13곳의 trailing whitespace를 보고한다. 생성물 재현성을 유지하기 위해 수동 trim하지 않았고 drift check는 통과했다. 웹 build의 500 kB chunk 크기 안내는 실패가 아닌 기존 빌드 경고이며 이번 서버 작업으로 웹 번들을 분할하지 않았다. 원격 commit/push/배포 및 사용자 인증 설정 변경은 수행하지 않았다.
