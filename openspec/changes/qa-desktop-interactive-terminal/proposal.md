# Proposal

## Why

현재 Desktop의 AI는 `codex exec`로 후보 XML을 생성하는 폼이다. 사용자는 설치된 AI CLI의 실제 터미널에서 QA 파일을 수정하고, XML/JSON을 직접 읽지 않아도 Unreal Blueprint처럼 조작 가능한 그래프로 즉시 확인하기를 요청했다. 현재 Flow는 단순 노드/연결 표시이며 기본 화면도 XML이므로 탭 기본값 변경만으로 요구를 충족하지 못한다.

## What Changes

- QA 상세 기본 화면을 넓은 어두운 격자 Blueprint 캔버스로 구성한다. 노드 이동, 입력/출력 핀 연결, 곡선 edge, 분기 라벨, pan/zoom/fit, 선택 속성과 실행 상태를 제공한다. XML/JSON과 기능 팔레트는 보조 탭/접는 영역이다.
- 하단 접기/크기 조절 가능한 실제 PTY 터미널에서 사용자가 설치 Codex를 시작한다. CLI 입력·출력·로그인/승인 프롬프트를 그대로 제공하며 별도 API 키나 채팅 엔진을 만들지 않는다.
- 전용 QA 세션의 `scenario.xml` 또는 `scenario.json`이 변경되면 불변 snapshot을 공개 Engine으로 compile하고, 유효하고 충돌이 없으면 GUI 문서/그래프에 자동 반영한다. 매번 후보 승인 폼을 거치는 것을 기본 경로로 삼지 않는다.
- 부분 쓰기/삭제/잠금/문법 오류는 마지막 유효 그래프를 보존한다. GUI 미반영 편집과 외부 편집, 양쪽 형식 동시 수정은 명시적 충돌 해결로 보호한다. 파일 변화가 QA 실행을 시작하지 않는다.
- 터미널 프로세스·출력·watcher·compile 요청을 Provider 수명과 QA/session/revision에 묶고, 종료 미확증을 성공으로 표시하지 않는다.
- 기존 `desktop-ai-alpha8` Release와 목업/고정 Engine 패키지를 보존하고 후속 구현 인수 후 별도 `desktop-terminal-blueprint-alpha8` Release를 만든다.

## Capabilities

### New Capabilities

- `desktop-interactive-terminal`: 설치 AI CLI의 실제 Windows PTY 입력/출력과 명시적 시작·종료·리소스 소유권.
- `desktop-live-qa-document`: 외부 XML/JSON 파일의 비실행 compile, 충돌 없는 자동 반영, 오류/dirty/stale 보호.
- `desktop-blueprint-canvas`: 실제 QA 블록/핀/edge 편집과 snapshot에 결합된 실행 관찰을 제공하는 데스크톱 작업 공간.

### Modified Capabilities

없음. 현재 `openspec/specs` 정본은 없으며 기존 완료 change의 인수 기록은 수정하지 않는다. 기존 기능의 후속 요구는 이 change에 추가한다.

## Impact

- dependsOn: `qa-desktop-ai-workspace`, `qa-desktop-mvvm-boundaries`, `qa-flow-editor`, `qa-engine-refactor-compatibility`.
- counterpart: Engine 변경 없음. 공개 runtime `0.1.0-alpha.8`, execution contract `0.3.0-draft.2`를 그대로 소비한다. 기본 서버/Agent alpha.6 및 HTTP 계약은 불변이다.
- 예상 경계: Flutter app composition/workbench, Flow 표시/편집, 새 terminal/file-sync Service·Repository·VM, 테스트와 별도 Release 설치/문서. 서버/웹/API 및 Engine 내부 소스는 변경하지 않는다.
- 의존성: `xterm2 5.4.0` exact pin 및 `flutter_pty2 3.0.0` 원본 SHA 기반 vendor. Windows 두 호스트에서 표준핸들 상속 결함을 재현하여 관리 승인으로 STARTF_USESTDHANDLES 1줄을 보완한다. 원본/MIT/provenance/diff를 보존하며 native spike 통과 전 종료 보장을 완료로 보고하지 않는다.
- 이번 할당은 명세·조사까지이며 제품 apply는 관리 검토 뒤 진행한다. API 호출/실기기 지원/Claude 설치 완료는 범위에 포함하지 않는다.
