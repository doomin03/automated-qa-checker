# Proposal

## Why

사용자는 기존 목업과 Material 폼 중심 제품 UI를 거절하고 Photoshop 같은 문서 중심 데스크톱 구성과 Unreal Blueprint 같은 실제 조작을 요청했다. 또한 개별 실행 동작과 재사용 XML 파일을 구분하여 XML 하나를 하나의 블록으로 배치하고, Checker가 조합 결과를 공개 Engine XML로 전달하거나 XML 파일을 직접 실행하는 사용자 앱을 요구했다. 목업만 바꾸는 것으로 충족하지 않는다.

## What Changes

- 실제 Flutter를 메뉴·작업 툴바·문서 탭·tool rail·블록 palette·캔버스·inspector·문서 구조/이력·하단 터미널/결과로 재구성한다. 대시보드/hero/카드 랜딩을 기본 작업 화면으로 사용하지 않는다.
- 한 XML 파일을 재사용 블록으로 취급하는 Checker 작성 모델과 파일 보관·hash·출처·인스턴스를 구분한다. 개별 Engine action node 편집과 혼동하지 않는다.
- 작성 그래프를 기존 공개 Engine 계약으로 compile하고 최종 XML 미리보기/내보내기·검증·명시 실행을 연결한다. Engine DSL이나 실행 해석기를 Checker에 새로 만들지 않는다.
- XML 파일 직접 열기/검증/실행 경로를 유지한다. 기존 프로젝트/QA 저장, Codex PTY와 live 문서 동기화, 실제 실행 snapshot/증거를 보존하고 새 작업 공간에 배치한다.
- 실제 Windows 사용자 경로, 캔버스 조작, XML 입출력, Engine PASS/FAIL/취소와 증거를 검증하고 이전 Release를 보존한 별도 앱 산출물을 제공한다.

## Capabilities

### New Capabilities

- `desktop-document-studio`: 문서 중심 툴 UI와 도킹/키보드/작업 상태를 제공하는 실제 Desktop 작업 공간.
- `desktop-xml-block-authoring`: XML 파일 단위의 재사용 작성 블록, 조합·compile·출처와 직접 XML 경로.

### Modified Capabilities

없음. 정본 `openspec/specs`가 비어 있으며 이전 완료 change의 인수 이력을 덮어쓰지 않는다.

## Impact

- owner: Checker `apps/app` MVVM/Provider, 관련 테스트/문서/새 Release. 원본 목업 및 기존 사용자 수정은 보존한다.
- dependsOn: qa-desktop-ai-workspace, qa-desktop-interactive-terminal, qa-flow-editor, qa-user-web-desktop-handoff.
- counterpartRepoChange: Engine 공개 계약 감사 결과를 관리 검토 후 확정한다. Engine 변경이 필요하면 이 change의 compile apply를 선행하지 않는다.
- contractVersion: 현 Desktop `0.3.0-draft.2`, runtime `0.1.0-alpha.8`; 서버/Agent alpha.6와 HTTP 계약은 불변이다. 독립 Engine package/CLI를 그대로 소비한다.
- acceptanceCriteria: 실제 Flutter UI와 공개 Engine 검증·실행 증거가 필요하다. 로컬 HTML 목업·fixture·문서만으로 완료 처리하지 않는다.
- 현재 단계: 조사와 OpenSpec 준비. XML 조합 의미 및 관리 검토 이후 apply한다. 원격 commit/push, 기존 Release 덮어쓰기, 사용자 workspace 데이터 마이그레이션 강행은 하지 않는다.
