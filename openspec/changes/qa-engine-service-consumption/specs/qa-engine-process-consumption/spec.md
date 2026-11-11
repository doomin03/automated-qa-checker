# Spec Delta

## Purpose

Desktop과 서버가 공개 Engine CLI를 소비할 때 출력량과 프로세스 수명을 제한하고, 사용자 화면의 응답 속도나 오류가 실제 실행 결과를 왜곡하지 않도록 한다.

## ADDED Requirements

### Requirement: Bounded process lifetime
CLI 소비자 SHALL 명령의 exit와 출력 EOF를 포함한 전체 기한과 유한한 종료 정리 기한을 적용한다. 강제 종료나 pipe 누락은 성공으로 판정하지 않는다.

#### Scenario: Process exits without usable output
- **WHEN** 프로세스가 비정상 종료하거나 올바른 응답 없이 출력이 닫힌다
- **THEN** 제한 시간 안에 안전한 오류를 반환하고 직접 시작한 프로세스·구독을 정리한다

#### Scenario: Child hangs
- **WHEN** 직접 시작한 child가 명령 기한을 초과한다
- **THEN** child를 종료하고 유한한 정리 후 환경 오류를 반환한다

### Requirement: Independent bounded output consumption
Desktop SHALL UI 이벤트 구독의 pause와 독립적으로 CLI stdout/stderr를 읽고 고정된 누계 출력 한도를 적용한다. 진단 원문이나 비밀값을 오류 화면에 복사하지 않는다.

#### Scenario: Slow UI consumer
- **WHEN** UI가 진행 이벤트 구독을 일시 정지한다
- **THEN** 제한 내 CLI 출력과 취소 처리는 계속 진행하며 재개 후 순서대로 이벤트를 받는다

#### Scenario: Excessive output
- **WHEN** stdout 또는 stderr가 한도를 넘거나 JSONL/UTF8이 잘못된다
- **THEN** 직접 child를 정리하고 성공/정상 취소를 합성하지 않는 오류를 표시한다

### Requirement: Honest cancellation and disposal
Desktop SHALL 취소 요청을 실행당 한 번 전송하고 기한 내 종료를 확인한다. 구독 취소·dispose는 직접 소유한 child를 유한하게 정리한다.

#### Scenario: Cancel during paused subscription
- **WHEN** UI 이벤트 구독이 멈춘 상태에서 사용자가 취소한다
- **THEN** 공개 stdin 제어를 전송하며 정상 cancelled 결과는 terminal·result·exit 일치 후에만 인정한다

#### Scenario: Unresponsive cancellation
- **WHEN** child가 취소 제어에도 응답하지 않는다
- **THEN** 유한한 fallback 종료를 수행하고 결과 누락을 정상 취소와 구분한다

### Requirement: Evidence based service readiness
소비자 인수 SHALL 공개 Engine version/hash·실행 환경·실제 결과·소요시간·지원 한계를 기록하고 검증하지 않은 플랫폼이나 운영 환경을 완료로 표시하지 않는다.

#### Scenario: Package upgrade assessment
- **WHEN** 새 Engine 후보가 전달된다
- **THEN** 관리 승인된 hash를 확인한 별도 설치로 실제 PASS/FAIL/cancel 및 해당 회귀를 수행하고 검증 전 기본 pin을 변경하지 않는다

#### Scenario: Isolated alpha seven acceptance
- **WHEN** alpha.7의 관리 승인 package/hash가 준비된다
- **THEN** 독립 설치·주입 manifest로 실제 Service PASS/FAIL/cancel·1000node 결과·지연 assertion을 인수하고 source pin·기존 설치·Release·서버/Agent 설정은 alpha.6으로 보존한다
- **AND** 새 Windows 배포와 서버/Agent 운영 승격은 완료로 보고하지 않는다

### Requirement: Reachable large flow nodes
Desktop SHALL 지원하는 큰 Flow의 node를 스크롤로 접근·선택할 수 있게 한다. 캔버스 표시나 단순 선택만으로 원문 좌표·문서 revision을 변경하지 않는다.

#### Scenario: Forty and one thousand nodes
- **WHEN** 40개 또는1000개 node 문서를 표시한다
- **THEN** 마지막 node까지 캔버스에 포함되고 스크롤·선택이 가능하며 build/선택 시간을 기록한다

#### Scenario: Existing presentation positions
- **WHEN** 저장된 좌표를 불러오거나 node를 실제 이동한다
- **THEN** 저장 좌표를 보존하며 명시 이동만 좌표 변경으로 반영하고 undo로 복원한다
