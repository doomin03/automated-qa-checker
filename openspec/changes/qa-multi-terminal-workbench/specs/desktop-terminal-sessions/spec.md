## Purpose

사용자가 여러 AI CLI와 일반 셸을 독립된 QA 작업 사본에서 사용하도록 실제 PTY의 소속, 준비 상태, 출력과 종료 수명을 분리한다.

## ADDED Requirements

### Requirement: Independent native sessions
앱은 각 세션의 PTY/출력 버퍼/입력/감시기/후보와 immutable project/QA/시작 cwd를 분리하여 SHALL 관리한다.

#### Scenario: Concurrent sessions
- **WHEN** 같은 provider를 포함한 두 세션을 열고 서로 다른 출력과 파일 변경을 발생시킨다
- **THEN** 각 세션의 출력·입력·후보는 독립이며 한쪽 종료가 다른 세션을 종료하거나 drain을 멈추지 않는다

#### Scenario: Navigate away
- **WHEN** 다른 QA 또는 홈으로 이동한 뒤 돌아온다
- **THEN** 기존 세션의 소속/시작 경로/PID는 유지되고 새 QA에 기존 파일을 자동 적용하지 않는다

#### Scenario: Session limit
- **WHEN** 8개 보관 세션 상태에서 추가한다
- **THEN** 상한을 안내하고 기존 세션을 자동 삭제/종료하지 않는다

### Requirement: Honest provider readiness
앱은 Codex/Claude/Windows PowerShell/cmd별 executable과 지원 인자를 확인하며 설치·로그인·실행·모델 성공을 구분하여 SHALL 표시한다.

#### Scenario: Provider unavailable
- **WHEN** Claude 또는 선택 executable이 없거나 필수 옵션을 지원하지 않는다
- **THEN** 실행하지 않고 설정 필요/지원 오류를 표시하며 다른 provider는 계속 사용 가능하다

#### Scenario: Explicit launch
- **WHEN** 사용자가 준비된 provider를 선택해 시작한다
- **THEN** 고유 session cwd와 인자 배열로 실행하고 AI 신뢰/로그인 화면은 실제 터미널에 표시하며 일반 셸에 AI 준비 배지를 붙이지 않는다

### Requirement: Owned cleanup
앱은 선택 세션의 Job close와 cleanup_unknown latch를 소유하며 화면 숨김과 종료를 분리하여 SHALL 처리한다.

#### Scenario: Close races with spawn
- **WHEN** 준비/spawn 중 종료하거나 부모가 자식보다 먼저 종료한다
- **THEN** 해당 세션만 bounded close하고 종료 또는 정리 미확인을 표시하며 늦은 callback이 상태를 성공으로 덮지 않는다

#### Scenario: Pool disposal
- **WHEN** 앱 종료를 확정하거나 Provider scope를 제거한다
- **THEN** 모든 소유 세션 정리를 요청하고 이중 dispose 없이 watcher/callback을 해제하며 외부 주입 의존은 소유 계약을 따른다

#### Scenario: Hidden session output
- **WHEN** 세션 탭/도크가 숨겨진 상태에서 출력이 계속된다
- **THEN** bounded buffer로 drain하며 포커스 이동이나 세션 재시작을 발생시키지 않는다

### Requirement: Versioned authoring environment
앱은 프로젝트/수신 QA의 고정 Engine 계약과 필요한 작성 환경 버전을 식별하고 세션 사본에 공개 contract/examples 및 provider별 명시 작성 가이드를 SHALL 준비하며 전역 설정과 자격증명을 보존한다.

#### Scenario: Prepare an AI session
- **WHEN** Codex 또는 Claude 세션 사본을 준비한다
- **THEN** 해당 사본의 .agents/skills 또는 .claude/skills에 QA 작성 가이드를 생성하고 계약/예제 hash와 가이드 버전을 기록하며 준비됨과 CLI의 실제 탐지·활용은 구분한다

#### Scenario: Shell and existing settings
- **WHEN** 일반 셸을 시작하거나 사용자 기존 CLI 설정이 존재한다
- **THEN** 일반 셸의 AI skill 활성은 주장하지 않고 전역 설정/credential을 변경하거나 작업 사본으로 복사하지 않는다
