# Proposal

## Why

A07의 사용자·권한 관리가 환경 provisioning에만 의존한다. 현재 PlatformRepository.start는 매 시작 사용자 활성 상태와 membership을 seed로 덮어쓰므로 HTTP CRUD만 붙이면 변경이 재시작 때 소실된다. 실제 프로젝트 관리 UI를 추가하기 전에 영속 권한의 권위와 기존 실행 환경 호환성을 확정해야 한다.

## What Changes

- 명시 `QA_IDENTITY_STORAGE=managed`에서만 영속 사용자·membership 관리 API를 활성화한다. 기본 provisioned 모드는 기존 환경 재조정 동작을 유지한다.
- 관리 DB 상태에 identity 저장 모드를 기록하고 managed DB를 provisioned로 자동 재조정하지 않는다. 최초 전환은 기존 자료를 보존하며 이후 seed가 API 변경을 덮어쓰지 않는다.
- 기존 프로젝트 scope에서 bounded 사용자 조회·생성·표시명/활성 변경, membership 추가·역할 변경·제거를 revision/audit/idempotency와 함께 제공한다. 권한 상승·다른 프로젝트 정보 노출·마지막 관리자 제거를 거부한다.
- DTO/OpenAPI/생성 TS·Dart SDK 및 실제 HTTP/재시작 인수를 추가한다. A07 웹 소비는 `qa-web-project-workspaces`에서 수행한다.

## Capabilities

### New Capabilities

- `persistent-project-administration`: 기존 provisioning 호환성을 보존하면서 프로젝트 사용자·membership을 영속 관리한다.

### Modified Capabilities

없음. 기존 auth/session·조회 endpoint의 응답과 Engine 계약을 유지한다. 새 관리 endpoint는 별도 namespace다.

## Impact

dependsOn: `qa-auth-workflow`, `qa-product-planning-backend-context`. counterpart: 후속 `qa-web-project-workspaces`, `qa-assignment-inbox`; Engine 변경 없음. contractVersion: Checker `/api/v1` additive. 기준 main `3e73cd1`의 기존 dirty tree를 보존한다.

수정 예정: apps/server의 config/repository/관리 module, 서버 tests/docs, packages/contract 및 생성 양 SDK. Flutter 제품·desktop scripts·Engine·운영 환경설정은 수정하지 않는다. 새 조직 전역 권한, 프로젝트 생성/삭제, team 권한상속, 실제 외부 초대는 별도 A07 후속이며 이 change 완료로 전체 A07 완료를 주장하지 않는다. 제품 적용은 strict와 관리 검토 후다.
