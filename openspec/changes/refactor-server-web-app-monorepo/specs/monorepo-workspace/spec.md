# Monorepo Workspace

## Purpose

서버, 웹, Desktop 앱을 한 저장소에서 독립적으로 개발하고 공용 계약과 라이브러리를 일관된 경계로 소비하도록 한다. 신규 개발자가 동일한 도구 버전과 명령으로 설치 및 실행을 재현할 수 있어야 한다.

## ADDED Requirements

### Requirement: Three application boundaries
저장소는 apps/server, apps/web, apps/app을 독립 실행 단위로 제공하고 공용 기능은 packages 아래에서 공개 API로 소비하도록 SHALL 구성한다.

#### Scenario: Discover application entry points
- **WHEN** 개발자가 저장소의 개발 문서를 따라 실행 대상을 찾는다
- **THEN** server, web, app 각각의 경로와 실행 명령이 명시되고 다른 앱 소스의 직접 import 없이 실행할 수 있다.

#### Scenario: Reject cross-application source imports
- **WHEN** web 또는 server가 다른 앱 내부 source를 상대 경로로 import한다
- **THEN** 경계 검사가 실패하고 위반 경로를 보고한다.

#### Scenario: Keep execution engine independent
- **WHEN** Checker가 QA 실행 기능을 연결한다
- **THEN** 고정된 공개 엔진 release/CLI를 소비하고 엔진 소스·submodule·커밋된 외부 로컬 경로 의존성을 추가하지 않는다.

### Requirement: Reproducible toolchains
저장소는 JavaScript 및 Flutter toolchain과 의존성 해석 결과, 계약 생성 도구 버전을 고정하여 동일 checkout에서 재현 가능한 설치를 SHALL 제공한다.

#### Scenario: Clean installation
- **WHEN** 문서에 명시된 도구가 있는 깨끗한 checkout에서 설치를 수행한다
- **THEN** 고정 lockfile을 소비하고 의도하지 않은 lockfile 갱신 없이 server/web과 Flutter 의존성을 설치한다.

#### Scenario: Unsupported toolchain
- **WHEN** full verification에 필요한 Flutter 또는 generator runtime이 없거나 지원 버전과 다르다
- **THEN** 검증은 필요한 도구 정보를 표시하며 실패하고 해당 단계를 성공으로 건너뛰지 않는다.

### Requirement: Independent development commands
root 명령은 server/web 개발과 Flutter 실행을 분리하고 실패 exit code와 사용자 인자를 보존하도록 SHALL 동작한다.

#### Scenario: Work without Flutter
- **WHEN** Flutter가 없는 환경에서 JS 전용 설치 및 server/web dev/build를 실행한다
- **THEN** Flutter 프로세스를 요구하지 않고 두 JS 앱의 명령이 실행된다.

#### Scenario: Run desktop with device configuration
- **WHEN** 개발자가 dev:app에 기기와 API origin 설정을 전달한다
- **THEN** Flutter 실행은 apps/app에서 해당 설정을 사용하고 실패 시 root 명령도 실패한다.

### Requirement: Deterministic build dependencies
공용 산출물을 사용하는 빌드는 필요한 선행 산출물을 준비해야 하며 계약 생성과 서버 빌드 사이 순환 의존을 만들지 않도록 SHALL 구성한다.

#### Scenario: Build from clean outputs
- **WHEN** dist/build 폴더가 없는 checkout에서 문서의 JS build를 실행한다
- **THEN** 공용 패키지와 SDK가 소비자보다 먼저 빌드되고 server가 generated client를 요구하지 않는다.

#### Scenario: Run persistent development tasks
- **WHEN** server/web dev를 실행한다
- **THEN** 지속 실행 작업의 이전 cache 결과로 서버 프로세스 시작을 대체하지 않는다.
