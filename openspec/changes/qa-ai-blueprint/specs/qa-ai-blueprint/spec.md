# AI Blueprint

## ADDED Requirements

### Requirement: Provider neutral authoring
플랫폼은 engine CLI의 schema/template/import/validate/plan으로 생성된 선언형 QA 문서를 공급자에 종속되지 않고 SHALL 수용한다.

#### Scenario: Import generated XML
- **WHEN** engine CLI에서 XML을 JSON으로 변환한 blueprint를 GUI에 import한다
- **THEN** JSON 정본을 스키마 검증하고 그래프를 표시하며 실행은 시작하지 않는다.

#### Scenario: Reject executable or external entities
- **WHEN** Flow에 임의 shell action 또는 문서에 engine가 지원하지 않는 필드가 있다
- **THEN** 입력 오류로 거부하고 파일/프로세스 실행을 하지 않는다.

### Requirement: Blueprint progress and explicit execution
GUI는 가져온 정의와 event의 run/attempt/node identity를 검증하고 대기/실행/성공/실패/미실행 상태를 구분해 SHALL 표시한다.

#### Scenario: Review before execution
- **WHEN** 사용자가 AI가 만든 Flow를 가져온다
- **THEN** 검증 결과와 실행 단계를 표시하고 가져오기만으로 실행하지 않는다.

#### Scenario: Replay branch execution
- **WHEN** 한 분기만 실행한 event stream을 불러온다
- **THEN** 방문하지 않은 노드를 성공으로 표시하지 않으며 실패 node/진행을 확인할 수 있다.

