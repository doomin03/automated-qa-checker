# Design

## D1. 근거와 현재 지원

현재 TerminalWorkbenchViewModel.start는 Codex 외 provider를 거부하고 Codex 전용 인자를 전달한다. LiveDocumentRepository는 QA별 terminal-sessions 아래 편집 사본 및 QA-CONTEXT.md/engine-contract.json을 만든다. 파일 변경→Engine prepare→revision/hash 검사→GUI 반영 기반은 있으나 Claude 실제 실행 및 다중 provider 제품 인수가 완료된 것은 아니다. 새 화면은 설치 탐지나 PTY를 호출하지 않는 예시다. 일반 셸에는 AI skill 준비 배지를 붙이지 않는다. 역할명은 OS 읽기 전용 권한 또는 자동 에이전트 협업을 보증하지 않는다.

Engine은 공개 schema/examples/template/preset 및 검증·실행 의미를, Checker는 작업 사본/cwd/provider별 작성 환경·프로젝트 CRUD·도크 UI를 소유한다. 이번에 skill/plugin 파일을 설치하거나 Engine API를 새로 만들지 않는다.

## D2. 화면 구성과 토큰

frontend-design과 qa-workbench-design을 적용한다. 기존 Photoshop 중립색 canvas #1c1c1c, chrome #292929, panel #323232, controls #414141, text #e0e0e0, selection #8ea8bd를 유지한다. Segoe UI/Malgun Gothic 13px 본문, 12px 코드/컨트롤, 14px 패널 제목, 4px 간격과 1px 구분선을 사용한다. VS Code식은 하단 패널·세션 탭·분할 동작에 적용하며 기존 앱을 웹 카드나 채팅 중심으로 바꾸지 않는다.

```text
홈 / 프로젝트 / QA       저장   검증   실행
Blueprint | XML          문서 상태
라이브러리 | 편집 캔버스 또는 XML | 속성
-------------- 키보드/포인터 리사이저 --------------
터미널 | 출력 | 문제 | 결과       +  분할  확대  접기
작성 Codex | 검토 Claude | PowerShell   세션 메뉴
선택 세션의 입력/출력       | 선택적 두 번째 세션
프로젝트 / QA / cwd · 반영 권한 · 준비/프로세스 상태
```

기본 높이는 편집기가 주영역으로 남도록 제한한다. 확대도 복귀 버튼과 문서 탭을 남긴다. 1024 폭에서는 라이브러리/속성 우선 접힘, 도크 split은 탭 전환으로 대체하고 넓어지면 선호한 두 세션을 복원한다. 새 메뉴·작은 명시 상태만 추가하며 장식 hero/KPI는 만들지 않는다.

## D3. 세션 모델과 문서 소속

세션은 id/provider/roleName/projectId/qaId/cwd/baseRevision/baseHash, contractVersion/runtime/schema pin, 준비 상태, 프로세스 상태, input/output/scroll을 가진다. cwd는 시작 디렉터리와 결과 경로의 바인딩이며 셸의 cd 금지나 추적 보증이 아니다. 동일 provider의 여러 세션을 허용한다. 새 세션 메뉴는 예시 준비 완료와 설정 필요를 구분한다. 준비되지 않은 항목은 필요한 조치와 예시 준비 설정을 제공하며 실제 실행 성공으로 표시하지 않는다.

문서를 바꿔도 세션의 project/QA/cwd는 고정이다. 현재 QA 세션만 기본 목록에 노출하고 다른 문서 세션의 존재와 원래 문서로 돌아갈 경로를 제공한다. 원본 수신 XML·receipt는 수정하지 않는다. 새 세션은 편집 사본 또는 검토 사본을 사용한다. 숨김/접기는 세션 상태를 바꾸지 않고 종료는 별도 확인 후 정리 중→종료됨 또는 정리 미확인 예시로 전환한다. 정리 미확인은 writer를 계속 차단하며 명시 정리 확인 전 새 writer를 양도하지 않는다.

## D4. 단일 writer와 검증

QA 문서당 자동 반영 writer는 최대 하나다. 다른 세션의 검증된 후보도 자동으로 원문을 덮지 않는다. writer 양도는 명시 액션이며 기존 writer 정리/양도 상태를 확인한다. 파일 후보는 project/QA/session/cwd 및 기준 revision/hash/Engine pin과 묶고 공개 Engine 검증 예시 후 현재 문서·기준 동일성, writer, 실행 중 여부를 다시 검사한다. pin이 바뀌면 재검증 전 반영하지 않는다. 사용자 선택 자동 반영 모드에서는 통과 후보를 draft에 반영하되 저장·run은 수행하지 않는다. 불일치/실행 중/검증 오류는 마지막 정상 그래프와 draft를 유지하고 사본/검토 또는 실행 종료 후 재검토로 남긴다.

반례 합의: Engine 담당이 늦은 후보의 새 QA/새 편집 덮어쓰기 위험을 지적했다. 검증 성공만을 적용 조건으로 삼지 않고 위 모든 기준을 추가한다. terminal 프로세스 running/exited, Engine 검증 상태, Engine run outcome, 업무 상태는 별도다. 설치/로그인/skill 준비가 schema 호환이나 실행 PASS를 의미하지 않는다.

구현 교차검토에서 작성자 A→B→A 및 해제→재지정으로 오래된 후보가 되살아나는 반례를 발견했다. 문서별 writerEpoch를 후보에 고정하고 작성자 변경 시 증가시켜 해당 후보를 다시 적용하지 않는다. 새 후보 준비는 고정 fixture를 현재 문서 기준으로 새로 생성하는 목업이며 실제 세션 파일의 재동기화 구현을 주장하지 않는다.

## D5. 입력과 화면 제어

도크만 변경할 때 편집기 DOM을 재생성하지 않는다. XML 입력/선택 범위/scroll, canvas pan/zoom/선택, 세션별 미제출 입력/출력 scroll을 유지한다. 메뉴 종료 시 트리거로 focus 복귀, 세션 전환 시 사용자 선택 대상에만 focus 이동한다. 출력 수신은 focus/확대를 강제하지 않는다. Esc는 팝오버·이름 편집만 취소하며 프로세스 종료/인터럽트를 합성하지 않는다.

리사이저는 separator 역할·방향·현재값을 노출하고 포인터/키보드 방향키/Home/End로 조절한다. 창 크기에 맞춘 최소 편집기/도크 높이를 유지한다. 드래그 중 transition을 적용하지 않고 접기/복귀는 120ms 이하이며 prefers-reduced-motion에서는 끈다. 분할 최소 폭 미만이면 탭 fallback을 표시한다.

첫 브라우저 확인에서 높이 transition과 초기 레이아웃 계산이 충돌해 34px에 머무는 문제가 있어 최종판은 도크 높이를 즉시 변경한다. 연결된 pane만 scroll을 기록하고 재부착 시 복원하여 숨겨진 DOM의 scroll=0이 세션 기록을 덮지 않게 했다.

웹 담당 반례를 수용해 기본 도크 280px, 최소 터미널 160px/상단 편집 220px를 가용 높이에 clamp한다. 이름 편집 중 한글 조합 입력을 DOM 재생성으로 끊지 않는다. 홈으로 이동해도 세션을 폐기하지 않고 소속 문서로 돌아가는 경로를 제공한다.

## D6. 파일 구조와 통합

studio 신규 terminal-dock.js/terminal-dock.css가 모델·렌더·컨트롤을 소유한다. 기존 index는 script/style과 하단 mount, app/home은 문서 변경/수정 revision 연결, review-route는 D08 overlay를 제거하고 실제 dock API를 호출한다. D05/D06/D08은 같은 편집 상태를 유지하고 예시 상태 선택은 해당 도크 상태로 연결한다. portal data/화면설계/여정/결정의 D05/D06/D08을 갱신하며 기존 25 ID를 보존한다.

기획 진입은 기존처럼 sessionStorage namespace를 사용하고 standalone localStorage 문서를 덮지 않는다. 도크 UI 상태/세션 예시도 별도 키로 둔다. 기존 baseline 캡처/로그는 덮지 않고 새 검증 경로를 만든다.

## D7. 검증과 인수

세션 추가/중복 provider/이름/전환/종료와 숨김, 준비 상태, split fallback/복원, pointer/keyboard resize, 문서·입력·focus·scroll 보존, writer 경쟁·늦은 후보·검증 오류·실행 중 반영 제한을 실제 브라우저 조작으로 검증한다. 기존 홈/수신/편집기와 portal 25화면/저장 격리 회귀를 수행한다. 1440×900/1024×768 대표 캡처를 담당·관리자가 검토하고 Engine/웹 담당의 반례→수정→확인을 기록한다. OpenSpec strict/diff check와 저장소 pnpm run verify를 수행한다. 실제 AI/셸/Engine/Windows 실행 인수는 새로 주장하지 않는다.
