# Proposal

## Why

사용자가 전달한 scratch3d 모노레포 OpenSpec의 일부 경로만 이전 QA 설계에 반영되어 서버·다언어 계약·Flutter·CI의 전체 인수 기준이 Checker 안에 모이지 않았다. 원본 change를 QA 제품 역할에 맞게 이관하고 구현 담당과 선행 조건을 명확히 한다.

## What Changes

- 원본 `refactor-server-web-app-monorepo`의 proposal/design/tasks/integration 및 다섯 capability를 Checker에 이관한다. 출처·차이·제외·기존 구현은 [이관 표](integration.md)에 남긴다.
- apps/server, apps/web, apps/app와 공용 TS/Dart 계약의 목표를 유지한다. 현재 pnpm/Turbo 기반은 보존한다.
- 웹은 사용자 공용 QA·XML 전달·진행 앱, Flutter Desktop은 블록/Flow 또는 XML 기반 개별 테스트 개발·실행 앱으로 확정한다. 관리자 업무는 권한별 기능으로 유지한다.
- scratch3d의 내부 engine/게임/물리/3D lifecycle는 제외한다. QA 실행 엔진은 별도 저장소의 고정 release/CLI 계약으로 소비한다.
- 원본 Android 첫 인수를 Windows Desktop 첫 인수로 조정하고 로컬 엔진 실행과 서버 API 연결을 서로 다른 경계로 검증한다.
- OpenAPI export·TS/Dart SDK·health·drift·compatibility·실제 양 client 호출·전체 CI 인수 기준을 누락 없이 추적한다.

## Capabilities

### New Capabilities

- monorepo-workspace: 세 앱·공용 package·독립 엔진 경계와 재현 가능한 실행.
- shared-api-contract: 단일 HTTP 원본, 생성 SDK, validation/error 및 호환성.
- qa-user-web-app: 사용자 QA 문서·XML 전달·실행 관찰과 FSD/UI lifecycle.
- flutter-app-shell: Windows Desktop 구조, 로컬 QA 개발·실행 및 생성 Dart HTTP SDK.
- architecture-verification: deterministic generation, drift, 교차 client, deployment와 실제 단계별 인수.

### Modified Capabilities

없음. 현재 기준 specs가 없고 기존 QA changes와의 소유권은 [integration.md](integration.md)에서 연결한다.

## Impact

- integrationId: automated-qa-foundation
- contractVersion: Checker HTTP v1 목표 / Engine 0.1.0-draft.1 실행 schema 계약은 별도
- dependsOn: qa-monorepo-policy 현재 JS 기반; 엔진 release 계약은 독립 선행
- counterpartRepoChange: automated-qa-engine의 qa-flow-schema-core, qa-playwright-runner, qa-user-web-desktop-handoff
- acceptanceCriteria: 이 change의 모든 spec scenario를 실제 명령·테스트·artifact에 연결한 후에만 구현 인수. 이번 이관은 문서 완료이며 제품 구현 재개는 관리 검토 후다.
- source: 원본 MD 지정 scratch-3d의 로컬 origin/feature @ 325ca653fe213eb02b1b1e6e4fd7edc147f71721이 1차 기준이다. 후속 monorepo-setup @ 2e515c0df05fd592ec18e9e7388bb34eb3e904c5는 비교 참고다. 원격 최신 상태의 증거가 아니다.
