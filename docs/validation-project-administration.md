# A07 서버·계약 인수

변경: `qa-persistent-project-administration`. 저장소 기준은 main `3e73cd1f14b0aab658748e9c9b5c1be4a87794ad`이며 기존 앱·Engine 소비·문서의 working tree 변경을 보존했다. 이번 범위는 서버와 생성 SDK다. A07 웹 관리 화면은 후속 구현이며 현재 제공하지 않는다.

## 실제 검증

| 명령 | 결과 | 근거 |
| --- | --- | --- |
| `tsc -p apps/server/tsconfig.json` | PASS | 이후 테스트가 해당 빌드를 소비 |
| 서버 cwd `node --test test/administration.test.mjs` | 10/10 PASS | `artifacts/administration/focused.log` (명시 clear 계약 추가 전 집중 결과) |
| 서버 cwd `node --test test/*.test.mjs` | 54/54 PASS | `artifacts/administration/server-tests-final.log` (명시 clear 계약 포함) |
| `node packages/contract/generator/contract-tools.mjs generate` | PASS | `artifacts/administration/sdk-generate-final.log` |
| `node packages/contract/generator/contract-tools.mjs check` | PASS, drift 없음 | `artifacts/administration/sdk-drift.log` |
| `node scripts/check-api-compatibility.mjs` | PASS | `artifacts/administration/compatibility.log` |
| `node --test packages/api-client/test/*.test.mjs` | 12/12 PASS | `artifacts/administration/ts-sdk-tests.log` |
| `node packages/contract/generator/administration-integration.mjs` | TS/Dart 실제 HTTP PASS | `artifacts/administration/sdk-http.log` |
| `node --test packages/contract/generator/contract-tools.test.mjs tests/api-compatibility.test.mjs` | PASS | `artifacts/administration/contract-tests.log` |
| `openspec validate qa-persistent-project-administration --strict --no-interactive` | PASS | `artifacts/administration/strict.log` |
| `pnpm run verify` | exit 0 PASS | `artifacts/administration/verify.log` (foundation/lint/boundaries/types/packages/strict/build/browser UI/routes) |

SDK HTTP 검사는 임시 managed Nest 서버에서 양 생성 API가 사용자 생성, 표시명 비우기, 이름 설정, active-only 변경, membership 제거를 수행한다. Dart 모델 6개 검사에는 required nullable 이름/role 및 명시 clear 직렬화가 포함된다. 실제 외부 IdP 로그인이나 사용자 초대는 수행하지 않았다. 임시 서버는 종료하고 DB는 진단을 위해 OS temp에 보존한다. 인증용 임시 token은 로그로 출력하지 않는다.

`sdk-freeze.json`은 인계 시점 OpenAPI·TS·Dart 생성물 339파일 hash를 기록한다. OpenAPI SHA256은 `9697841dfcdf8db6e8e0e083695ae6242bdc1905f8c823e5b611f07abf27ad68`이다. Engine 실행 schema와 alpha6 기본 서버 pin은 이 변경에서 수정하지 않았다.

## 보존과 실패 처리

최초 전체 회귀는 54 중 52 PASS, 중첩 부모 테스트를 포함한 2 FAIL이었다. 원인은 기존 provisioned fixture의 trusted 물리 사용자 삭제가 새 sidecar FK로 차단된 단일 호환성 결함이었다. 최초 로그 `server-tests.log`를 남겼고 신규 user FK만 기존 cascade 의미에 맞춘 뒤 전체를 다시 통과했다. 회원 해제 tombstone은 유지하며 HTTP user hard delete를 추가하지 않았다. migration 10은 운영 배포 전 개발 변경이다.

기존 실제 alpha6 Chromium 실행 fixture의 Blueprint/events/result 원본 bytes와 provenance SHA를 사용했다. 임시 서버에 게시 버전과 Run 하나를 저장한 다음 관리 변경과 재시작 전후 versions/runs/events 저장 행, events hash, 조회 응답을 정확히 비교했다. reviewer의 실제 review/publish 403과 권한 있는 게시자의 철회된 review에 대한 409도 검증했다. 이 검사는 새 브라우저 실행이나 PNG 보존 인수가 아니다.

managed adoption은 기존 DB가 있으면 seed 전체를 무시한다. 관리자 누락을 seed로 조용히 복구하지 않으며 시작을 거부한다. downgrade 거부, 기존 provisioned 동작, revision/ABA, scope/role, global 변경의 모든 프로젝트 권한, 같은 DB의 web/desktop 세션 및 code 폐기, 재활성화 뒤 과거 세션 거부를 검사했다. 운영 전환·관리자 복구 절차는 [project-administration.md](architecture/project-administration.md)를 따른다.

## 남은 경계

실제 운영 DB 변경·외부 IdP 로그인·A07 웹 화면·새 관리자의 HTTP 승격은 이번 인수에 없다. 기존 generated PlatformApi/SuiteApi의 JSDoc 빈행 trailing whitespace 13곳은 `git diff --check`에서 보고되며 생성기 출력을 수동 편집하지 않았다. 기능 검증과 이 형식 경고는 구분한다. Flutter 전체 테스트와 native/Release 빌드는 앱 담당자의 별도 인수다.
