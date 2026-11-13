# Proposal

## Why

프로젝트 상세에서 Blueprint/XML 편집과 여러 작성·검토 터미널을 함께 사용하는 사용자 흐름이 필요하다. 현재 통합 목업 D08은 편집기를 덮는 설명 패널이며 실제 앱은 Codex 전용 단일 터미널 기반이다. 새 사용자 요청은 VS Code식 하단 다중 터미널의 기획·화면 목업이며 제품 구현 요청으로 확대하지 않는다.

## What Changes

- 기존 홈·받은 QA·25개 화면 연결을 유지하고 D05/D06 편집 영역 아래 D08 터미널 도크를 실제 조작 가능한 로컬 예시로 연결한다.
- Claude Code/Codex/PowerShell/명령 프롬프트의 준비 상태, 추가·전환·이름·분할·종료, 도크 접기·확대·크기 조절을 설계한다.
- QA별 단일 자동 반영 writer, 세션 소속과 격리 사본, 검증·충돌·저장·실행 경계와 포커스 보존을 명세화한다.
- Engine/웹 기획 담당의 반례와 합의를 기록하고 기능·키보드·1440/1024 시각 검증을 수행한다.

## Capabilities

### New Capabilities

- `multi-terminal-planning`: 프로젝트 문서 편집과 다중 터미널의 상태·레이아웃·작성 안전 경계를 검토하는 목업.

### Modified Capabilities

없음. 기존 제품 실행·HTTP·Engine 계약은 변경하지 않는다.

## Impact

Checker main `3e73cd1f14b0aab658748e9c9b5c1be4a87794ad`의 기존 dirty를 보존한다. 소유 범위는 `design/mockups/xml-block-studio`, `design/mockups/product-planning`, 관련 안내/검증 문서와 이 change다. 기존 stylesheet 전체 교체 대신 전용 도크 JS/CSS 모듈을 추가한다. Flutter/Server/Engine 제품, pin, Release, 자격증명, 실제 셸 실행은 제외한다.

counterpartRepoChange: Engine 읽기 전용 계약 감사, 웹 기획 독립 UX 검토(제품 변경 없음). contractVersion: 기존 Desktop alpha.8/0.3.0-draft.2, Server/Agent alpha.6 유지. dependsOn: qa-integrated-product-planning, qa-desktop-project-received-home, qa-desktop-xml-block-studio, qa-desktop-interactive-terminal. 관리 기준: `C:/workspace/QA/coordination/multi-terminal-planning-20261112/management-brief.md`.

OpenSpec strict와 관리 검토 후 목업에 apply했다. 전용 43검사, 기존 홈14/편집기16/portal94 회귀, 독립 웹46+5/Engine12경로, 관리 8캡처/25화면·저장 격리·제품 파일 보존을 확인했다. 저장소 verify exit0 및 최종 strict/이번 목업·기획·OpenSpec 범위의 diff PASS를 기록했다. 전체 dirty tree의 기존 생성 API trailing whitespace는 별도 제한이며 제품 파일은 보존했다. 실제 다중 CLI/PTY/Claude 제품 인수는 이번 범위가 아니다.
