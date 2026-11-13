# Proposal

## Why

D08의 다중 터미널 목업은 검토를 완료했으나 착수 당시 실제 앱은 Codex 전용 단일 PTY와 파일 감시 상태를 공유했다. 사용자 요청에 따라 여러 작성·검토 세션을 실제 앱으로 연결하고, 재사용 가능한 템플릿·블록 합성 의미를 공개 Engine 작성 계약으로 이관한다.

## What Changes

- Codex·Claude·Windows PowerShell·cmd의 준비 상태와 실제 세션 추가/이름/전환/종료, 독립 출력·입력·스크롤을 제공한다.
- 세션의 project/QA/시작 cwd를 고정하고 사본을 분리한다. QA별 단일 자동 반영 writer와 epoch, 정리 미확인 차단, 검증 후보의 마지막 적용 검사를 도입한다.
- 하단 도크의 접기·확대·키보드/포인터 크기 조절·두 세션 분할과 작은 창 대안을 구현한다. 편집기와 세션 수명을 화면 배치에서 분리한다.
- 검증된 새 Engine의 template/compose 공개 계약을 Service/Repository로 소비한다. 기존 Dart 합성 의미의 동등성을 확인한 뒤 새 경로에서 대체하며 무음 fallback은 하지 않는다.
- 실제 Windows PTY·파일 동기화·공개 Engine 실행·반응형 인수와 별도 Release를 기록한다. Claude 미설치와 실제 모델 미검증을 명확히 구분한다.

## Capabilities

### New Capabilities

- `desktop-terminal-sessions`: 실제 다중 provider PTY, 고정 소속, 수명과 준비 상태.
- `desktop-terminal-writer`: QA별 writer epoch와 파일 후보 검증·충돌·자동 반영 경계.
- `desktop-terminal-dock`: 편집 상태를 보존하는 다중 도크와 접근성.
- `desktop-engine-authoring-consumer`: 공개 템플릿·블록 합성의 앱 소비와 기존 자료 보존.

### Modified Capabilities

없음. 기존 완료된 목업 change는 역사 기록으로 보존한다.

## Impact

Checker main `3e73cd1f14b0aab658748e9c9b5c1be4a87794ad`의 이전 dirty를 보존한다. 주요 변경은 `apps/app`의 interactive_terminal, xml_blocks, app/workbench와 composition root, 관련 테스트/문서/새 Release 도구다. 서버·HTTP SDK·목업·기존 Release를 변경하지 않는다. MVVM+Provider와 검증된 flutter_pty2 vendor/xterm2를 유지한다.

counterpartRepoChange: Engine `qa-reusable-document-authoring`. contractVersion: 새 Desktop runtime alpha.9/execution 0.3.0-draft.2/authoring 0.1.0-draft.1을 관리 version/hash 승인 후 앱 전용으로 소비했다. 고정 hash와 근거는 design D5에 기록한다. 이전 alpha.8 설치/Release와 기본 서버/Agent alpha.6은 보존한다. dependsOn: qa-multi-terminal-planning, qa-desktop-interactive-terminal, qa-desktop-xml-block-studio, qa-desktop-planning-responsive. 루트의 2026-11-12 책임 재분배·다중 터미널 기획 보고서를 기준으로 한다. 새로운 실행 DSL, 전역 CLI 설정 변경, 자격증명 저장, 자동 QA 실행, 원격 게시를 포함하지 않는다.
