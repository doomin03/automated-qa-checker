# QA Monorepo Policy

## ADDED Requirements

### Requirement: Explicit application ownership
Checker는 web/app/server를 같은 Git 저장소의 독립 앱 경계로 SHALL 관리하고 실제 구현 상태와 독립 엔진 release 경계를 문서화한다.

#### Scenario: Inspect application readiness
- **WHEN** 개발자가 모노레포 정책을 읽는다
- **THEN** 현재 실행 가능한 web과 설계 상태인 Flutter/server를 구분하고 기존 인수 tasks를 찾을 수 있다.

### Requirement: Enforced JavaScript dependency boundaries
저장소 검증은 JS/TS package 간 상대 source import, 비공개 package import, 앱 의존, FSD 상향 import, workspace 순환을 SHALL 거부한다.

#### Scenario: Reject boundary bypass
- **WHEN** web이 server source나 contract의 비공개 subpath를 import한다
- **THEN** 경계 검사는 해당 위반 경로를 출력하고 실패한다.

#### Scenario: Allow public dependency
- **WHEN** web이 workspace:*로 선언된 contract의 명시적 public export를 import한다
- **THEN** 의존 경계 검사가 통과한다.

### Requirement: Independent JavaScript task graph
루트 dev/build는 실제 JS package task만 실행하고 build 선행 의존과 지속 개발 프로세스의 비캐시 실행을 SHALL 구성한다.

#### Scenario: Verify without Flutter
- **WHEN** Flutter가 없는 환경에서 현재 JS 검증과 build를 실행한다
- **THEN** Flutter를 요구하지 않으며 검증 결과는 Flutter/server 인수 완료를 주장하지 않는다.
