# Tasks

## 1. P0 기획과 구조

- [x] 1.1 실제 저장소·참조 branch·도구 현황과 제약을 문서화한다.
- [x] 1.2 역할 경계·계약 초안·counterpart·인수 시나리오를 작성한다.
- [x] 1.3 고정 dependency 설치와 foundation/OpenSpec strict 검증 결과를 기록한다. 근거: docs/validation.md.

## 2. P3/P4 구현 및 인수 — 아직 시작하지 않음

- [ ] 2.1 P3: Nest/React 및 OpenAPI/SDK 생성 버전을 spike 후 고정하고 앱을 생성한다.
- [ ] 2.2 P3: Slack 공식 OIDC/desktop callback을 검증하고 RBAC/unauthorized 테스트를 구현한다.
- [ ] 2.3 P3: registry immutable release/review/pin/upgrade diff와 관리자 UI를 구현한다.
- [ ] 2.4 P4: Agent 인증/protocol 별도 change를 engine와 연계해 확정한다.
- [ ] 2.5 P4: timezone/occurrence/idempotency/queue/device lease/fencing을 구현한다.
- [ ] 2.6 P4: replay/artifact storage/baseline comparison/missed/notification retry를 구현한다.
- [ ] 2.7 P3/P4: 실제 서버·클라이언트·Agent 통합과 duplicate/lease/offline/unauthorized 인수를 검증한다.

## 3. 사용자 웹과 Desktop 전달

- [ ] 3.1 공용 XML version/hash 및 권한별 Desktop 전달을 구현하고 잘못된 권한·수신 자동실행 방지 테스트를 통과한다.
- [ ] 3.2 진행 자동 수신 transport를 고정하고 실제 웹 재연결에서 run/attempt/snapshot/sequence 중복·gap 검증을 통과한다. 파일 교환 검증만으로 완료하지 않는다.

## 4. 완료 처리

- [ ] 4.1 실제 검증 증거를 연결하고 미완료 기능이 없는지 확인한 뒤 기준 spec sync/archive를 수행한다.

