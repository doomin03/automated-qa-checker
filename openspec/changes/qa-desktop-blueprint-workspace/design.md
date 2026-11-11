# Design

## Context

기존 `qa-desktop-ui-mockup`은 밝은 Flow 목록과 서로 독립된 고정 XML·Flow 표현이다. 이번 요청은 어두운 Desktop Blueprint 편집기와 동일 모델 기반 편집으로 바뀌었다. 이번 턴의 제품 Flutter는 동결하며 여기서는 로컬 HTML만 만든다. 원본은 설치된 Engine alpha.6 공개 `contracts/releases/qa-blueprint-0.1.0-alpha.6.xml`이며 실행 문법의 정본을 새로 정의하지 않는다.

## Goals / Non-Goals

**Goals:** viewport 안의 밀도 높은 편집, 프로젝트·QA 계층 탐색, 동일 node의 그래프/XML/속성/AI 문맥 연결, 변경을 검토한 뒤 적용하는 네 가지 AI 범위, 손실 없는 unsupported 처리, 검증·명시 실행·snapshot 진행 분리.

**Non-Goals:** 실제 AI/인증/키 영속 저장, 실제 Engine 실행, 새 실행 DSL, 전체 Engine XML 편집기, branch 편집, 자유 wire 연결, 제품 스타일 이식, 서버·계약·라이브러리 추가. 이 목업의 네 AI 범위는 편집 범위이며 부분 실행 기능이 아니다.

## Decisions

### 1. Desktop IA와 도킹 배치

프로젝트 목록 → 프로젝트 상세의 QA 목록 → QA 상세 작업 공간을 별도 화면으로 표현한다. 프로젝트/QA 목록은 큰 hero·카드 대신 행 선택·열기·검색이 있는 테이블이다. 작업 공간에는 상단 메뉴/툴바와 문서 탭, 좌측 프로젝트/QA 탐색, 중앙 Blueprint/XML 탭, 중앙 하단 실행 타임라인·로그, 우측 속성/AI 대화 도킹 영역, 최하단 상태바가 있다. 명령은 한국어 텍스트 위주이며 불필요한 아이콘과 그라데이션은 없다.

1440×900에서는 탐색·캔버스·속성·AI를 동시에 볼 수 있다. 1024×768에서는 탐색/도킹 패널 접기와 패널 내부 스크롤로 중앙 작업 영역을 유지한다. document 전체 세로 스크롤을 만들지 않고 각 목록·XML·대화·로그 패널 안에서 스크롤한다. 차콜의 3단계 명도와 경계선, 한 가지 주 강조색으로 위계를 만든다. PASS/FAIL/환경 오류/미실행은 텍스트와 원인으로 구별한다. 상단에 작은 `목업 · 예시 데이터` 표시를 두며 화면마다 긴 개발 경고를 반복하지 않는다.

### 2. 입력과 동일 모델

Checker `projectId/qaId`는 탐색 식별자다. `blueprint.id`, `flow.id`, `node.id`와 혼용하지 않는다. 문서 세션은 `{projectId, qaId, documentId, revision, rawXml, parsedDocument, supported, selectedNodeId}`를 가지며 원문은 사용자 입력 그대로 유지한다. graph와 속성·AI 문맥은 현재 parse 결과에서만 파생한다. 문서/선택 식별자 변경 시 AI context 세대가 증가한다.

지원 범위는 공개 fixture의 하나의 flow, start/end 각 하나, launch/input/tap/assertText/screenshot의 선형 연결과 알려진 속성·params다. variables/selectors/target은 원문 DOM의 별도 구역으로 보존하며 노드/params 참조를 검사한다. 중복 node ID, 없는 edge endpoint, 연결되지 않은 node, cycle, entry 불일치, 없는 selector/variable/target 참조를 거절한다. 알 수 없는 element/attribute/params, 다중 flow·분기·반복 또는 알려진 범위 밖 액션은 `이 목업에서 편집 미지원`으로 구분한다. public Engine 자체가 해당 문서를 지원하지 않는다고 단정하지 않는다.

무지원/잘못된 입력도 rawXml을 보존한다. 그래프를 이전 정상 입력으로 몰래 대체하지 않으며 비어 있는 캔버스 안내와 원문 탭을 제공한다. AI·속성 편집·실행을 차단하고 XML 수정/undo/예시 복원만 가능하다. 지원 입력에 대한 편집은 기존 DOM을 복제해 지정된 node/edge만 바꾸고 원본의 variables/selectors/target을 유지한다. 포맷 정규화는 명시하며 undo는 직전 rawXml을 정확히 복원한다. 미변경 fixture bytes는 그대로 보존한다.

XML 탭은 전체 원문 편집과 node별 코드 구간 선택을 함께 제공한다. 코드 구간 클릭 또는 대응 node 선택은 그래프와 같은 `selectedNodeId`를 갱신한다. 별도 고정 Flow 문자열은 두지 않는다. 원문 편집은 적용할 때 전체 문서 parse/지원 검사 후 한 revision으로 반영하며 입력 대기 상태에서는 실행·AI 적용을 막는다. 미반영 입력도 QA별 메모리에 보존하므로 다른 QA로 이동했다 돌아와도 사라지지 않는다. 미반영 입력이 있는 동안 graph에는 적용 전 문서라는 안내를 표시한다.

### 3. 노드 캔버스

노드에는 node ID, 동작 제목, params 요약, 입력/출력 포트를 표시한다. edge.from/to를 SVG 곡선으로 렌더링하며 label이 있으면 보존·표시한다. branch/label 연결의 편집은 지원하지 않는다고 명시하고 AI 삽입을 차단한다. 빈 캔버스 드래그 또는 Space+drag로 팬, wheel/+/−로 40~160% 줌, 전체 보기로 좌표를 복구한다. node 선택과 필요 시 화면 내 위치 이동은 UI layout만 바꾸며 XML 의미/revision을 바꾸지 않는다. 위치를 실행 schema에 저장하지 않는다.

### 4. AI 문맥과 네 범위

오른쪽 AI 패널에 현재 프로젝트/QA와 선택 node, 범위 선택, 한국어 요청, 대화 및 제안 미리보기를 둔다. 결과는 deterministic mock이며 `예시 제안`으로 표시한다. 자유 요청은 대화에 보이지만 실제 언어 이해를 한 것처럼 응답하지 않는다. 선택 범위에 정해진 예시 변환을 사용한다고 짧게 안내한다. 제안은 `{documentId, baseRevision, contextGeneration, selectedNodeId, scope, prompt, beforeXml, afterXml, affectedNodeIds}`를 고정한다. 요청/범위→변경 node·삽입 edge→결과 XML을 시각적으로 추적할 수 있다.

| 범위 | 적용 의미 | 제약 |
| --- | --- | --- |
| 선택 수정 | 선택 node의 지원 params/timeout 변경 | ID와 외부 참조 유지 |
| 앞 삽입 | 선택 node의 유일한 incoming edge를 A→새 node→선택으로 분할 | start 앞/다중 incoming/분기 label은 차단 |
| 뒤 삽입 | 선택 node의 유일한 outgoing edge를 선택→새 node→B로 분할 | end 뒤/다중 outgoing/분기 label은 차단 |
| 전체 흐름 변경 | 문서 전체의 지원 node/edge 변화를 미리보기 | 선택이 있어도 범위가 전체임을 명시, root 참조 검증 |

삽입 node ID는 문서 내 충돌을 검사해 발급한다. 예시 삽입은 새 selector가 필요 없는 screenshot을 사용한다. 전체 변경도 기존 start/end와 외부 선언을 보존하는 유효한 선형 그래프로 제한한다. 단순 XML 배열 순서로 삽입하지 않는다.

미리보기는 문서에 영향이 없다. 적용은 모든 context/revision 일치와 후보 전체 참조 검증을 통과한 경우에만 원자 반영한다. selection/QA/문서가 바뀌거나 다른 XML 편집·undo가 일어나면 stale로 거절하고 재요청을 안내한다. 취소는 변경 0회다. undo는 한 번의 적용을 되돌리되 revision은 단조 증가하여 예전 제안이 다시 유효해지지 않게 한다. 변경 후 검증을 무효화하며 자동 실행하지 않는다.

### 5. 검증과 실행 snapshot

UI 검증은 지원 subset의 구조·참조 검사이며 실제 Engine 검증과 구분한다. 검증된 현재 revision과 대상을 표시한 뒤 실행 클릭 한 번으로 타이머 진행을 시작한다. 실행 중 semantic 편집/AI 적용·QA 전환을 잠그고 중단을 제공한다. 진행은 immutable run snapshot의 node ID에 결합한다. 실행 후 draft가 바뀌면 캔버스의 이전 run 색을 제거하고 하단 결과는 `이전 실행 snapshot`으로 보존한다. QA 전환 시 다른 QA의 실행 표시를 가져오지 않는다.

실행 snapshot에 속한 node만 진행/통과/실패/미실행으로 표시한다. 환경 오류는 실행 전 실패, 후속 node는 미실행이다. 로그·타임라인은 동일 run snapshot으로부터 나온다. 데모 결과 변경은 별도 설정에 둔다. 실제 assertion/기기/AI 실행으로 보고하지 않는다.

### 6. 제공자 설정과 비영속성

설정은 별도 dialog로 제공한다. 최신 관리 요청에 따라 Anthropic/Claude, OpenAI(Codex 연동용)의 password 입력·표시/숨김·연결/해제 폼을 만든다. AI 패널에 현재 공급자와 데모 설정 상태를 표시하고 미설정이면 설정→연결 시연 후에만 제안받기를 활성화한다. 기본값과 인수는 명백한 가짜 키만 사용하며 실제 비밀값 입력을 요구하지 않는다. 입력값은 메모리에서만 유지하고 URL/localStorage/sessionStorage/IndexedDB/cookie/파일·대화·로그·검증결과에 저장하지 않는다. 연결 버튼은 `연결 시연`이며 `실제 연결하지 않음` 결과만 반환한다. provider API key 설정이 Codex CLI 로그인이나 ChatGPT 구독 인증을 구성한다는 표현을 쓰지 않는다. CSP connect-src none과 네트워크/저장 API 감시 회귀를 적용한다. 캡처에서는 password 마스킹을 유지한다.

### 7. 인수와 보존

최신 관리 승인에 따라 기존 root 목업의 HTML/JS/CSS/fixture/verify/문서/verification/캡처를 현재 경로에 보존하고 새 산출물은 `design/mockups/desktop/blueprint-workspace`에 둔다. 이전 원문과 캡처는 checksum으로 보존을 확인한다. 상위 목업 README의 새 검토 링크 추가 외 기존 OpenSpec 및 부모 소유 문서는 변경하지 않는다.

기존 Playwright로 두 viewport에서 프로젝트/QA 탐색, pan/zoom, graph/XML 선택 일치, AI 네 범위의 preview/apply/cancel/undo/stale, unknown XML 원문 보존, branch 삽입 거부, revision 검증, snapshot node 진행, 키 비영속/외부 요청 0을 인수한다. 생성한 지원 XML은 설치된 공개 CLI validate/plan을 argument array·shell=false로 호출해 확인하며 run은 호출하지 않는다. 초기 fixture와 네 범위 적용/undo의 XML 산출물을 캡처·검증 근거로 보존한다.

## Risks / Trade-offs

- [부분 XML 편집기로 데이터 손실] → 좁은 지원 allowlist와 unknown 거절, rawXml 보존·정확 undo, 공개 CLI 비실행 roundtrip.
- [노드 선택 변경 뒤 잘못된 AI 적용] → document/revision/contextGeneration 검사와 stale 반례 인수.
- [오래된 실행 결과가 새 초안에 보임] → run snapshot 별도 보관, draft revision 불일치 시 진행 overlay 제거.
- [조밀한 화면의 가독성] → 중앙 viewport 우선, 내부 스크롤·패널 접기, 두 viewport 실제 캡처 검수.
- [AI/키 화면을 실제 연결로 오인] → 작은 지속 데모 배지, 기본/테스트는 가짜 값, 요청/영속 저장 0회 회귀.

## Migration Plan

명세와 strict 결과를 관리 에이전트에 보고한다. 명세 strict 후 apply에 대한 조건부 관리 승인을 수신했으므로 기존 목업 checksum 기록 → 새 하위 폴더 구현 → 첫 캔버스 시각 검수 → 공개 CLI와 브라우저 인수 → 최종 캡처 검수 순서로 진행한다. 제품 이식이나 원격 배포가 없으며 이전 목업은 기존 index.html로 계속 열 수 있다.
