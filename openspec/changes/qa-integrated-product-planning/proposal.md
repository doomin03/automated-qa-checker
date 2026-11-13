# Proposal

## Why

사용자는 Engine, 사용자 Desktop, 관리자 웹 전체의 기능 관계·기획·화면설계를 기존 목업에서 함께 검토하도록 요청했다. 지금 목업은 Desktop 작업실과 홈은 연결되지만 사용자 웹의 공용 QA 전달, 관리 역할의 검수·게시·운영, 독립 Engine과 서버 Agent 실행 경계를 한 곳에서 설명하거나 화면으로 왕복하기 어렵다.

## What Changes

- 하나의 로컬 기획 검토 진입점에 관계도, 연속 사용자 여정, 화면 ID별 설계, 동작 목업, 합의·제약을 통합한다.
- Desktop 홈·수신·파일 블록/직접 XML 작업실의 기존 조작을 보존하고 사용자 웹과 역할별 관리 화면을 설계한다.
- 코드 구현, 실제 인수 증거, 이번 화면 구조 제안, 미완료를 개별 기능에 표시한다. 예시 상호작용은 실제 서버/Engine 호출과 구분한다.
- Engine/웹 기획/Checker 담당의 제안·반례·합의를 근거 및 화면에 연결하고 관리 검토 뒤 구현한다.
- 기존 roadmap의 미구현 표기와 현재 증거를 정합하고 시스템 관계도의 결과 수집·게시 주체 및 목표/미구현 관리 기능을 바로잡는다. 과거 auth 인수 버전은 이력으로 보존한다.

## Capabilities

### New Capabilities

- `integrated-product-planning`: 제품 역할·기능 관계·여정·화면설계와 검토 목업을 연결하는 단일 로컬 도구.

### Modified Capabilities

없음. 실행 schema/API/권한 또는 실제 앱 기능은 바꾸지 않는다.

## Impact

소유 경로는 `design/mockups/product-planning/**`, 기존 `design/mockups/xml-block-studio`의 검토 연결만, 관련 docs와 이 change다. 제품 Flutter/Web/Server/Engine 구현 및 release/pin 변경, 원격 게시, commit/push는 범위 밖이다. counterpartRepoChange는 Engine 담당의 공개 계약 실사(제품 변경 없음), contractVersion은 Desktop alpha.8/0.3.0-draft.2 및 기존 Server/Agent alpha.6 고정이다. dependsOn: qa-desktop-project-received-home, qa-desktop-xml-block-studio, qa-product-journey-mockup, qa-user-web-desktop-handoff, qa-platform-services, qa-auth-workflow, qa-shared-suites, qa-desktop-interactive-terminal. 관리 기준은 `C:/workspace/QA/coordination/product-planning-20261111/management-brief.md`다.

proposal/design/specs/tasks strict 통과와 관리 검토 후 apply하여 완료했다. 기존 studio의 review route adapter·별도 검토 저장 영역, 25개 화면, 원본 대응표와 문서 정합을 포함한다. 자체 94검사·기존 목업 14/16검사·웹 독립 24검사, repository verify exit 0 및 최종 관리 시각/연결/보존 인수를 기록했다. 제품 실행·배포 인수의 확대는 아니다.
