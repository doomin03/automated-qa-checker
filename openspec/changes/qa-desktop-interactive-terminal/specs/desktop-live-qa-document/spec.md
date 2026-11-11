# Spec Delta

## Purpose

터미널에서 편집한 XML 또는 JSON 파일을 공개 Engine의 검증된 Blueprint 투영과 연결하여, 사용자가 원문을 직접 해석하지 않아도 최신 유효 QA 흐름을 안전하게 확인하도록 한다.

## ADDED Requirements

### Requirement: Valid external edits update the GUI automatically
앱은 안정적으로 읽은 외부 QA 파일을 불변 snapshot으로 공개 Engine compile한 뒤, 문서/세션/파일이 동일하고 GUI 충돌이 없으면 자동 반영해야 한다(SHALL). 동기화는 QA 실행과 workspace 저장을 자동 수행하지 않아야 한다(MUST).

#### Scenario: XML edited in terminal
- **WHEN** terminal이 scenario.xml을 유효하게 수정하고 GUI에는 동시 편집이 없다
- **THEN** 전체 compile 후 그래프와 원문이 자동 갱신되고 저장 필요 상태가 표시되며 별도 후보 승인이나 자동 실행은 발생하지 않는다.

#### Scenario: JSON edited in terminal
- **WHEN** 활성 형식이 JSON인 scenario.json의 유효한 변경을 읽는다
- **THEN** JSON 확장자를 유지한 snapshot으로 compile하여 동일한 Blueprint GUI를 갱신한다.

### Requirement: Invalid files preserve the last valid graph
부분 쓰기, 문법 오류, 삭제, 잠금, 크기/경로 제한 위반은 이전 유효 원문/그래프를 보존하고 최신 파일 오류를 표시해야 한다(SHALL). 이전 그래프를 현재 파일의 정상 상태로 오인하여 실행하도록 해서는 안 된다(MUST).

#### Scenario: Partial write and recovery
- **WHEN** 유효 XML이 부분 쓰기로 깨졌다가 이후 유효한 전체 내용으로 저장된다
- **THEN** 오류 중 마지막 그래프를 유지하며 실행을 막고, 후속 유효 compile 후 자동으로 회복한다.

#### Scenario: File replacement or path escape
- **WHEN** 파일이 atomic rename으로 교체되거나 symlink/다른 폴더 참조로 바뀐다
- **THEN** 교체된 regular 파일은 다시 검증하고 허용 세션 밖 입력은 거절하며 원문을 잃지 않는다.

### Requirement: Conflicting writers require explicit resolution
GUI dirty와 외부 변경 또는 XML/JSON 양쪽 변경이 겹치면 앱은 base/GUI/file 내용을 보존하고 명시적 해결을 요구해야 한다(SHALL). mtime 우선이나 마지막 응답으로 한쪽 편집을 덮어쓰지 않아야 한다(MUST).

#### Scenario: GUI and file changed together
- **WHEN** 사용자가 블록 속성을 수정한 상태에서 terminal이 같은 QA 파일을 수정한다
- **THEN** 자동 반영이 중단되고 GUI 유지·파일 수용·사본 보존 선택이 제공되며 취소하면 양쪽 내용을 유지한다.

#### Scenario: Both formats changed
- **WHEN** scenario.xml과 scenario.json이 같은 동기화 기준 이후 각각 변경된다
- **THEN** 형식 우선순위를 추정하지 않고 충돌로 표시한다.

### Requirement: Stale work cannot overwrite current state
앱은 compile 완료 및 파일 교체 전에 QA/session identity, 문서 revision과 bytes hash를 확인해야 한다(SHALL). undo는 후속 편집을 무단 덮어쓰지 않아야 한다(MUST).

#### Scenario: Late compile after ABA edit
- **WHEN** compile 중 문서를 수정했다가 같은 문자열로 되돌리거나 QA를 전환한다
- **THEN** 이전 요청 결과는 늦은 결과로 거절되어 현재 정본을 변경하지 않는다.

#### Scenario: Undo after later edit
- **WHEN** 자동 반영 이후 사용자가 추가 편집하고 이전 반영의 undo를 요청한다
- **THEN** 후속 편집을 덮지 않고 충돌/별도 복원 선택을 제공한다.

### Requirement: Source preservation and explicit snapshot execution
GUI는 전체 원문을 보존하고 지원하지 않는 편집 구역을 묵시적으로 삭제하지 않아야 한다(MUST). 실행은 사용자가 명시한 불변 검증 snapshot을 사용하고 실행 중 외부 변경은 대기 상태로 분리해야 한다(SHALL).

#### Scenario: External file changes during a run
- **WHEN** 실행 중 terminal이 파일을 수정한다
- **THEN** 실행 그래프/PNG의 원 QA와 snapshot 소속을 유지하고 변경 대기를 표시하며, 종료 후에도 revision 검사를 통과한 변경만 반영한다.

#### Scenario: Unknown but valid document content
- **WHEN** Engine이 수용하지만 GUI가 편집을 지원하지 않는 내용이 문서에 있다
- **THEN** 원문과 해당 내용을 보존하고 제한을 표시하며 GUI 투영에서 빠졌다는 이유로 저장 시 삭제하지 않는다.
