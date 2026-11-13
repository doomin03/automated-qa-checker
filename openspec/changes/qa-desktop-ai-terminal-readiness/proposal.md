# Proposal

## Why

다중 PTY/작성 권한/공개 Engine 작성 통합은 완료했으나 Codex 인수는 업데이트 TUI 시작까지다. 이전 단일 터미널 change의 11개 미완료 항목에는 후속 구현으로 대체된 인수와 실제 AI 파일 작성·IME 검증 부족이 섞여 있다. 설치되지 않은 프로그램의 복구 경로도 실행 파일 문자열 입력만 제공한다. 최신 사용자 요청에 따라 재구현 없이 실제 사용의 남은 연결과 증거를 완성한다.

## What Changes

- 프로그램별 공식 설치 안내·기존 실행 파일 선택·재진단·로컬 경로 기억을 제공한다. 앱이 자동 설치/업데이트하거나 인증 정보를 저장하지 않는다.
- 세션 작성 환경의 버전/가이드 준비 상태와 실제 발견/활용 미확인을 구분하고, 고정 QA의 문맥·skill 호출 안내를 복사/미제출 입력으로 전달한다.
- 실제 interactive Codex의 XML/JSON 수정→공개 검증→GUI→사용자 명시 실행을 격리 QA로 인수한다. Claude는 설치/인증된 환경이 있을 때 별도 인수하며 unavailable을 성공으로 간주하지 않는다.
- 옛 terminal tasks를 후속 증거에 매핑하고 정확히 충족한 항목만 정합한다. 원래 실패·부분 인수 기록은 보존한다.

## Capabilities

### New Capabilities

- `desktop-ai-terminal-readiness`: CLI 준비 복구, 로컬 프로필, 세션 작성 안내와 실제 AI 편집 경로의 구분된 인수.

### Modified Capabilities

없음. 완료된 다중 터미널/목업의 의미와 Engine 계약을 바꾸지 않는다.

## Impact

Checker main `3e73cd1f14b0aab658748e9c9b5c1be4a87794ad` 및 기존 dirty를 보존한다. 변경 후보는 앱 interactive_terminal의 Model/Service/Repository, pool의 준비 상태 조합, terminal 추가/세션 메뉴, 관련 테스트·문서다. Engine·서버·SDK·목업·기존 Release는 수정하지 않는다. package 새 의존성 대신 기존 file selector/Provider를 사용한다.

counterpart: Engine 계약 변경 없음. contractVersion: 앱 alpha.9/execution `0.3.0-draft.2`/authoring `0.1.0-draft.1`; 기본 서버 alpha.6 유지. dependsOn: `qa-multi-terminal-workbench`, `qa-desktop-interactive-terminal`, `qa-desktop-planning-responsive`. 이 문서는 관리 검토용이며 제품 apply 승인 전이다. 운영 승격·원격 게시·범용 installer·개인 QA 배정/조직 CRUD/Recorder는 별도 의존 작업이다.
