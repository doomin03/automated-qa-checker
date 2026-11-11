# Design

## Context

2026-11-11 실제 Git root는 `C:/workspace/QA/automated-qa-checker`, branch main, HEAD `4f97e920a399d4a5434ab1ecbe44c4d879d397a4`다. 이전부터 대규모 dirty tree가 있다. `qa-desktop-ai-workspace`는 12/12 완료이고 `artifacts/releases/desktop-ai-alpha8/Release` 및 실제 Windows/Codex/Engine 인수 문서가 존재한다. 이 기능을 미구현이라고 다시 만들지 않는다.

`qa-desktop-interactive-terminal` tasks는 전부 미완료지만 실제 source에는 `TerminalService`, `LiveDocumentRepository`, `TerminalWorkbenchViewModel`, `TerminalDock`, `BlueprintWorkspace`, `CanvasLayoutRepository`가 연결되어 있다. Desktop 기본 `_flow=true`, 기본 AI폼은 숨김, 실제 pan/zoom/drag/pin/branch·외부 파일 자동 compile source가 있다. 다만 관련 별도 terminal Release는 아직 없고 기존 제품 수준의 최종 인수로 간주하지 않는다.

현재 `DesktopWorkspaceView`는 Material3 버튼/ChoiceChip/Wrap·목록과 일체형 상단을 사용한다. `BlueprintWorkspace`는 개별 Engine action/assertion/branch node를 표시한다. 이것은 사용자가 요청한 XML 파일 단위 블록과 다른 추상화다. public contract의 `testcase.flowRef`는 실행 node의 subflow 호출 근거가 아니다.

## Goals / Non-Goals

Goals: 실제 Flutter의 문서·블록 작성 UX를 전문 도구형으로 바꾸고 XML 단위 재사용과 공개 Engine 전달을 일관되게 연결한다. 기존 terminal 작업과 Provider/문서/실행 수명 경계를 보존한다.

Non-Goals: 웹을 Desktop처럼 재작성, Engine 내부 interpreter/새 DSL 복제, Photoshop/Unreal의 상표/독점 자산 복사, 자동 QA 실행, 새 AI API·키 저장, 서버 runtime 승격, 원격 배포. 사용자 확인 없이 기존 QA 정의를 새 블록으로 강제 변환하지 않는다.

## Decisions

### D1. 제품 화면은 문서 중심

상단은 파일/편집/보기/테스트/도움말 메뉴, 현재 도구 옵션 툴바, 열려 있는 QA 문서 탭을 사용한다. 좌측 tool rail에는 선택/이동 도구와 블록 추가/파일 열기 등의 작은 명확한 제어를 둔다. 별도 palette는 XML 파일 라이브러리와 기본 편집 기능을 구분한다. 중앙은 캔버스, 우측은 선택 항목 inspector와 문서 구조/이력 탭, 하단은 terminal/output/results 도크다.

프로젝트/QA 선택은 동일 shell의 탐색/파일 화면에서 이뤄지며 마케팅 hero나 상태 카드 대시보드를 만들지 않는다. 현재 document name/dirty/validation/run state를 각 소유 영역에서 보여준다. 큰 둥근 카드·과도한 badge·설명 문단을 작업 화면에 반복하지 않는다. 경계선/차콜 명도/유형별 node header·pin 색으로 위계를 만들고 선택과 실행 색을 구분한다.

기본 글자 12~13px, 읽을 수 있는 inspector와 문서명, 28~34px 컨트롤 높이, 작은 border radius를 사용한다. 명령마다 tooltip/키보드 접근과 disabled 이유를 제공한다. 1440×900과 1024×768에서 최소 canvas를 확보하며 dock collapse와 탭 전환을 지원한다. 실행하지 않는 장식 버튼은 넣지 않는다. 관리자가 설치·전달한 디자인 skill 지침은 D7에 반영했다.

### D2. XML 파일과 실행 node의 분리

XML block은 Checker 작성 자산이다. block asset은 이름·보관된 원문 bytes·sha256·원본 표시 경로·확인한 Engine version/hash·요약을 갖고, canvas instance는 asset 참조·instance ID·위치와 연결을 갖는다. 같은 파일을 두 번 놓아도 asset과 인스턴스를 구분한다. 이것은 Engine schema를 변경하는 execution node가 아니다.

원본 XML 파일을 자동 수정하지 않는다. 가져올 때 bounded UTF-8 파일 snapshot과 public compile 결과를 확인한 후 로컬 라이브러리에 보관한다. 변경된 원본을 다시 읽으면 자동 실행/자동 덮어쓰기 없이 명시 갱신과 재검증을 제공한다. 파일 누락/오류/지원하지 않는 조합을 문서의 실행 가능 상태와 구분한다.

기존 workspace v1 strict 데이터 형식을 직접 확장하지 않고 별도 versioned authoring sidecar와 보관 파일을 사용한다. 기존 단일 XML QA는 '직접 XML 문서'로 계속 열 수 있다. 조합 문서를 생성할 때만 authoring identity를 저장하며 DB/sidecar 읽기 오류는 조용한 초기화로 덮지 않는다.

파일 가져오기는 공식 `file_selector: 1.1.0`의 Windows native 파일 찾기를 기본으로 하고 경로 입력을 보조로 제공한다. 파일 선택 Service를 Provider에서 주입하며 View는 파일 IO를 직접 호출하지 않는다. 취소는 원문·라이브러리·모드를 변경하지 않는다. 조합은 XML 필터, 직접 문서는 XML/JSON 필터를 사용한다. 선택 대화 중 QA가 바뀌면 이전 선택을 새 문서에 적용하지 않는다. 테스트는 주입 picker로 결정적 선택/취소를 검증하고 별도 Windows UI smoke로 실제 native dialog를 확인한다.

### D3. 기존 공개 계약의 제한된 정적 조합

현 public `prepare(source)`는 임시 XML/JSON 파일을 만들고 공개 validate/plan을 호출하며 `exportXml(source)`는 공개 export를 호출한다. 이를 통해 조합 결과를 최종 XML로 정규화하고 Engine에서 다시 검증할 수 있다. 그러나 XML 파일을 연속 실행 노드로 배치하는 의미는 `testcase.flowRef`만으로 정해지지 않는다.

2026-11-11 Engine 담당의 읽기 감사와 관리 결정에 따라 **Checker 작성 그래프의 정적 조합**을 채택한다. 임의 subflow/call node, 새 XML tag, 문자열 치환, 서로 다른 target의 강제 병합을 구현하지 않는다. Engine가 단일 run/session으로 실행하는 기존 Blueprint를 생성하는 것으로 블록별 변수 scope/driver lifecycle/timeout 격리를 제공하지 않는다.

첫 지원 범위는 각 원본이 공개 plan에 통과하는 단일 start/end Blueprint이며, outer graph는 모든 인스턴스가 한 번씩 등장하는 명시 순차 연결이다. block 내부 DAG와 true/false 라벨은 유지한다. branch가 밖으로 여러 출구 의미를 만들지 않으며 기존 start/end 경계를 조합 연결로 펼친다. 순환/누락/복수시작·종료/미연결 instance는 compile 오류다. 내부 repeat authoring 문서는 자동 추측 펼침하지 않고 공개 expand 후 생성된 Blueprint를 명시 가져오거나 직접 XML 모드를 사용한다.

공개 plan의 target 객체는 전체 의미가 일치해야 한다. platform/environment/allowedOrigins/launchTargets/profile을 합쳐 쓰거나 최초 파일 값을 택하지 않는다. 초기 compose subset에서는 `references`, `testCase`, `metadata.preset` 및 selector를 포함할 수 있는 target.profile을 수용하지 않고 해당 원본을 지목해 직접 XML 모드 사용을 안내한다. 해당 계약을 지원하지 않는 Engine이라고 표시하지 않는다.

instance별 node/selector/variable namespace를 생성하고 타입별 필드만 remap한다. node.id/flow.entryNode/edge.from,to, variable 선언 key와 valueRef/expectedRef/capture.params.variable/condition.variable, selector 선언 key와 params.selector가 대상이다. secret.ref는 외부 resolver key이므로 변경하지 않는다. 새 ID는 정본 형식/최대 길이를 만족하고 중복 없는 deterministic 매핑이어야 한다. launch target은 전체 target 일치 조건과 원래 params.target을 그대로 유지한다. 알 수 없는 참조 필드를 발견하면 무시하거나 추측 rewrite하지 않고 compile을 거부한다.

원본 testcase/metadata를 조합 결과의 출처로 그대로 승계하지 않는다. 원본 bytes/hash 및 compile source map을 Checker sidecar에 보관하고 generated node→instance→asset/file→source node로 역추적한다. final Blueprint는 공개 export로 XML을 만들고 전체 validate/plan을 다시 호출한다. 전체 Engine 정책에서 secret/capture 등 조합 불가이면 최종 validation 오류를 그대로 표시한다. generated plan hash와 source mapping은 같은 compile identity에 묶는다.

직접 XML 실행은 이 제한된 block compiler와 독립적으로 보존한다. 범위를 확대해야 한다면 지원 규칙과 테스트를 먼저 정합하고, API 의미 변경이 필요한 경우 Engine 계약→구현/검증→version/hash→Checker 소비 순서를 따른다.

### D4. 캔버스 조작과 도킹

기존 pan/zoom/fit·node drag·pin wire·branch 라벨·layout sidecar를 재사용하되 XML-block 문서와 primitive 내부 보기의 모드를 구분한다. 확대/축소 시 node 이동과 wire endpoint 좌표를 같은 canvas 좌표계로 처리한다. 선택/팬/wire gesture가 충돌하지 않아야 한다. node 삭제 시 연결 제거와 undo를 함께 처리하고 Ctrl+Z/Redo/Save/Delete는 canvas/editor focus에만 적용한다. terminal의 Ctrl+C/Delete를 전역 단축키가 가로채지 않는다.

layout 이동은 실행 문서를 바꾸지 않는다. 의미 변경은 authoring revision과 validation을 무효화하고 재compile한다. inspector는 일반 필드를 폼으로 제공하고 XML 원문은 보조 문서 탭이며 무조건 JSON을 사용자에게 요구하지 않는다. 문서 구조 탭에서 라이브러리 파일·인스턴스·연결과 오류로 이동할 수 있다.

### D5. 기존 terminal·실행·저장 수명 유지

AppProviders에서 Service/Repository/ViewModel을 조립하고 View는 IO를 호출하지 않는다. 기존 PTY가 QA/session에 고정되는 규칙, cleanup_unknown/start 차단, file hash/revision 충돌 보호를 보존한다. source에 들어 있는 진행 중 terminal 변경을 덮어쓰거나 완료 이력을 임의 체크하지 않는다.

직접 XML은 공개 Engine prepare/run 경로로 전달하고 실행 snapshot을 고정한다. 조합 문서는 최신 compile 결과의 XML/hash를 확정한 후 동일 경로로 전달한다. 가져오기/저장/compile/터미널 외부 편집은 run을 호출하지 않는다. 실행 중 문서 편집/교체와 외부 변경은 기존 대기/충돌 정책을 따른다. 과거 결과는 원 QA와 snapshot 소속을 유지한다.

### D6. 실제 사용자 인수와 Release

명세 승인 후 먼저 최소 실제 Flutter 화면을 구동하고 관리 시각 검토를 받는다. HTML을 만들어 실제 앱을 대체하지 않는다. compose/직접 XML 각각의 사용자 조작→public validate/plan→명시 실행→PASS/의도 FAIL/취소→PNG를 기록한다. block library 재열기/원본 보존·stale compile·unsupported/충돌 오류를 실제 파일 fixture로 검증한다.

전용 `desktop-xml-block-studio-alpha8` Release를 새로 만들고 전체 파일/native dependency/source manifest와 smoke를 남긴다. 기존 alpha6, alpha6-mvvm, desktop-ai-alpha8, 사용자 workspace와 실행 중 프로세스는 보존한다. 미완료 terminal change를 통합하는 데 필요한 검증을 수행한 뒤 각 change의 실제 완료 항목만 정합한다.

### D7. 디자인 토큰과 레이아웃 검토

관리자가 설치한 공식 Anthropic `frontend-design` 및 프로젝트 companion `qa-workbench-design`을 읽고 적용한다. 실제 기준은 `C:/workspace/QA/.claude/skills/frontend-design/SKILL.md`와 sibling `qa-workbench-design/SKILL.md`다. 상위 skill의 일반 웹 hero 지침보다 명시된 Windows 편집기 brief를 따른다. 프로젝트/사용자/주요 작업은 이미 확정되어 추가 subject 질문은 하지 않는다.

| Token | 값 | 용도 |
| --- | --- | --- |
| canvas | #1c1c1c | 격자 작업 평면 |
| chrome | #292929 | 메뉴·툴바·문서탭 바탕 |
| panel | #323232 | 라이브러리·속성·하단 도크 |
| control | #414141 | 입력·작은 버튼·비선택 탭 |
| text | #e0e0e0 | 기본 내용·제어 이름 |
| selection | #8ea8bd | 선택 테두리·포커스·연결 강조 |

보조 텍스트는 #bcbcbc, 구분선은 #505050을 기본으로 하고 실제 대비/크기로 확인한다. 상태색은 기존 판정 텍스트를 보조할 때만 사용한다. Segoe UI와 Malgun Gothic fallback을 Windows 도구의 익숙한 문자 모양으로 사용하고 컨트롤12px/본문13px/패널 제목14px/코드12px로 제한한다. 단위 간격4px, border1px, control corner2~4px를 적용한다.

```text
파일  편집  보기  블록  테스트  도움말                 프로젝트 / 연결
선택 도구 | 저장 | 실행취소/다시실행 | 검증 | 실행/중단          대상
도구 | 프로젝트 / XML 라이브러리 | QA 문서탭             | 속성
     |                         |                       | 구조
     | 파일을 캔버스로 배치     | XML 블록 ─ XML 블록    | 이력
     |                         |                       | 진단
     |                         | 출력 / 터미널 / 결과  |
상태 | 문서 이름 | 미저장 표시 | 확대 비율 | 실행 상태
```

텍스트는 좌측 정렬하고 선택 block의 파일명·주요 node 라벨에만 시각 강조를 쓴다. 초기안의 파란 브랜드·큰 제목·카드/KPI·숫자장식·상단 AI 탭은 사용자 거절과 겹치므로 제거한다. 중립 회색 도크와 XML file block이 화면 정체성이며 AI는 하단 도구다. 동일 토큰/레이아웃으로 새 독립 목업을 제공하되 제품 source에 시뮬레이션을 넣지 않는다. 이전 목업은 덮어쓰지 않는다.

## Risks / Trade-offs

- 'XML 하나=블록'의 semantics가 primitive node와 달라 UI만 바꾸면 의미 오류가 생김 → D3 계약 checkpoint 선행.
- 이미 진행 중인 PTY/native 코드의 미인수 상태 → 현 상태를 baseline으로 기록하고 관련 회귀·Windows 인수를 함께 완료.
- 도구형 UI의 밀도 → 최소 viewport와 focus/dock 조작을 실제 크기로 검증.
- 기존 workspace migration 위험 → 별도 versioned authoring 보관과 직접 XML 경로 보존.

## Migration Plan

1. 현재 source/pin/Release/목업 baseline hash와 실제 미완료 terminal 범위를 기록한다.
2. 관리 디자인 지침 및 XML composition 계약을 명세에 확정하고 strict 후 apply한다.
3. 실제 shell→XML block library/compile→직접 XML/terminal/실행 연결을 작은 단위로 구현한다.
4. 실제 Windows 사용자 경로·관련 전체 회귀·필수 저장소 검사·새 Release/문서 인수를 마친다. 기존 Release로 돌아갈 수 있게 보존한다.
