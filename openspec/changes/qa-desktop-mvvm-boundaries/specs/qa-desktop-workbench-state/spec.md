# Spec Delta

## Purpose

Desktop 작업 공간은 화면의 재생성과 비동기 작업 중에도 사용자 문서와 실행 설정을 정확히 보존한다. 공유 자원의 수명을 명시하여 화면을 바꾸거나 제거해도 다른 기능의 실행과 편집을 손상시키지 않는다.

## ADDED Requirements

### Requirement: Session settings and draft survive view recreation

작업 공간은 같은 앱 세션 안에서 설정 입력과 진단 대상, 문서 정본을 화면 수명과 분리하여 보존해야 한다(SHALL). 화면 입력은 현 정본을 표시하며 프로세스 재시작을 넘는 자동 저장은 요구하지 않는다.

#### Scenario: Recreate a panel in the same session
- **WHEN** 사용자가 엔진 경로·결과 경로·진단 플랫폼과 문서를 바꾸고 화면만 제거한 뒤 다시 연다
- **THEN** 현재 설정과 문서가 그대로 표시되며 진단/검증/실행이 자동으로 시작되지 않는다

#### Scenario: External document change updates visible editor
- **WHEN** 검증된 수신 또는 변환 결과가 현재 문서에 적용된다
- **THEN** 원문 입력과 이후 검증 대상은 같은 정본을 사용하고 동일 입력 재표시는 불필요하게 선택·조합 중 입력을 초기화하지 않는다

### Requirement: Late operations cannot overwrite newer work

문서 변환·기준 연결·공유 수신 결과는 시작한 문서와 설정이 여전히 유효한 경우에만 적용해야 한다(SHALL). 설정 변경 후 진단 결과도 현재 상태로 오인해 표시하면 안 된다(MUST NOT).

#### Scenario: Edit while transformation is pending
- **WHEN** 변환 중 문서 또는 설정이 바뀌며 원문이 나중에 같은 문자열로 되돌아오더라도 이전 작업이 완료된다
- **THEN** 오래된 결과는 새 작업 공간 문서를 덮어쓰지 않고 적용되지 않았음을 표시한다

#### Scenario: Dispose during pending work
- **WHEN** 작업 공간이 비동기 완료 전에 종료된다
- **THEN** 문서를 변경하거나 종료된 화면에 알림을 보내지 않는다

### Requirement: Shared dependency ownership is explicit

앱이 생성한 공유 실행·통신 자원은 앱 소유자가 정확히 한 번 종료해야 한다(SHALL). 한 화면 또는 소비자의 제거는 다른 소비자가 사용하는 공유 자원을 종료하면 안 되며 외부에서 빌린 자원은 외부 소유자가 종료해야 한다(MUST).

#### Scenario: Remove one consumer
- **WHEN** 실행 소비자를 제거했지만 같은 세션에서 기준 검사 소비자가 남아 있다
- **THEN** 공유 엔진 서비스는 살아 있으며 마지막 소유 scope 종료 때 한 번만 정리된다

#### Scenario: Externally supplied service
- **WHEN** 외부 소유 서비스가 주입된 작업 공간을 종료한다
- **THEN** 앱 구독은 해제되지만 외부 서비스는 임의로 종료하지 않는다

### Requirement: Explicit execution and existing evidence remain intact

재구성된 화면은 기존 공개 엔진 검증·명시 실행·취소와 snapshot/이벤트/결과 증거 대조를 보존해야 한다(SHALL). 상태 이동·화면 표시·가져오기만으로 실행하거나 결과 성공을 합성하면 안 된다(MUST NOT).

#### Scenario: Actual CLI round trip
- **WHEN** 사용자가 문서를 검증하고 실행하거나 실행 취소를 요청한다
- **THEN** 같은 고정 CLI에서 실제 결과·terminal·취소 판정을 받아 표시하고 변경된 설정이나 문서는 다시 검증해야 한다
