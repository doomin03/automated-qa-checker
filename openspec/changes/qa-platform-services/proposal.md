# 사내 협업·예약·결과 관리

## Why

공통 QA 게시와 주간 실행은 Desktop이 꺼져 있어도 권한·중복 방지·실행 증거를 유지해야 한다.

## What Changes

apps/server의 단일 API, apps/web 사용자 공용 시나리오·진행 및 역할별 관리자 업무, OIDC/RBAC, immutable registry, scheduler/Agent lease/reporting을 단계별로 구현한다. 공용 XML의 권한별 버전 전달과 Desktop/Agent 진행 자동 수신을 포함한다. P0에는 상세 설계만 작성하고 서비스 scaffolding은 하지 않는다.

## Capabilities

### New Capabilities

- qa-collaboration-platform: 사내 협업·예약·결과 관리의 요구사항과 인수 시나리오.

### Modified Capabilities

없음. 현재 구현된 기준 spec이 없다.

## Impact

- integrationId: automated-qa-foundation
- contractVersion: 0.1.0-draft.1
- dependsOn: refactor-server-web-app-monorepo의 health/OpenAPI/SDK bootstrap, qa-flow-editor 및 engine release; P3 인증/권한 → P4 원격 실행
- counterpartRepoChange: automated-qa-engine: P4 Agent protocol change는 후속 제안
- phase: P3/P4

acceptanceCriteria: 아래 spec의 성공·실패 시나리오와 tasks의 실제 검증을 모두 통과해야 구현 완료다. P0에서는 기획·설계·기반 설정만 완료한다.

