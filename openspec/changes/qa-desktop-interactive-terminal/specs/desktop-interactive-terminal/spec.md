# Spec Delta

## Purpose

설치된 AI CLI를 실제 Windows 터미널에서 사용하여 QA 전용 파일을 수정하고, 입력과 승인 프롬프트 및 소유 프로세스 수명을 앱에서 명확하게 관리한다.

## ADDED Requirements

### Requirement: Explicit interactive CLI session
앱은 사용자가 선택한 QA 전용 작업 폴더에서 명시적 시작으로 실제 interactive CLI 세션을 제공해야 한다(SHALL). 로그인/신뢰/권한 프롬프트를 유지하고 다른 세션이나 전역 설정을 변경하지 않아야 한다(MUST).

#### Scenario: Installed Codex starts interactively
- **WHEN** 사용자가 설치된 Codex로 터미널 시작을 누른다
- **THEN** QA에 고정된 PTY에서 CLI TUI와 입력/승인 프롬프트가 표시되고 자동 QA 실행이나 별도 API 키 등록을 요구하지 않는다.

#### Scenario: Unsupported installation
- **WHEN** 실행 파일이 없거나 필수 옵션이 지원되지 않는다
- **THEN** 명시적 진단으로 중단하며 성공 세션 또는 미설치 Claude 지원 완료를 표시하지 않는다.

### Requirement: Terminal input and display fidelity
터미널은 한글 조합 입력, UTF8 출력, 커서 키, 명시적 붙여넣기와 화면 크기 변경을 지원해야 한다(SHALL). 출력의 코드/URL/제어열을 앱의 임의 명령·파일 전송·클립보드 변경으로 실행하지 않아야 한다(MUST).

#### Scenario: Korean path and interaction
- **WHEN** 한글과 공백을 포함한 QA 폴더에서 사용자가 한글 IME와 커서 키를 입력하고 창을 조절한다
- **THEN** 인수와 경로가 보존되고 조합 문자가 중복 제출되지 않으며 실제 PTY 행/열 크기가 갱신된다.

#### Scenario: Output while collapsed
- **WHEN** terminal dock이 접힌 동안 CLI가 대량 출력을 생성한다
- **THEN** 출력은 계속 drain되고 메모리는 유한하며 다시 열 때 앱 입력과 현재 세션이 정상 동작한다.

### Requirement: Owned shutdown is observable
앱은 입력 중단 요청과 세션 종료를 구분해야 한다(SHALL). 시작 중 취소, root 종료 후 자식 잔존 및 출력 EOF 지연에도 owned 리소스 정리를 시도하고 정리 미확증을 성공으로 표시하지 않아야 한다(MUST).

#### Scenario: Interrupt versus close
- **WHEN** 사용자가 Ctrl+C를 입력하거나 종료 버튼을 누른다
- **THEN** Ctrl+C는 CLI 입력으로 전달되고 종료는 별도의 소유 세션 정리 경로를 사용하며 다른 사용자 CLI를 종료하지 않는다.

#### Scenario: Child and pipe outlive root
- **WHEN** root가 먼저 종료하고 자식 또는 출력 파이프가 남는다
- **THEN** 유한 정리 예산 내 결과를 확인하고 미확증이면 cleanup_unknown과 후속 시작 차단을 표시한다.

#### Scenario: Cancel during spawn
- **WHEN** 시작 준비 중 취소 또는 Provider scope 종료가 발생한다
- **THEN** 늦은 spawn/응답이 새 활성 세션으로 표시되지 않고 생성된 owned 리소스는 정리된다.

### Requirement: Session identity and context
터미널 세션은 프로젝트/QA identity에 고정되어야 한다(SHALL). 선택 블록 문맥은 명시적 파일 또는 입력 액션으로 제공하고 QA 전환이 기존 CLI의 작업 대상을 조용히 바꾸지 않아야 한다(MUST).

#### Scenario: QA changes with live CLI
- **WHEN** 사용자가 활성 터미널이 있는 QA에서 다른 QA를 연다
- **THEN** 기존 세션의 종료 또는 기존 QA 유지 선택을 요구하고 출력/파일 변경을 새 QA에 반영하지 않는다.

#### Scenario: Selected node context
- **WHEN** 사용자가 선택 블록 문맥 전달을 요청한다
- **THEN** node ID와 인접 edge 및 요청 범위가 QA 문맥에 포함되며 명령/QA 실행을 자동 제출하지 않는다.
