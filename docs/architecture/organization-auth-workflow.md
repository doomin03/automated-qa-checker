# 조직 인증과 실행 업무

`qa-auth-workflow`의 구현과 당시 인수 기록이다. 외부 Slack 계정 인수와 local provider 검증을 구분한다. 아래 alpha.5 / 0.3.0-draft.1은 이 변경의 과거 검증 범위이며 현재 pin을 뜻하지 않는다. 2026-11-11 현재 기본 서버/Agent alpha.6과 Desktop alpha.8은 [시스템 설계](system-design.md) 및 [최신 홈 인수](../validation-project-home.md)를 따른다. 로그인·업무 상태가 실행 결과를 재정의하지 않는 원칙은 유지한다.

## 조직 설정

`QA_AUTH_MODE=oidc`, `QA_OIDC_CLIENT_ID`, `QA_OIDC_CLIENT_SECRET`, `QA_OIDC_CALLBACK_URL=https://<api-host>/api/v1/auth/callback`, `QA_OIDC_WEB_ORIGIN=https://<web-host>`, `QA_OIDC_ALLOWED_WORKSPACES=T...`를 프로세스 환경 또는 비밀 저장소에서 공급한다. 고정 Slack discovery 의미를 사용하는 openid-client6.8.8/RS256 검증이며 임의 외부 issuer를 허용하지 않는다. callback과 웹 주소는 정확한 HTTPS 주소여야 한다. Slack 앱에 동일 callback을 등록한다.

`QA_IDENTITY_PROVISION_JSON`은 `users[{id,active}]`, `projects[{id,name}]`, `memberships[{userId,projectId,role}]`를 사전 등록한다. `QA_OIDC_BINDINGS_JSON`은 `[{subject:"U...",workspace:"T...",userId:"등록한 id"}]`다. 로그인은 사용자를 생성하거나 권한을 승격하지 않는다. 실제 client secret·session·token 값은 예제 파일에 넣지 않는다. 기존 `QA_DATA_DIR`, Engine CLI/manifest 설정은 [로컬 데모](../local-demo.md)와 같다.

웹에서 서버 주소를 입력하고 `조직 로그인`을 누른 뒤 돌아오면 `조직 세션 확인`을 선택한다. 프로젝트를 확인하고 `공유 연결`을 누른다. session cookie는 HttpOnly이고 변경 요청은 허용 Origin과 CSRF를 함께 검사한다. Flutter의 `브라우저에서 조직 로그인`은 Windows 기본 브라우저를 열고 임시 loopback callback에서 PKCE로 묶인 일회성 code를 교환한다. 실제 bearer는 메모리에만 두고 서버 주소가 다른 연결에 사용하지 않는다. 로그아웃은 서버 세션을 폐기하고 공유 연결을 해제한다. 로그인 성공·callback 수신은 QA 실행 권한 요청이나 자동 실행을 뜻하지 않는다.

`oidc-test`는 NODE_ENV=test와 loopback HTTP issuer에서만 허용한다. `tests/auth-fixture.mjs`는 테스트용 RS256 제공자와 실제 Nest/SQLite를 시작하며 Slack에 연결하지 않는다. Flutter 테스트는 시스템 브라우저 launcher를 HTTP redirect driver로 대체하고 실제 callback/socket/SDK를 사용한다. Windows 기본 브라우저 수동 조작과 실제 Slack 계정 로그인은 별도 환경 인수다.

## 업무와 비교

업무 status는 todo/in_progress/done이며 담당자는 활성 프로젝트 사용자여야 한다. qa_tester 이상이 현재 revision을 보내서 변경하고 충돌은409다. done은 Engine passed를 의미하지 않는다. 서버 outcome·원본 result·이미지 baseline 파일은 불변이다.

비교는 동일 Blueprint snapshot, target, Engine version 및 실제 검증된 check-report profile/reference hash 집합을 요구한다. 한 검사의 실패로 후속 노드가 미방문이면 같은 profile/reference의 중복 보고서는 identity에서 중복 제거한다. 환경 정보가 없으면 `ENVIRONMENT_EVIDENCE_ABSENT`, 불일치하면 incomparable다. 자동 비교는 직전100개 terminal run에서 일치하는 가장 최근 실행을 찾는다. 명시 baseline 선택도 같은 조건을 통과해야 하며 비교 결과와 변경 node 목록을 표시한다. 이것은 outcome/step 회귀 비교이며 이미지 기준 승격 기능이 아니다.

UX 보고서는 referenceHash가 없는 계약 정상 출력이다. 실제 profileHash와 node/kind를 비교 identity에 사용한다. alpha5 UX처럼 profileHash가 없는 출력이나 blocked/미지원 보고서는 비교 불가다. Engine alpha6 설치 소비자의 실제 UX 보고서 bytes를 별도 fixture로 검증했으며 이 fixture 사용은 runtime pin 변경을 뜻하지 않는다.

## 알림

현재 실제 전송 구현은 명시한 loopback HTTP fixture다. `QA_NOTIFICATION_MODE=local-test`, `QA_NOTIFICATION_URL=http://127.0.0.1:<port>/<path>`를 설정하며 production에서 거부한다. 외부 Slack 발송은 구현·인수 완료로 주장하지 않는다. 조직 로그인 token을 알림에 재사용하지 않는다.

qa_manager 이상이 terminal run 알림을 요청한다. payload는 run/project ID, outcome, evidence 상태와 업무 revision만 포함하고 XML·이미지·사용자 입력·secret은 포함하지 않는다. outbox는 SQLite에 영속화하며 같은 run/payload는 같은 delivery ID다. POST의 Idempotency-Key를 fixture가 중복 제거해야 한다. 응답 유실 시 재전송할 수 있으므로 exactly-once 전송을 보장하지 않는다. 5초 timeout, lease15초, 최대5회 재시도 후 delivery_failed를 표시한다. 재시도 시 원래 요청자의 현재 프로젝트 권한도 재검사한다. 서버 종료 중 미확정 전송은 기존 lease 만료 뒤 재개한다. 알림 실패는 QA outcome을 바꾸지 않는다.

## 검증 범위

- `apps/server/test/auth.test.mjs`: 실제 HTTP RS256 provider, state/nonce/signature/issuer/audience/expiry/workspace, CSRF, logout, 사용자 비활성화, Desktop TTL/PKCE/one-use.
- `apps/app/test/organization_ui_test.dart`: Provider 화면→실제 callback/생성 SDK→공유 연결→logout, 자동 실행 없음.
- `tests/auth-ui.test.mjs`: 실제 Chromium→조직 로그인→cookie/CSRF SDK 초안 저장→logout.
- `apps/server/test/workflow.test.mjs`: 업무 권한/revision/재시작, 영속 outbox 동일 delivery 재시도, 환경 비교 정책. 비교 profile은 명시 fixture이며 실제 QA 실행 인수와 구분한다.
- `tests/workflow-ui.test.mjs`: Flutter가 생성한 실제 alpha.5 디자인 PASS/FAIL evidence를 서버로 게시하고 웹에서 업무·회귀·로컬 알림을 확인한다. 결과 파일은 artifacts/workflow-web-verification.json이다.

공식 기준: [Slack Sign in](https://docs.slack.dev/authentication/sign-in-with-slack/), [OIDC discovery](https://slack.com/.well-known/openid-configuration), [openid-client](https://github.com/panva/openid-client/tree/main/docs).
