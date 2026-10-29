# Flutter Flow 편집과 로컬 엔진 통합

## ADDED Requirements

### Requirement: Engine owned schema round trip
Desktop은 engine release의 스키마로 Flow를 작성·저장·검증하도록 SHALL 구성한다.

#### Scenario: Supported path
- **WHEN** 노드와 분기/selector를 편집하고 저장 후 다시 읽는다
- **THEN** engine validate가 통과하고 실행 의미와 UI metadata가 보존된다.

#### Scenario: Rejected or failure path
- **WHEN** 저장 문서의 schemaVersion이 지원되지 않는다
- **THEN** silent migration 없이 오류와 업그레이드 경로를 표시한다.

#### Scenario: Equivalent block and XML definitions
- **WHEN** 사용자가 블록/Flow로 테스트를 만들고 XML을 생성하거나 같은 의미의 XML을 직접 붙여넣는다
- **THEN** 두 입력은 동일 Engine parse/validate/compile-plan 경로에서 같은 실행 의미를 가진다. 내부 JSON 모델 사용은 허용하며 XML 원문 편집만으로 블록 builder 인수를 완료하지 않는다.

#### Scenario: Offline local development
- **WHEN** 공용 서버에 연결하지 않고 로컬 정의를 편집·검증·실행한다
- **THEN** 호환 엔진과 대상 환경이 있으면 가능하며 서버 로그인은 로컬 엔진 호출의 필수조건이 아니다.

### Requirement: Pinned local engine bridge
Desktop은 정확한 버전/hash와 capability를 확인한 engine CLI만 SHALL 실행한다.

#### Scenario: Supported path
- **WHEN** 지원되는 target에서 Flow를 실행한다
- **THEN** shell 문자열 조립 없이 executable/args로 실제 엔진을 호출한다.

#### Scenario: Rejected or failure path
- **WHEN** release 미고정 또는 capability가 맞지 않는다
- **THEN** 실행을 차단하고 mismatch/unsupported 사유를 표시한다.

### Requirement: Truthful run presentation
Desktop은 node events/result/evidence와 오류·취소를 구분해 SHALL 표시한다.

#### Scenario: Supported path
- **WHEN** 실제 웹 Flow가 성공 또는 실패한다
- **THEN** 각각의 outcome과 failure node/screenshot/로그를 표시한다.

#### Scenario: Rejected or failure path
- **WHEN** CLI 비정상 종료 또는 최종 result 누락이 발생한다
- **THEN** 완료 성공을 표시하지 않고 환경 오류와 진단을 보여준다.

