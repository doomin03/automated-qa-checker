# Architecture Verification

## Purpose

모노레포 구조와 다언어 계약이 시간이 지나도 일치하도록 검증 절차를 제공한다. 단계별 이전에서 기존 QA 문서와 이벤트 관찰 동작을 보존하고 계약 생성, 클라이언트 연동 및 문서의 실제 상태를 재현 가능한 증거로 확인한다.

## ADDED Requirements

### Requirement: Deterministic generation and drift detection
계약 검증 명령은 같은 입력에서 동일한 OpenAPI와 양 언어 SDK를 재생성하고 저장소와의 차이를 탐지하도록 SHALL 동작한다.

#### Scenario: Repeat generation
- **WHEN** 같은 toolchain/source/config에서 계약 생성 명령을 두 번 실행한다
- **THEN** 시간·host·임시 경로에 의한 diff 없이 같은 파일을 생성한다.

#### Scenario: Detect missing or manually edited generated files
- **WHEN** 생성 결과를 수동 수정하거나 삭제하거나 새 출력 파일을 누락하고 contract check를 실행한다
- **THEN** 검사는 실패하며 tracked diff뿐 아니라 untracked/삭제 파일도 보고하고 working tree를 조용히 고치지 않는다.

### Requirement: Verify both generated clients against a real server
통합 검증은 생성된 TypeScript와 Dart client로 같은 실제 서버를 호출하여 요청과 응답 의미의 일치를 SHALL 확인한다.

#### Scenario: Compare health calls
- **WHEN** 양 client가 client를 생략하거나 web/app 값으로 health를 호출한다
- **THEN** 200 status와 required/nullable 필드가 같은 계약 의미를 가지며 query 직렬화가 실제 서버에 전달된다.

#### Scenario: Verify invalid input and transport failure
- **WHEN** 잘못된 query fixture를 전송하거나 서버가 응답하지 않는 상태를 만든다
- **THEN** 두 adapter가 각각 HTTP 400 공용 오류와 transport failure를 구분한다.

### Requirement: Enforce full verification
전체 검증은 계약 drift/호환성, JS 빌드·타입·경계·테스트와 Dart 분석·테스트, Windows Desktop build를 수행하고 하나의 실패도 성공으로 처리하지 않도록 SHALL 구성한다.

#### Scenario: One toolchain fails
- **WHEN** Dart 분석 또는 JS 계약 테스트가 실패한다
- **THEN** 전체 검증 exit code는 실패이고 수행하지 못한 단계 또는 실패 원인이 표시된다.

#### Scenario: New contract baseline
- **WHEN** 저장소에 최초 OpenAPI 계약을 도입한다
- **THEN** 검증된 baseline을 기록하고 후속 변경은 base branch의 수용된 계약과 비교한다.

### Requirement: Preserve routing behavior in deployment artifacts
production 웹과 서버 구성은 SPA navigation과 API/asset 오류를 구분하여 SHALL 제공한다.

#### Scenario: Open a QA deep link
- **WHEN** 사용자가 웹 QA 경로를 직접 열거나 새로고침한다
- **THEN** 웹 앱이 해당 route를 렌더한다.

#### Scenario: Request missing API or asset
- **WHEN** 존재하지 않는 API 또는 asset 경로를 요청한다
- **THEN** 올바른 오류 status를 반환하며 SPA index.html의 200 응답으로 바꾸지 않는다.

### Requirement: Evidence-based incremental migration
이전 작업은 단계별 동작 확인과 되돌릴 수 있는 변경 단위를 유지하며 문서의 계획과 현재 구현을 구분하도록 SHALL 수행한다.

#### Scenario: Baseline fails before migration
- **WHEN** 기존 checkout의 build 또는 실행이 실패한다
- **THEN** 원인과 필요한 호환 수정 범위를 기록하고 기존 코드가 정상 동작했다고 주장하지 않는다.

#### Scenario: Complete a migration stage
- **WHEN** workspace/계약/API/Desktop 이전 단계가 완료된다
- **THEN** 해당 동작 증거와 문서 변경이 기록되고 실패 시 직전 검증 단계로 되돌릴 수 있다.

#### Scenario: Accept the refactoring
- **WHEN** 모든 spec scenario와 통합 검증을 충족한다
- **THEN** baseline 및 QA 설계의 실제 구현 결과를 갱신한 뒤 OpenSpec을 기준 명세로 반영하며 문서 작성만으로 구현 tasks를 완료 표시하지 않는다.
