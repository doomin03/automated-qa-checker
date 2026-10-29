# 로컬 디자인·UX 검수 작업 흐름

## Purpose

사용자가 명시한 디자인 기준과 기본 UX Blueprint를 배포 웹에 연결하여 실제 실행 증거를 검토하도록 한다. Desktop에서 파일 준비부터 검증·실행·결과 확인까지 제공하고 실행하지 못한 검사를 성공으로 오인하지 않게 한다.

## ADDED Requirements

### Requirement: Explicit local reference binding
Desktop은 로컬 PNG·명시 수치 JSON·selector 매핑·테스트 URL/profile을 입력받고 Engine 공개 계약으로 검증하도록 SHALL 구성한다. 이미지에 없는 수치·동작 기대값을 임의 생성하지 않는다.

#### Scenario: Bind a reference to a page
- **WHEN** 사용자가 기준 파일과 화면/상태/selector, URL/profile을 입력한다
- **THEN** 선택한 기준 버전/hash와 매핑을 확인할 수 있고 파일을 가져오는 것만으로 실행하지 않는다.

#### Scenario: Invalid or changed reference
- **WHEN** 기준 파일이 없거나 PNG/JSON이 잘못되었거나 hash/profile이 맞지 않는다
- **THEN** 문제와 해당 파일/매핑을 표시하고 비교 가능한 정상 실행이나 PASS로 표시하지 않는다.

### Requirement: Bound preset definitions
Desktop은 공개 기본 UX 팩의 버전·필수 입력·capability를 표시하고 바인딩한 Blueprint/XML을 작성·수정할 수 있도록 SHALL 구성한다. 템플릿 전개·XML 검증은 Engine 정본 의미를 유지한다.

#### Scenario: Create a bound XML draft
- **WHEN** 사용자가 웹 back/focus/input/overlay 검사 팩을 선택하고 필요한 selector·입력·기대 상태를 채운다
- **THEN** 같은 Engine 검증·계획 경로로 연결되는 XML 초안을 확인·저장할 수 있고 아직 실행되지 않은 상태를 표시한다.

#### Scenario: Missing expectations or unsupported keyboard
- **WHEN** 뒤로 가기 목적지나 입력 후 기대 상태가 없거나 실제 OS 키보드 검사를 요청한다
- **THEN** 누락 입력 또는 미지원 사유를 표시한다. 이미지로 목적지를 추정하거나 브라우저의 합성 가림 검사를 실제 OS 키보드 인수로 표시하지 않는다.

### Requirement: Explicit pinned engine execution
Desktop은 호환 version/hash/capability가 확인된 Engine에 validate/plan/run/cancel을 전달하고 사용자가 명시 실행한 snapshot만 SHALL 실행한다. 서버 로그인은 로컬 데모의 전제조건이 아니다.

#### Scenario: Validate before explicit run
- **WHEN** 사용자가 XML을 검증하고 계획을 확인한 뒤 실행한다
- **THEN** import/validate/plan은 테스트를 시작하지 않으며 run만 실제 실행을 시작한다. 실행 중 편집한 내용은 현재 snapshot에 적용하지 않는다.

#### Scenario: Mismatched engine or cancellation
- **WHEN** 새 계약 capability가 없거나 사용자가 실행 중 취소한다
- **THEN** 미지원 엔진 실행을 차단한다. 취소 요청과 확인된 종료를 구분하고 종료 증거가 없으면 취소 완료 또는 PASS를 합성하지 않는다.

### Requirement: Evidence based review
Desktop은 실행별 단계·검사 결과, baseline/actual/diff 참조와 expected/actual/tolerance 등 공개 측정값을 SHALL 표시한다. 비교 연산과 판정은 Engine 결과를 소비하고 사용자 검토 상태는 실행 결과와 분리한다.

#### Scenario: Inspect pass and intentional failure
- **WHEN** 실제 웹의 정상 실행과 의도적 시각 또는 UX 실패 결과를 연다
- **THEN** run/attempt/snapshot에 일치하는 결과·실패 node·측정값과 제공된 증거 경로를 확인할 수 있다. 존재하지 않는 diff나 수치는 생성된 것처럼 표시하지 않는다.

#### Scenario: Non comparable or incomplete evidence
- **WHEN** Engine가 비교 불가/미지원/환경 오류를 보고하거나 최종 결과가 없거나 artifact가 허용된 실행 경계를 벗어난다
- **THEN** 사유를 표시하고 테스트 불일치 실패와 구분한다. 누락 결과를 PASS로 바꾸거나 임의 외부 경로를 읽지 않는다.

#### Scenario: Keep reference and review immutable
- **WHEN** 사용자가 차이를 검토하거나 기준 파일을 바꾼다
- **THEN** 검토만으로 기준을 덮어쓰거나 과거 판정을 바꾸지 않는다. 새 기준은 명시적으로 새 버전/hash로 선택하며 과거 실행은 당시 snapshot을 유지한다.

### Requirement: Separate desktop acceptance
이 기능의 Desktop 인수는 실제 Flutter 사용자 입력→검증→실행→결과 흐름과 Windows build 증거를 SHALL 요구한다. 독립 CLI 데모는 엔진 증거로 별도 기록한다.

#### Scenario: CLI evidence only
- **WHEN** 독립 CLI에서 시각/UX PASS·FAIL만 확인했다
- **THEN** Engine 증거로 기록하되 Flutter 연결·실행 화면 인수는 미완료로 남긴다.

#### Scenario: Desktop product evidence
- **WHEN** 서버 없는 Flutter 앱에서 기준·팩·대상을 입력하고 실제 웹을 실행한다
- **THEN** 검증/계획·진행·증거 결과 표시를 확인하며 analyze/test/build와 사용자 실행 경로 증거를 함께 남긴다. 창 초기화 smoke만으로 이 흐름을 대체하지 않는다.
