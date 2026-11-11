# Proposal

## Why

현재 서버 협업은 명시한 loopback local/test identity로만 동작하고 업무 상태는 todo 초기값이다. 사용자가 승인한 P3/P4에서 조직 로그인·Desktop 세션·업무 처리·알림의 제품 코드를 구현해야 하며 실제 Slack 계정 미확보와 코드 미구현을 구분해야 한다.

## What Changes

- 공식 Slack OpenID Connect authorization code/state/nonce/서명 검증, workspace 허용목록과 사전 등록 membership을 적용한다.
- 서버 영속 session과 CSRF, logout/revocation, Desktop 일회성 callback code·짧은 TTL·PKCE 바인딩을 제공한다. local/test mode는 운영에서 계속 거부한다.
- run outcome과 독립적인 todo/in_progress/done 업무 상태 및 감사·낙관적 동시성 제어를 추가한다.
- 명시 notification 설정과 영속 retry/outbox를 구현하고 로컬 HTTP fixture로 검증한다. 로그인 권한과 알림 전송 권한을 분리하며 외부 Slack 메시지는 보내지 않는다.
- 웹/Flutter 로그인·상태 처리 UI와 생성 SDK를 연결한다. real Slack 운영 인수는 실제 계정/앱 설정 준비 후 별도 수행한다.

## Capabilities

### New Capabilities

- qa-auth-workflow: 조직 인증, Desktop 세션, 업무 상태와 알림.

### Modified Capabilities

없음. 진행 중 qa-platform-services의 구체 후속 인수를 소유한다.

## Impact

dependsOn: qa-platform-services, refactor-server-web-app-monorepo. P4 qa-agent-protocol과 독립된 auth/workflow module을 사용한다. Engine runtime alpha.5/contract0.3.0-draft.1 실행 계약은 변경하지 않는다. HTTP DTO/OpenAPI는 Checker가 소유하며 서버 실구현 뒤 동일 exporter로 SDK를 생성한다.
