# Flutter Flow 편집과 로컬 엔진 통합

## Why

QA 담당자가 코드 없이 동일 engine Flow를 작성하고 실제 실행 증거를 확인해야 한다.

## What Changes

apps/app에 TC/Flow CRUD, nodes/edges editor, undo/redo, engine CLI bridge와 run view를 구현한다. P0는 경로·소비 manifest·명세만 준비하며 로그인/registry/예약은 후속 change다.

사용자는 블록/Flow 또는 XML 원문으로 원하는 테스트를 만든다. 블록 편집 결과와 직접 작성 XML은 같은 엔진 정규화·검증·실행계획으로 이어진다. 내부 JSON 편집 모델을 허용하며 XML을 임의 shell/script로 해석하지 않는다.

## Capabilities

### New Capabilities

- qa-desktop-flow: Flutter Flow 편집과 로컬 엔진 통합의 요구사항과 인수 시나리오.

### Modified Capabilities

없음. 현재 구현된 기준 spec이 없다.

## Impact

- integrationId: automated-qa-foundation
- contractVersion: 0.1.0-draft.1
- dependsOn: refactor-server-web-app-monorepo의 Flutter toolchain/shell 기반, engine qa-flow-schema-core + qa-playwright-runner의 실제 테스트와 고정 release
- counterpartRepoChange: automated-qa-engine/openspec/changes/qa-flow-schema-core; automated-qa-engine/openspec/changes/qa-playwright-runner
- phase: P2

acceptanceCriteria: 아래 spec의 성공·실패 시나리오와 tasks의 실제 검증을 모두 통과해야 구현 완료다. P0에서는 기획·설계·기반 설정만 완료한다.

