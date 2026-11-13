# Design

## D1. 소유와 기존 인수

Checker 담당은 modules/auth/**, modules/workflow/**, 관련 웹/Flutter UI를 소유한다. 서버 하위 담당은 Agent/scheduler/lease/storage와 기존 root module/config wiring 및 generator를 소유한다. 기존 PlatformRepository 공개 transaction 경계를 공유하되 migration 번호는 분리한다. local Registry 인수를 운영 로그인 완료로 바꾸지 않는다.

## D2. OIDC와 세션

2026-10-31 공식 Slack discovery는 issuer https://slack.com, authorize /openid/connect/authorize, token /api/openid.connect.token, jwks /openid/connect/keys, RS256, code/query 및 client_secret_basic/post를 제공한다. 공개 openid-client6.8.8을 exact pin하고 서명 검증을 활성화한다. state와 nonce는 암호학적 난수이며 DB에는 state/hash·browser correlation·만료·사용 여부를 저장한다. callback은 한 번만 소비하고 nonce/iss/aud/exp/JWKS 서명을 검증한 뒤 allowed workspace와 사전 등록 사용자/프로젝트 membership을 확인한다. id/access token과 client secret은 UI·로그·artifact·DB에 저장하지 않는다.

웹 세션은 opaque random identifier의 hash만 서버 DB에 저장하고 HttpOnly/Secure/SameSite=Lax cookie 및 명시 CSRF token을 사용한다. 변경 요청은 허용 Origin과 CSRF를 모두 요구한다. session expiry/로그아웃/사용자 비활성화는 즉시 거부한다. production은 고정 Slack HTTPS metadata만 허용한다. loopback 테스트 OIDC 제공자는 NODE_ENV=test에서만 명시 허용한다.

Desktop은 서버 OAuth callback 후 승인된 loopback callback URI에 짧은 TTL 일회성 전달 code만 받는다. 임의 원격 callback/fragment/userinfo는 금지한다. Desktop이 만든 S256 challenge에 code를 묶고 교환 때 verifier를 검증한다. 실제 app session bearer는 교환 응답에서만 받아 메모리에서 사용한다. callback 수신만으로 테스트 실행은 일어나지 않는다. 종료·logout은 메모리를 정리하고 서버 세션을 폐기한다.

## D3. 업무 상태와 알림

업무 row는 run의 immutable outcome과 별도로 status/assignee/revision을 저장한다. 프로젝트 qa_tester 이상만 전이하며 동일 revision 조건의 transaction으로 충돌409를 반환한다. done은 QA 성공 판정이 아니며 감사에는 행위/사용자/시간만 기록한다.

알림은 운영자가 별도로 설정한 sink와 권한으로 전송한다. Slack 로그인 token을 알림에 재사용하지 않는다. 영속 outbox는 payload hash/idempotency key/attempt/nextRetry/lease를 보관하고 유한 timeout·최대 재시도 후 delivery_failed를 표시한다. 전달 실패는 QA outcome·업무 처리 결과를 덮어쓰지 않는다. 원문 secret/실행 XML/개인 캡처값을 payload에 넣지 않는다. 이번 인수는 local HTTP fixture이며 외부 Slack 전송은 별도 명시 지시가 있어야 한다.

## D4. 검증과 제한

previous comparable baseline/regression은 workflow module이 소유한다. 같은 scenario/target/engine와 검증된 profile/reference 범위만 비교하고 Result.executed에 없는 browser/OS를 추정하지 않는다. 필요한 증거가 없으면 incomparable 사유를 반환한다. 수동 baseline 선택·업무 상태는 원래 Engine outcome·이미지 기준을 바꾸지 않는다. step/outcome regression 비교와 이미지 기준 파일 승격은 구분한다.

image/layout 보고서는 실제 profileHash와 referenceHash를 요구한다. UX 보고서는 referenceHash가 없는 정상 계약을 허용하되 실제 profileHash와 node/kind를 identity로 사용한다. UX profileHash가 없는 이전 출력, blocked/미지원 보고서는 비교 불가로 둔다. 디자인 보고서는 같은 profile/reference 중복을 제거하여 첫 이미지 실패로 후속 동일 기준 layout이 미방문인 경우를 비교할 수 있다.

로컬 RS256 provider의 실제 authorize→callback→token/JWKS 교환에서 state/nonce/issuer/audience/서명/expiry/workspace/replay 실패, session/logout/revoked user, Desktop code TTL/PKCE/reuse를 검증한다. SDK 및 웹/Flutter 사용자 경로를 별도로 확인한다. 실제 Slack 계정·네트워크·등록 redirect URI 검증은 환경이 준비되지 않아 미완료로 남긴다. notification retry/멱등/재시작 및 권한 검증은 local fixture에서 수행한다.

공식 근거: https://docs.slack.dev/authentication/sign-in-with-slack/ , https://slack.com/.well-known/openid-configuration , https://github.com/panva/openid-client/tree/main/docs .
