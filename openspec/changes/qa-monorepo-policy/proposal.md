# Checker 모노레포 정책과 검증

## Why

Flutter·웹·서버 경계는 기존 설계에 있으나 참조 worktree 디렉터리와 제품 모노레포의 구분, 구현 상태, 실제 의존 검사 및 root task graph를 명확히 해야 한다.

## What Changes

- 기존 pnpm/Turbo 구조와 독립 엔진 정책을 하나의 모노레포 정책 문서로 연결한다.
- 앱/공통 package 의존 및 JS/TS source 경계 검사를 검증 파이프라인에 추가한다.
- root dev/build task를 구성하고 현재 웹만 실행·빌드됨을 명시한다.
- Flutter/Nest 실제 생성과 제품 기능은 기존 change에서 계속 추적한다.

## Capabilities

### New Capabilities

- qa-monorepo-policy: 의존 경계와 재현 가능한 JS task orchestration.

### Modified Capabilities

없음.

## Impact

- integrationId: automated-qa-foundation
- contractVersion: 0.1.0-draft.1
- dependsOn: qa-flow-editor / qa-platform-services의 P0 설계
- counterpartRepoChange: 없음; engine 계약/소스 변경 없음
- acceptanceCriteria: 허용된 공개 import는 통과하고 cross-app/deep import/역방향/순환은 거부되며 기존 실제 UI 검증과 JS build가 통과한다. Flutter/서버 미구현을 명시한다.
