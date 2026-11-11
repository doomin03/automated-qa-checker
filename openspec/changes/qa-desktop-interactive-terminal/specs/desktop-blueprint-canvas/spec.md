# Spec Delta

## Purpose

QA 상세를 실제 노드와 포트 및 연결선을 조작하는 데스크톱 Blueprint 작업 공간으로 제공하고, 문서 편집과 실행 snapshot의 진행 상태를 시각적으로 구별한다.

## ADDED Requirements

### Requirement: Canvas is the primary QA workspace
QA 상세는 컴팩트 툴바, 어두운 격자 캔버스, 선택 블록 속성과 하단 terminal dock을 중심으로 구성해야 한다(SHALL). XML/JSON과 큰 입력 폼은 보조 영역으로 제공하고 viewport 내 작업 영역이 겹치지 않아야 한다(MUST).

#### Scenario: Desktop sizes and docking
- **WHEN** 1440×900 또는 1024×768 창에서 terminal을 접거나 열고 크기를 변경한다
- **THEN** 캔버스와 속성/terminal이 겹치지 않으며 내부 스크롤/접기로 모든 주요 조작에 접근할 수 있다.

### Requirement: Nodes support direct manipulation
사용자는 pan/zoom/fit과 노드 드래그·선택으로 그래프를 조작할 수 있어야 한다(SHALL). 레이아웃 이동은 실행 의미 변경으로 취급하지 않고 앱 presentation 상태로 보존해야 한다(MUST).

#### Scenario: Drag at nondefault zoom
- **WHEN** 사용자가 줌과 pan 이후 노드를 드래그하고 QA를 다시 연다
- **THEN** 좌표 변환에 맞게 이동한 위치가 복원되며 XML/JSON 및 실행 snapshot hash는 좌표 이동만으로 변경되지 않는다.

#### Scenario: Fit a large graph
- **WHEN** 1000개 노드를 가진 문서를 열어 fit과 선택을 수행한다
- **THEN** 끝 노드와 연결선까지 접근 가능하고 원문이 보존되며 build/선택/이동의 실제 측정값을 검증 기록에 남긴다.

### Requirement: Ports represent valid graph connections
노드는 입력/출력 핀과 곡선 edge를 제공하고 branch는 true/false 출력을 구별해야 한다(SHALL). start/end 방향 제약과 중복/끊긴 연결의 편집 불변식을 지키며 최종 실행 가능 여부는 공개 Engine compile으로 판정해야 한다(MUST).

#### Scenario: Connect branch output
- **WHEN** 사용자가 branch의 true 또는 false 핀에서 대상 입력 핀으로 드래그한다
- **THEN** 지정 라벨의 연결이 갱신되고 동시에 노드 이동이 발생하지 않으며 start 입력/end 출력 같은 잘못된 방향은 거절된다.

#### Scenario: Select and edit properties
- **WHEN** 사용자가 블록을 선택하여 selector/value/timeout 등 지원 속성을 수정한다
- **THEN** 우측 기본 폼에서 편집할 수 있고 변경을 compile해야 실행 가능하며 JSON 입력은 필수 기본 경로가 아니다.

### Requirement: Input focus prevents cross-panel commands
키보드 동작은 현재 focus가 있는 편집기/terminal/canvas에만 적용되어야 한다(SHALL). terminal 입력이 그래프 삭제·복사·실행 단축키를 동시에 유발해서는 안 된다(MUST).

#### Scenario: Terminal owns Delete and interrupt
- **WHEN** terminal에 focus가 있는 상태에서 Delete 또는 Ctrl+C를 누른다
- **THEN** 입력은 terminal로만 전달되고 선택 노드 삭제나 canvas 변경이 발생하지 않는다.

### Requirement: Execution status belongs to its snapshot
캔버스의 실행중/성공/실패/미방문 상태는 run identity와 실행 snapshot에 결합되어야 한다(SHALL). 편집된 최신 draft에 이전 실행 결과를 붙여서는 안 된다(MUST).

#### Scenario: Draft differs from completed execution
- **WHEN** 완료된 실행 이후 원문/연결을 수정한다
- **THEN** 현재 draft와 실행 snapshot 보기를 구별하고 과거 상태/PNG를 원 QA/run에 귀속하여 표시한다.
