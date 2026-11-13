# Spec Delta

## Purpose

사용자 PC에 설치된 AI CLI와 기존 인증을 이용해 QA 정의 작성을 도우면서, 생성 결과를 실제 실행과 분리한다. 원본 문서 보존, 전체 Engine 검증, 변경 승인과 취소 및 오래된 결과 차단을 사용자가 확인할 수 있게 한다.

## ADDED Requirements

### Requirement: Explicit local CLI configuration
앱은 AI 공급자와 실행 파일 경로, 설치·지원 여부 진단을 SHALL 제공한다. API 키를 임의 저장하지 않고 기존 CLI 인증을 사용하며, 인증 실패·미설치·지원되지 않는 CLI는 실제 상태로 표시해야 한다.

#### Scenario: Missing CLI or authentication
- **WHEN** Claude가 설치되지 않았거나 선택한 CLI의 인증이 실패한다
- **THEN** 생성 성공을 표시하지 않으며 설치/외부 인증 안내와 재진단 경로를 제공한다

### Requirement: Context-bound definition generation
앱은 프로젝트 지침·QA 요청·전체 원본·선택 node/edge와 전체/선택/앞/뒤 범위를 SHALL 생성 요청에 포함한다. 앞/뒤는 그래프 연결 의미이며 부분 실행 의미가 아니다. 정의 생성은 QA 자동 실행이나 사용자 shell 문자열 실행 권한을 주지 않는다.

#### Scenario: Insert around a selected block
- **WHEN** 사용자가 선택 블록 앞 또는 뒤에 검사를 추가하도록 요청한다
- **THEN** 선택 ID와 연결 문맥을 전달하고 전체 후보 XML의 변경 노드·edge·참조를 검토하게 한다

#### Scenario: Generation is not execution
- **WHEN** AI 생성이 완료된다
- **THEN** Engine run을 호출하지 않고 후보 검증·변경 검토 상태로 전환한다

### Requirement: Bounded asynchronous generation
앱은 비동기 생성 진행·취소·timeout·프로세스 실패를 SHALL 구분하고 출력과 작업 시간을 제한해야 한다. 각 요청은 고유 세션 폴더를 사용하고 취소 후 늦은 출력이 적용 가능해져서는 안 된다.

#### Scenario: Cancellation and late output
- **WHEN** 사용자가 생성을 취소한 뒤 프로세스에서 추가 출력이 도착한다
- **THEN** 취소를 유지하고 후보 적용을 차단하며 프로세스 정리 결과를 표시한다

#### Scenario: Excess output or hanging process
- **WHEN** CLI가 출력 제한이나 실행 deadline을 초과한다
- **THEN** 유한 시간 안에 종료를 시도하고 실패 원인을 표시하며 원본 문서를 유지한다

### Requirement: Validate the entire candidate before approval
앱은 후보 전체를 고정된 공개 Engine으로 import/validate/plan하여 SHALL 검증하고 원본 대비 XML·노드·연결·target/selectors/variables 변경을 표시해야 한다. 형식 오류, 참조 오류 또는 범위 밖 변경은 숨기지 않는다.

#### Scenario: Invalid candidate
- **WHEN** AI가 잘못된 XML, 지원되지 않는 action 또는 깨진 edge를 반환한다
- **THEN** 검증 오류를 표시하고 원본 적용과 실행을 허용하지 않는다

#### Scenario: Valid candidate requires explicit approval
- **WHEN** 후보가 전체 검증을 통과한다
- **THEN** 미적용 상태의 변경 미리보기를 표시하며 사용자 적용 이후에도 자동 실행하지 않는다

### Requirement: Revision-safe apply and undo
앱은 project/QA ID, 문서 revision, 선택 revision, 프롬프트 revision, runtime 설정 revision과 요청 generation을 SHALL 비교하여 오래된 후보 적용을 거부해야 한다. 명시 적용 후 되돌리기는 직전 원문을 복원하며 외부 원본 파일을 자동 덮어쓰지 않는다.

#### Scenario: ABA edits or QA switch
- **WHEN** 요청 후 문서를 수정했다가 동일 텍스트로 되돌리거나 QA·선택·지침·runtime이 바뀐다
- **THEN** 이전 후보를 stale로 표시하고 적용하지 않는다

#### Scenario: Undo and export
- **WHEN** 사용자가 후보를 적용한 뒤 되돌린다
- **THEN** 적용 직전 원문이 복원되고 검증 상태는 무효화되며 외부 파일은 별도 저장 승인 전까지 그대로 남는다

#### Scenario: Manual edits after applying a proposal
- **WHEN** 후보 적용 후 수동 편집 또는 다른 후보 적용이 발생한 상태에서 이전 제안을 되돌리려 한다
- **THEN** 적용 직후 revision과 다름을 확인해 해당 undo를 거부하거나 명시적인 후속 변경 폐기 확인을 요구하며 조용히 덮어쓰지 않는다

### Requirement: Honest AI acceptance
실제 AI 응답 인수는 설치된 CLI의 실제 호출·정상 종료·후보 검증 증거로 SHALL 기록한다. fixture와 실제 모델 응답, QA 실행 진행과 AI 생성 진행, 이미지 표시와 AI 이미지 해석을 구분해야 한다.

#### Scenario: Real provider unavailable
- **WHEN** CLI fixture는 성공하지만 실제 인증 또는 모델 요청은 실패한다
- **THEN** UI/문서에 실제 연결 미인수를 남기며 fixture를 실제 AI 성공으로 보고하지 않는다
