## Purpose

여러 터미널에서 편집하는 파일이 서로 다른 QA나 최신 편집본을 덮지 않도록 문서별 자동 반영 권한과 검증 후보의 생명주기를 규정한다.

## ADDED Requirements

### Requirement: Single writer with epoch
앱은 QA별 최대 한 writer와 증가하는 writerEpoch를 SHALL 소유하며 해제/양도/삭제/정리 미확인 전 후보의 적용 자격을 폐기한다.

#### Scenario: Writer ABA
- **WHEN** A의 후보 검증 중 writer를 A→B→A로 바꾸거나 해제 후 A를 다시 지정한다
- **THEN** 이전 A 후보는 거절되고 새 epoch와 현재 원문 기준으로 다시 검증해야 한다

#### Scenario: Live role transfer
- **WHEN** 정상 실행 중인 작성자 A에서 검토 세션 B로 사용자가 권한을 양도한다
- **THEN** A의 PTY는 유지하고 이전 후보를 폐기하며 B의 기존 파일 변경은 사본/충돌로 보존한 뒤 현재 기준으로 재검증한다
- **AND** A가 closing 또는 cleanup_unknown이면 양도하지 않는다

#### Scenario: Unknown cleanup
- **WHEN** writer close가 정리 미확인이다
- **THEN** 기존 파일의 자동 적용과 새 writer 지정을 모두 차단하고 늦은 close도 임의로 barrier를 해제하지 않는다

### Requirement: Immutable candidate commit guard
앱은 immutable XML/JSON snapshot의 공개 Engine 검증 결과를 session/QA/activation/epoch/document/Flow/settings/pin/file hash와 결합하고 마지막 await 후 다시 확인하여 SHALL 적용한다.

#### Scenario: Late final read
- **WHEN** 최종 파일 재읽기 중 QA A→B→A 이동, GUI/Flow 편집 또는 writer 변경이 발생한다
- **THEN** 검증 성공 후보도 적용하지 않고 현재 문서와 마지막 정상 그래프를 유지한다

#### Scenario: Selection only
- **WHEN** 동일 문서에서 선택 노드 또는 화면 좌표만 바뀐다
- **THEN** 실행 의미 revision을 변경하지 않고 유효 후보를 선택 변경만으로 무효화하지 않는다

#### Scenario: Concurrent formats and invalid writes
- **WHEN** XML/JSON 모두 바뀌거나 파일이 부분쓰기/삭제/잠금/형식오류 상태이다
- **THEN** 마지막 정상 그래프를 유지하고 충돌/진단을 표시하며 실행 또는 저장을 자동 수행하지 않는다

### Requirement: Conflict preservation and blocker aggregation
앱은 GUI/외부 파일 사본을 보존하고 현재 QA의 개별 blocker를 집계하여 SHALL 관리하며 다른 기능의 차단을 덮어쓰지 않는다.

#### Scenario: Conflict changes while copied
- **WHEN** 사용자가 외부 파일 적용을 선택한 뒤 사본 저장 중 새 GUI/Flow 편집이 발생한다
- **THEN** 적용을 거절하고 새 편집을 보존한다

#### Scenario: QA run in progress
- **WHEN** QA 실행 중 writer 파일이 바뀐다
- **THEN** 실행 snapshot/진행/결과를 유지하고 실행 종료 후 현재 기준 재검증 대상으로 남긴다

#### Scenario: Independent blockers
- **WHEN** XML block 오류가 있는 상태에서 terminal 상태가 정상으로 바뀐다
- **THEN** XML block의 실행 차단은 유지되고 관련 없는 QA의 검토 세션 상태는 현재 QA를 차단하지 않는다

#### Scenario: Applied draft and undo
- **WHEN** 검증된 writer 후보가 draft에 적용되고 이후 사용자가 다시 편집한다
- **THEN** 자동 저장/run은 없으며 이전 후보 undo로 후속 편집을 무단 덮지 않는다

#### Scenario: Composition preview remains derived
- **WHEN** XML 파일 블록 합성 모드에서 writer 파일이 수정된다
- **THEN** 후보 검증과 검토는 가능하지만 합성 원문/그래프/sourceMap은 덮지 않고 기존 명시적 직접 문서 전환 경로를 안내한다
- **AND** 직접 문서 모드 전환 후 현재 QA/원문/작성권한을 재검증해야 적용하며 검증 중 mode 전환 후 원복도 이전 후보를 무효화한다
