## Purpose

프로젝트와 QA 편집 여정을 유지하면서 실제 여러 터미널을 하단 도크로 조작하고 창 크기와 글자 배율 변화에도 상태와 핵심 동작 접근을 보장한다.

## ADDED Requirements

### Requirement: Document centered dock
앱은 문서 아래 세션 추가/이름/전환/종료와 접기/확대/복원/두 세션 분할을 SHALL 제공하며 상단 문서와 홈 경로를 유지한다.

#### Scenario: Layout operations
- **WHEN** 양쪽 편집 패널과 터미널을 연 뒤 접기/확대/분할/창 크기 변경을 반복한다
- **THEN** 문서 원문/커서/선택/캔버스 transform과 세션별 출력·미제출 입력·scroll을 보존하고 PTY를 재생성하지 않는다

#### Scenario: Narrow split fallback
- **WHEN** 360px씩 두 pane을 확보할 수 없거나 편집기220px/터미널160px를 동시에 확보할 수 없다
- **THEN** 단일 세션 탭 또는 bounded 작업 패널을 제공하고 복귀 경로 및 이전 분할/높이 선호를 보존한다

### Requirement: Focus and accessible resize
앱은 키보드/포인터 리사이저와 명확한 focus를 SHALL 제공하며 터미널 입력을 canvas shortcut으로 전달하지 않는다.

#### Scenario: Keyboard resize and Escape
- **WHEN** separator에서 방향키/Home/End를 쓰거나 메뉴에서 Escape를 누른다
- **THEN** 가용 높이 내에서 조절하고 focus를 적절히 복귀시키며 세션 종료/인터럽트를 합성하지 않는다

#### Scenario: Terminal control keys
- **WHEN** 터미널에 포커스한 채 Delete/Ctrl+C와 한글 입력을 사용한다
- **THEN** 선택한 PTY만 해당 입력을 받고 canvas 노드나 다른 세션 입력을 변경하지 않는다

#### Scenario: Active view ownership
- **WHEN** inline/modal 또는 split/tab 표현을 바꾼다
- **THEN** 같은 session의 활성 TerminalView는 최대 하나이며 controller를 중복 dispose하지 않고 최초 PTY 크기도 실제 pane과 일치한다

### Requirement: Responsive native acceptance
앱은 실제 Windows viewport와 text scale을 기록하여 핵심 세션/편집 경로를 SHALL 검증한다.

#### Scenario: Small and scaled windows
- **WHEN** 1440×900/1024×768/800×600 및 낮은 높이1280×500, text1/1.25/1.5에서 긴 한글과 출력이 표시된다
- **THEN** 패널이 겹치거나 필수 액션이 접근 불가하지 않으며 숨긴 패널 대안/영역 스크롤을 제공하고 캡처와 실제 MediaQuery/창 geometry를 기록한다
