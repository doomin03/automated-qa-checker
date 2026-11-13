# Tasks

## 1. 설계와 인증

- [x] 1.1 공식 OIDC 설정·exact dependency·서버 identity 경계를 정합하고 OpenSpec strict를 통과한다.
- [x] 1.2 RS256 OIDC callback/state/nonce/workspace 검증과 영속 session·CSRF/logout/revocation을 구현하고 실제 local provider fixture를 통과한다.
- [x] 1.3 Desktop callback code TTL/one-use/PKCE와 서버 session 교환을 구현하고 재사용/잘못된 verifier를 거부한다.
- [x] 1.4 생성 SDK와 웹/Flutter 로그인 UI를 연결하고 실제 로컬 provider 경로를 검증한다. 실제 Slack 계정 인수는 별도 남긴다.

## 2. 업무와 알림

- [x] 2.1 업무 상태/담당/revision/audit를 구현하고 권한·동시성·재시작·outcome 불변을 검증한다.
- [x] 2.2 영속 알림 outbox/재시도/권한을 구현하고 외부 메시지 없이 local HTTP fixture로 검증한다.
- [x] 2.3 업무·알림 UI를 연결하고 SDK/OpenAPI drift 및 제품 통합 검증을 완료한다.
- [x] 2.4 명시 baseline 선택과 previous comparable run 비교를 구현한다. 동일 시나리오/target/engine 및 확인 가능한 profile/reference만 비교하고 환경 정보 부족은 incomparable로 반환하며 outcome 판정과 이미지 기준 승격을 혼동하지 않는다.

## 3. 환경 인수

- [ ] 3.1 실제 Slack 앱 credentials·workspace·redirect 설정을 준비한 환경에서 조직 로그인/운영 배포를 인수한다. fixture만으로 완료 처리하지 않는다.
