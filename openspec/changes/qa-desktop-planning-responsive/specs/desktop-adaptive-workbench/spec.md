# Spec Delta

## Purpose

Desktop의 홈부터 문서 편집과 실행 결과까지 창 크기와 사용자 글자 배율에 맞게 사용할 수 있게 한다. 좁은 화면에서도 원문·프로세스·실행 상태를 보존하며 숨겨진 도구와 긴 내용을 다시 확인할 수 있게 한다.

## ADDED Requirements

### Requirement: Viewport and text scaling preserve usable controls
앱은 SHALL 800×600, 1024×768, 1440×900 및 1280×500 logical viewport와 text scale 1, 1.25, 1.5에서 화면 밖으로 사라진 필수 액션이나 겹쳐 눌리지 않는 컨트롤 없이 D01–D08 작업을 제공한다. 사용자 글자 배율을 강제로 낮춰 맞추지 않는다.

#### Scenario: Small window with large Korean content
- **WHEN** 800×600, text scale 1.5에서 긴 한국어 프로젝트/QA 이름, 다중 행 오류, 긴 경로를 표시한다
- **THEN** 목록 선택·열기·뒤로가기·저장·검증·실행 취소에 접근할 수 있으며 전체 이름과 오류 원문은 상세/스크롤로 확인할 수 있다
- **AND** layout exception, 패널 겹침, 음수 크기 또는 잘린 대화상자 액션이 발생하지 않는다

### Requirement: Collapsed panels remain accessible
앱은 SHALL 가용 폭에 따라 접는 탐색·라이브러리·속성·AI·결과 패널에 명시적 열기/닫기 경로를 제공한다. 닫거나 창 크기를 바꾸는 동작은 문서 정본·선택·실행·터미널 세션을 초기화하지 않는다.

#### Scenario: Inspector below inline threshold
- **WHEN** XML 블록을 선택한 뒤 속성을 옆에 둘 폭이 부족한 창에서 속성을 연다
- **THEN** 선택 블록의 속성을 대체 패널에서 조회/편집하고 닫을 수 있으며 중앙 캔버스로 돌아간다
- **AND** 다시 큰 창으로 변경해도 같은 문서와 블록 선택이 유지된다

### Requirement: Docks share a bounded workspace
앱은 SHALL 터미널과 결과가 동시에 열려도 남은 편집 영역 크기를 기준으로 도킹 높이를 제한한다. 낮은 높이에서는 패널 전환/접기를 제공하고 모든 패널을 무제한 세로로 쌓지 않는다.

#### Scenario: Resize with live terminal and run results
- **WHEN** 터미널과 결과를 연 상태에서 창을 1280×500 또는 800×600으로 줄인다
- **THEN** 캔버스나 직접 문서를 계속 열 수 있고, 터미널 입력/종료와 결과/취소 액션을 전환하여 사용할 수 있다
- **AND** 세션 PID, 실행 identity, 원문 및 미저장 편집이 크기 변경만으로 바뀌지 않는다

### Requirement: Scroll and keyboard focus follow their regions
앱은 SHALL 긴 목록·속성·로그·결과·대화상자 내용에 독립적인 스크롤을 제공하며 키보드로 이동한 입력과 필수 액션을 보이게 한다. 터미널의 키 입력은 캔버스 단축키로 전파하지 않는다.

#### Scenario: Long dialog and terminal focus
- **WHEN** 확대 글자 상태에서 연결/실행 설정 대화상자 끝 필드까지 Tab으로 이동하고 닫은 뒤 터미널에 Delete와 Ctrl+C를 입력한다
- **THEN** 해당 필드 및 대화상자 액션에 접근 가능하고, 터미널 입력이 블록 삭제나 앱 실행 취소로 오인되지 않는다

### Requirement: Graph and evidence remain inspectable
앱은 SHALL XML 파일 블록 캔버스의 pan/zoom/fit, 선택과 핀 연결 및 증거 이미지의 종횡비를 유지한다. 작은 창에서도 현재 선택과 실행 snapshot의 출처를 확인할 수 있어야 한다.

#### Scenario: Canvas and screenshot at compact width
- **WHEN** 작은 창에서 블록을 선택하고 전체 보기를 누른 후 실행 PNG 및 실패 원인을 연다
- **THEN** 블록/연결이 캔버스 안에서 탐색 가능하고 PNG와 진단을 스크롤해 확인할 수 있다
- **AND** 수정 중인 문서에 이전 실행 snapshot의 성공/실패를 잘못 부착하지 않는다
