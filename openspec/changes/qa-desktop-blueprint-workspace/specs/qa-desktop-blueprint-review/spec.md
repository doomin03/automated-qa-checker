## Purpose

사용자가 프로젝트와 QA를 찾아 Desktop Blueprint 문맥에서 XML·그래프를 편집하고 선택 영역에 대한 AI 제안을 검토하는 과정을 로컬 목업으로 인수한다. 실제 제품 실행·AI 연결과 검토용 상태 전환을 구분한다.

## ADDED Requirements

### Requirement: Hierarchical desktop workspace
목업 SHALL 프로젝트 목록→프로젝트별 QA 목록→QA 상세의 탐색을 제공하고 어두운 차콜 도킹 편집기에서 내부 패널 스크롤과 접기를 지원한다.

#### Scenario: Open a QA in its project
- **WHEN** 사용자가 프로젝트와 QA 행을 선택하고 연다
- **THEN** 프로젝트/QA 식별자와 Blueprint/flow 식별자를 혼용하지 않고 해당 QA의 캔버스·속성·AI·하단 로그를 연다

#### Scenario: Compact desktop viewport
- **WHEN** 1440×900 또는 1024×768 창에서 탐색과 편집을 한다
- **THEN** 큰 hero나 페이지 전체 세로 스크롤 없이 중앙 캔버스를 유지하고 패널 내부 스크롤/접기로 내용에 접근한다

### Requirement: Consistent XML and graph model
목업 SHALL 현재 XML parse 결과를 graph/속성/AI 선택의 유일한 실행 문서 모델로 사용하고 미지원 XML 원문을 보존한다.

#### Scenario: Select a node in XML
- **WHEN** 사용자가 XML의 node 구간을 선택한다
- **THEN** 같은 node ID가 그래프·속성·AI 문맥에 선택되고 XML 변경 반영 뒤에는 최신 모델만 표시한다

#### Scenario: Unsupported or invalid XML
- **WHEN** 입력에 미지원 element/attribute/params, 분기, 중복 ID 또는 잘못된 참조가 있다
- **THEN** 이유를 표시하고 원문을 보존하며 이전 정상 graph로 몰래 대체하거나 일부를 버리지 않고 AI/graph 편집·실행을 차단한다

### Requirement: Navigable Blueprint canvas
목업 SHALL node ID에 묶인 포트·곡선 edge를 표시하고 팬·줌·전체 보기·선택을 제공한다.

#### Scenario: Inspect a graph at another scale
- **WHEN** 사용자가 캔버스를 이동하거나 줌을 변경한 뒤 node를 선택한다
- **THEN** 포트·연결선이 같은 graph 위치에 유지되고 선택 문맥이 일치하며 XML 의미와 revision은 변하지 않는다

### Requirement: Four scoped AI proposal previews
목업 SHALL 선택 수정/앞 삽입/뒤 삽입/전체 흐름 변경의 네 편집 범위를 미리보기 뒤 명시적으로 적용하거나 취소하도록 제공한다.

#### Scenario: Insert before or after a selected node
- **WHEN** 사용자가 지원되는 선형 graph에서 앞/뒤 삽입 제안을 적용한다
- **THEN** XML 배열 위치 대신 해당 incoming/outgoing edge를 분할해 새 node를 연결하고 node ID 충돌과 전체 참조를 검증한다

#### Scenario: Reject ambiguous insertion
- **WHEN** 선택 지점에 분기 label 또는 다중 incoming/outgoing이 있거나 start 앞/end 뒤를 요청한다
- **THEN** 지원 제한을 명시하고 임의 edge를 선택하거나 XML을 바꾸지 않는다

#### Scenario: Preview selected or whole-flow changes
- **WHEN** 선택 수정 또는 전체 흐름 변경 제안이 준비된다
- **THEN** 선택 node·영향 범위·변경 전후를 먼저 표시하고 적용 전에는 현재 문서를 바꾸지 않는다

#### Scenario: Cancel and undo
- **WHEN** 사용자가 제안을 취소하거나 적용 후 undo한다
- **THEN** 취소는 문서 변경 0회이며 undo는 직전 XML을 정확히 복원하고 자동 실행하지 않는다

### Requirement: Stale proposal protection
목업 SHALL AI 제안의 문서·revision·선택 context를 검사해 오래된 제안을 거절한다.

#### Scenario: Context changed after proposal
- **WHEN** 미리보기 후 XML 편집·다른 node 선택·QA 전환 또는 undo가 발생한다
- **THEN** 이전 제안 적용은 거절되고 현재 문서가 보존되며 재요청을 안내한다

### Requirement: Revision validation and run snapshot
목업 SHALL semantic 편집 뒤 재검증을 요구하며 명시 실행의 진행을 immutable 실행 snapshot에만 결합한다.

#### Scenario: Apply is not execution
- **WHEN** XML/속성/AI 변경 또는 undo가 적용된다
- **THEN** 검증은 무효화되고 실행 횟수는 증가하지 않으며 새 revision 검증 후 실행 클릭이 있어야 시뮬레이션을 시작한다

#### Scenario: Old run after draft edit
- **WHEN** 실행 종료 후 초안을 편집하거나 다른 QA를 연다
- **THEN** 이전 실행 node 색을 새 초안에 이식하지 않으며 결과·로그는 해당 snapshot의 기록으로 구분한다

#### Scenario: Failed and unrun nodes
- **WHEN** 실행 데모가 실패하거나 환경 오류·사용자 중단이 발생한다
- **THEN** 실제로 진행한 snapshot node와 미실행 node를 구분하고 환경 오류·미실행을 PASS로 표시하지 않는다

### Requirement: Demo-only provider settings
목업 SHALL Anthropic/Claude 및 OpenAI(Codex 연동용) password 입력·표시/숨김·연결/해제를 제공하고 기본/인수에는 가짜 값만 사용하며 입력값을 영속 저장·로그·전송하지 않는다.

#### Scenario: Configure a demo provider
- **WHEN** 사용자가 password 입력·표시/숨김·연결 시연·해제를 조작한다
- **THEN** 데모임과 실제 연결하지 않음을 표시하고 URL·localStorage·sessionStorage·IndexedDB·cookie·파일에 키를 보관하지 않으며 새로고침하면 설정이 초기화된다

#### Scenario: Unconfigured provider cannot propose
- **WHEN** AI 패널의 선택 공급자가 미설정 상태다
- **THEN** 공급자·미설정 상태와 설정 진입을 표시하고 데모 연결 설정 후에만 제안받기를 활성화한다

### Requirement: Preserved review evidence
목업 SHALL 이전 목업 원문/검증/캡처를 기존 경로에 보존하고 새 하위 폴더의 실제 브라우저·공개 CLI 비실행 검증·캡처를 구분해 제공한다.

#### Scenario: Review the new workspace
- **WHEN** 관리자가 HTML과 검증 근거를 검토한다
- **THEN** v1 보존 checksum, 네 AI 범위 생성 XML의 validate/plan 결과, 두 viewport 캡처, 네트워크/키 저장 없음과 현재 제품 대비 목업 한계를 확인할 수 있다
