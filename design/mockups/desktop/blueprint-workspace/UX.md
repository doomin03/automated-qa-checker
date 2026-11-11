# Blueprint Desktop UX 설계

기존 웹형 카드 배치를 프로젝트 안에서 QA를 편집하는 도구형 화면으로 바꿨다. 핵심은 **선택한 블록, 제안이 바꿀 범위, 현재 검증 상태**를 작업 공간 안에서 함께 읽는 것이다.

## 정보 구조

프로젝트 목록은 이름·QA 수·최근 작업을, 프로젝트 상세는 QA 이름·초안 상태·문서를 보여준다. QA를 열면 상단 메뉴/툴바와 문서 탭, 좌측 프로젝트 탐색, 중앙 Blueprint/XML, 우측 블록 속성·AI, 하단 타임라인/로그, 상태바를 사용한다. 큰 페이지 제목이나 hero는 두지 않는다. 1024에서는 패널을 접어 캔버스를 확보하며 스크롤은 패널 안에서만 한다.

어두운 차콜 명도를 영역별로 나누고 파란 선택/액션 강조를 사용한다. 상태는 PASS/FAIL/환경 오류/미실행이라는 텍스트와 이유로 구분한다. 포트와 방향 화살표는 실제 edge 방향과 맞는다. 아래쪽 역방향 연결도 블록 몸체를 관통하지 않게 양쪽 포트를 사용한다. 그라데이션과 장식 아이콘은 없다.

## XML과 그래프

프로젝트/QA ID는 Checker 탐색 ID이고 Blueprint/flow/node ID는 실행 문서의 ID다. 화면에서는 불필요한 구현 설명을 줄이고 선택 문맥 확인에 필요한 ID만 보여준다.

XML 원문과 parse 결과가 유일한 문서 모델이다. 그래프·속성·AI가 같은 node ID를 본다. XML 탭에서 node 구간을 고르면 코드 범위가 선택되고 그래프/AI 선택도 일치한다. 미반영 XML은 QA별 메모리에서 유지하고 원문 반영 전 실행/AI 적용을 막는다.

지원 subset은 공개 alpha.6 로그인 fixture의 한 flow, start/end, 선형 launch/input/tap/assertText/screenshot과 알려진 params/timeout이다. 앞·뒤 삽입은 XML 배열 순서가 아닌 edge 분할이다. 원문 DOM의 variables/selectors/target 선언을 유지하며 node ID·edge·selector/variable/target 참조를 검사한다. unknown element/attribute/params, JSON 영역의 XML 자식, 분기/반복/다중 flow, cycle, 중복 ID·잘못된 참조는 원문을 보존하고 편집 미지원 또는 오류로 표시한다. 이전 정상 graph를 새 원문의 graph처럼 보여주지 않는다.

지원 범위 밖이라는 표시는 **이 목업의 제한**이다. Engine가 해당 기능을 지원하지 않는다는 뜻이 아니다. 적용된 XML은 DOM 직렬화로 공백·표현이 정규화될 수 있지만, 미변경 fixture와 undo 원문은 정확히 보존한다.

## AI 제안

오른쪽 패널에 공급자와 데모 설정 상태, 선택 node·문서 revision, 네 범위, 요청 입력, 변경 미리보기를 둔다. 미설정이면 AI 설정으로 이동해 password 폼에서 연결을 시연해야 제안받기가 활성화된다. API 키 입력은 메모리만 사용하고 전송/영속 저장/로그 출력하지 않는다. 실제 키를 입력할 필요가 없으며 기본/인수 값은 가짜다. OpenAI 설정은 Codex CLI 로그인이나 구독 인증을 완료하지 않는다.

| 범위 | 이 목업의 예시 변환 |
| --- | --- |
| 선택 수정 | 선택 동작의 timeout을 5000ms로 변경 |
| 앞 삽입 | incoming edge를 분할해 screenshot node 삽입 |
| 뒤 삽입 | outgoing edge를 분할해 screenshot node 삽입 |
| 전체 흐름 변경 | 현재 모델의 assertText timeout을 변경하고 launch 뒤에 screenshot 삽입 |

전체 변경은 선택이 없어도 가능하며 현재 문서의 기존 node와 선언을 고정 샘플로 교체하지 않는다. 시작 앞·종료 뒤·분기의 모호한 삽입은 거절한다. node ID 충돌은 새 ID로 피한다. 네 범위는 편집 범위이며 부분 실행 기능이 아니다.

자유 요청은 대화에 보이지만 실제 언어 이해나 Claude/Codex 호출은 없다. `예시 제안`과 고정 변환임을 짧게 표시한다. 요청/범위 → 바뀌는 node·edge → 결과 XML을 보고 적용/취소한다. 미리보기와 취소는 변경 0회다. 문서·revision·선택 문맥이 달라지면 오래된 제안을 적용할 수 없다. undo는 이전 원문을 복원하면서 revision을 증가시켜 과거 제안이 다시 유효해지지 않게 한다.

## 검증과 실행 결과

semantic 편집·AI 적용·undo는 검증을 무효화하고 자동 실행하지 않는다. 현재 revision과 대상이 보이는 상태에서 검증 → 테스트 실행 한 번으로 진행한다. 실행 중 편집과 QA 이동은 잠기고 중단은 가능하다.

node 색·타임라인·로그는 실행 시점 snapshot에 결합한다. 초안을 바꾸면 old run 색을 새 graph에 이식하지 않으며 하단에 이전 snapshot 결과만 보존한다. 환경 오류는 QA assertion FAIL과 다르고 후속 미실행은 PASS가 아니다.

## 실제 구현과의 경계

이 파일은 HTML 검토 목업이다. 현재 Flutter의 기능을 새 배치로 검토하지만 스타일을 제품에 이식하지 않았다. 실제 전체 XML 편집·Engine 실행·인증·영속 저장은 기존 제품의 책임이다. 이번 목업에는 node 자유 연결, 분기 편집, 실제 AI 대화, 실제 키 검증/저장, 실제 서버 공유가 없다. 새로고침하면 모든 초안·키·결과가 초기화된다.

공개 Engine XML fixture는 설치 배포물에서 읽었으며 초기 XML과 네 가지 생성 XML은 실제 public CLI validate/plan으로 확인했다. 브라우저 이벤트와 키 시연은 별도 로컬 인수다. [verification.json](verification.json)과 [화면 목록](README.md)을 참조한다.
