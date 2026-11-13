## Why

기존 밝은 웹형 목업은 프로젝트 안에서 QA를 개발하는 Desktop 작업 공간의 밀도와 탐색 구조를 충분히 보여주지 못했다. 사용자 요청에 따라 프로젝트→QA 목록→Blueprint 편집의 계층과 선택 블록 문맥의 AI 제안 적용을 검토할 새 목업이 필요하다.

## What Changes

- 프로젝트 목록과 프로젝트별 QA 목록을 데스크톱 테이블로 구성하고 QA 상세를 도킹 패널형 Blueprint 작업 공간으로 연다.
- 어두운 차콜 배경, 컴팩트 메뉴·툴바·문서 탭·상태바, 팬/줌 노드·포트·곡선 연결 캔버스, 선택 속성, 하단 실행 로그·타임라인, 오른쪽 AI 대화를 제공한다.
- XML과 그래프가 같은 편집 모델을 사용하며 지원하지 않는 입력은 원문을 보존하고 그래프/AI 편집을 차단한다.
- AI 데모는 선택 수정/앞 삽입/뒤 삽입/전체 흐름 변경을 미리보기→적용 또는 취소로 연결한다. undo, stale 제안 차단, 변경 후 재검증과 자동 실행 0회를 인수한다.
- Anthropic/Claude와 OpenAI(Codex 연동용) 설정 화면은 password 입력·표시/숨김·연결/해제 폼을 제공한다. 기본값과 인수에는 가짜 키만 쓰며 입력값은 메모리에만 두고 저장·전송·실제 연결 성공 표시는 하지 않는다.
- 기존 root 목업과 인수 자료를 보존하고 blueprint-workspace 하위 폴더에 새 목업·캡처·설계 문서를 둔다.

## Capabilities

### New Capabilities
- `qa-desktop-blueprint-review`: 계층 탐색, 동기화된 XML/그래프 및 문맥에 묶인 AI 제안을 검토하는 로컬 Desktop 목업.

### Modified Capabilities
없음. 기존 제품 및 기존 목업 인수의 요구사항을 덮어쓰지 않는다.

## Impact

소유 경로: `design/mockups/desktop/blueprint-workspace/**` 및 이 change. 이전 root 목업·캡처·검증 자료는 그대로 보존하고 `design/mockups/desktop/README.md`에 새 기본 검토 링크만 안내한다. 기존 인수 결과를 새 목업 결과로 바꾸지 않는다. 제품 Flutter/서버/SDK/Engine pin/루트 package·lockfile은 변경하지 않는다. dependencies 추가 없음, counterpart는 Checker Desktop 기능, contractVersion 변경 없음. dependsOn: qa-desktop-ui-mockup, qa-flow-editor, qa-ai-blueprint. 공개 Engine alpha.6 XML fixture와 계약을 읽기 전용으로 참고한다.

최초 명세 checkpoint와 strict 이후 조건부 apply 승인을 받아 목업을 구현했다. 원격 게시·Figma·제품 스타일 이식·실제 AI 호출·commit/push는 범위 밖이다.
