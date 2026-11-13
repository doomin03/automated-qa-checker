# Tasks

## 1. P0 기획과 구조

- [x] 1.1 실제 저장소·참조 branch·도구 현황과 제약을 문서화한다.
- [x] 1.2 역할 경계·계약 초안·counterpart·인수 시나리오를 작성한다.
- [x] 1.3 고정 dependency 설치와 foundation/OpenSpec strict 검증 결과를 기록한다. 근거: docs/validation.md.

## 2. P3/P4 구현 및 인수

- [x] 2.1 P3: Nest/React 및 OpenAPI/SDK 생성 버전을 spike 후 고정하고 앱을 생성한다.
- [ ] 2.2 P3: Slack 공식 OIDC/desktop callback을 검증하고 RBAC/unauthorized 테스트를 구현한다.
- [x] 2.3 P3: registry immutable release/review/pin/upgrade diff와 관리자 UI를 구현한다.
- [x] 2.4 P4: Agent 인증/protocol 별도 change를 engine와 연계해 확정한다.
- [x] 2.5 P4: timezone/occurrence/idempotency/queue/device lease/fencing을 구현한다.
- [x] 2.6 P4: replay/artifact storage/baseline comparison/missed/notification retry를 구현한다.
- [x] 2.7 P3/P4: 실제 서버·클라이언트·Agent 통합과 duplicate/lease/offline/unauthorized 인수를 검증한다.

## 3. 사용자 웹과 Desktop 전달

- [x] 3.1 공용 XML version/hash 및 권한별 Desktop 전달을 구현하고 잘못된 권한·수신 자동실행 방지 테스트를 통과한다.
- [x] 3.2 진행 자동 수신 transport를 고정하고 실제 웹 재연결에서 run/attempt/snapshot/sequence 중복·gap 검증을 통과한다. 파일 교환 검증만으로 완료하지 않는다.

## 4. 완료 처리

아래 세부 단위는 기존2.2/2.3/2.6 및3.1/3.2의 인수 소유를 구체화한다. 로컬 identity 또는 polling만으로 OIDC/예약/Agent 전체를 완료 처리하지 않는다.

- [x] 4.2 SQLite migration/Repository transaction과 사용자·프로젝트 membership을 구현하고 재시작 보존·삭제 사용자·교차 프로젝트·production local/test identity 거부를 검증한다.
- [x] 4.3 Registry draft/review/immutable publish/version/hash/pin API와 생성 SDK를 구현하고 동시 발행·같은 key 멱등·다른 payload409 및 권한을 검증한다.
- [x] 4.4 Desktop 공용 목록/버전 수신→hash 검증→초안 적용을 연결하고 수신 자동 실행 없음을 실제 UI에서 검증한다.
- [x] 4.5 서버 run ID↔Engine run/attempt/snapshot 및 인증 batch events/cursor polling을 구현하고 중복/상이 payload/gap/terminal 이후 append·재시작·웹 재연결을 검증한다.
- [x] 4.6 artifact bytes 업로드·크기/hash·원자 저장과 result 증거 검증완료를 구현하고 누락/변조/권한/중단 복구를 검증한다.
- [x] 4.7 실제 서버→Desktop 수신·명시 CLI 실행→웹 자동 진행/결과 수직 단위를 양 SDK·브라우저·Flutter 경로로 인수하고 독립 로컬 실행이 계속 가능한지 확인한다.

- [ ] 4.1 실제 검증 증거를 연결하고 미완료 기능이 없는지 확인한 뒤 기준 spec sync/archive를 수행한다.


2026-10-31 alpha.5 인수 근거: docs/validation.md 및 artifacts/flutter-design/verification.json, flutter-design-ui/ui-verification.json, flutter-authoring/verification.json, flutter-shared/verification.json, flutter-shared-ui/verification.json, shared-web-verification.json. 전체 서버 OIDC/Agent/Suite/예약 인수와 구분한다.
