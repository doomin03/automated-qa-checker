# Proposal

## Why

product-planning의 게시 QA 수신·Suite pin·업무 담당자 선택을 실제 앱/서버로 연결할 때, 서버 runtime/권한 조회와 개인 Suite pin 복원·프로젝트 회원 선택 API가 빠져 있다. 기존 48개 HTTP 경로의 실행·예약·업무 기능을 재구현하지 않고 이 조회 누락을 보완하여 원본 판정과 공유 호환성·업무 상태를 구분한다.

## What Changes

- 인증된 `GET projects/{projectId}/context`에 현재 프로젝트와 역할별 진입 행위, 서버 Engine/contract/hash 및 설치 archive pin metadata를 제공한다. 경로·token·서버 설정은 노출하지 않는다.
- `GET projects/{projectId}/suites/pins`로 현재 사용자의 고정 Suite 목록을 bounded cursor 페이지로 복원한다. 구버전 pin을 자동 삭제하거나 승격하지 않는다.
- manager 전용 `GET projects/{projectId}/members`로 업무 담당자 선택의 활성 프로젝트 회원 ID/role/nullable displayName을 제공한다. 사용자 관리 CRUD나 개인 QA 배정함을 추가하지 않는다.
- 기존 Nest DTO/controller → OpenAPI → 고정 TS/Dart SDK 생성 순서를 유지하고 additive 계약/권한/재시작/멱등·무실행 회귀를 검증한다.
- D/W/A 화면·현재 endpoint·누락·6개 상태 축을 서버 인계 문서로 연결한다. Flutter 앱 소비/반응형 검증은 별도 담당 작업이다.

## Capabilities

### New Capabilities

- `project-client-context`: 프로젝트 권한과 서버 실행 pin을 비밀정보 없이 조회한다.
- `personal-suite-pin-discovery`: 사용자·프로젝트에 속한 Suite 고정 선택을 지속적으로 조회한다.
- `project-work-assignee-discovery`: manager가 업무 담당자 선택을 위해 활성 프로젝트 회원만 조회한다.

### Modified Capabilities

없음. 기존 API와 Engine DSL/pin은 유지한다. 현재 openspec/specs inventory는 비어 있으며 기존 change의 계약을 이 proposal에서 바꾸지 않는다.

## Impact

기준 Checker main `3e73cd1f14b0aab658748e9c9b5c1be4a87794ad`, 조사 시작 clean. 수정 범위는 apps/server, packages/contract, 생성 packages/api-client 및 packages/api_client_dart, 관련 서버/계약 test/docs와 이 OpenSpec다. Flutter·웹 UI·Engine 제품 파일과 root lock/CI는 수정하지 않는다.

HTTP contractVersion은 기존 `/api/v1` additive 확장이다. counterpart는 Flutter 담당의 product-planning 적용 change 및 Engine `alpha.8` Desktop / `alpha.6` 서버·Agent이며 Engine 변경 의존성은 없다. dependsOn: `qa-integrated-product-planning`, `qa-desktop-project-received-home`, `qa-shared-suites`, `qa-auth-workflow`, `refactor-server-web-app-monorepo`. 계약 확정 → 서버 테스트 → SDK 생성/검증 → 앱 소비 순서로 인계한다. 외부 Slack, 운영 배포/인증설정 변경, commit/push는 범위 밖이다.
