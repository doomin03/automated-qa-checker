# XML 파일 블록 작업실

2026-11-11 재설계는 실제 Flutter Windows 앱에 적용한다. 화면 목업은 `design/mockups/xml-block-studio/index.html`이며 제품 실행과 구분한다. 이전 `product-flow-review` 및 기존 Release는 보존한다.

## 화면과 주요 여정

| 화면 | 목적 | 입력·행동 | 결과·예외 |
| --- | --- | --- | --- |
| 프로젝트 / QA | 작업 문서 선택 | 프로젝트 만들기 → QA 만들기 또는 기존 QA 열기 | 문서와 실행 소유권을 QA에 고정 |
| XML 라이브러리 | 재사용할 파일 보관 | XML 가져오기 → 파일 선택 → 클릭/드래그 배치 | 원문 스냅샷·SHA-256·출처 보관. 원본 파일 자동 수정 없음 |
| 파일 블록 캔버스 | 외부 실행 순서 작성 | 파일 블록 이동, 출력→입력 연결, 삭제/Undo/Redo | 모든 블록이 연결된 단일 비순환 순서. 내부 동작 노드와 구분 |
| 속성 / 구조 / 이력 | 선택과 수정 맥락 확인 | 블록 선택, 읽기 전용 원문 확인, 연결 삭제 | 같은 자산의 여러 인스턴스도 분리. 직접 문서 편집은 명시 전환 |
| 검증 / 생성 XML | 실행 문서 확정 | 개별 source prepare → 필드별 매핑 → 전체 export/prepare | 표준 Engine XML과 source map. 미지원 조립은 진단, 자동 실행 없음 |
| 직접 문서 / XML | 파일을 독립적으로 편집·실행 | XML/JSON 직접 열기, 편집, 검증, 실행 | 조합을 거치지 않는 기존 경로 유지. 모드·저장 대상 분리 |
| 출력 / 결과 | 실행 관찰 및 원인 추적 | 명시 실행, 취소, 실패의 원인 파일 블록 선택 | 실제 terminal 결과·PNG. 과거 snapshot과 다른 자산으로 오연결 금지 |
| 터미널 | 현재 QA의 CLI 작업 | 기존 PTY 세션 열기·입력·종료 | 기존 격리/cleanup/외부 편집 가드 유지. 별도 change의 미완료 인수는 유지 |

메뉴/툴바/문서탭은 중립 회색의 작은 도구 셸이다. 중앙 작업 영역은 연속 격자와 실제 XML 파일 블록을 보여준다. 1024px에서는 라이브러리를 버튼으로 열며 전체 파일에 접근한다. 속성은 파일명·내부 동작·실행 대상부터 보여주고 경로/해시는 상세로 접는다. 실행/문서 dirty는 footer와 문서 탭에서 확인한다.

## 저장과 편집 의미

자산 원문은 가져올 때 보관한다. 외부 원본이 이동·삭제되어도 저장된 문서를 읽는 데 원본 파일을 다시 요구하지 않는다. 원본 변경을 적용하려면 명시적으로 다시 가져온다. 같은 원문은 라이브러리에서 재사용하고 다른 원문은 새 자산으로 들어온다. 내부 확인 화면은 읽기 전용이며 공유 원문이나 인스턴스를 조용히 수정하지 않는다.

작성 sidecar는 workspace의 `xml-blocks-v1`에 QA identity별로 저장한다. 모드, 자산/좌표/연결, Engine version/contract/package hash, 생성 XML/hash/source map과 실행 매핑 identity를 기록한다. 기존 workspace v1 형식을 바꾸지 않는다. 손상된 저장 파일은 자동 초기화하여 덮지 않으며 외부 revision 충돌도 저장을 거부한다. 재열기는 전체 조합 재검증을 요구한다.

레이아웃 이동/Undo는 실행 의미를 바꾸지 않는다. 자산/연결 변경은 검증을 무효화한다. 선택 변화만으로 실행 검증을 무효화하지 않는다. 검증 중 source revision, QA 또는 설정이 달라지면 늦은 결과를 적용하지 않는다. 생성 XML 탭을 여는 것은 직접 모드 전환이 아니다. 직접 모드 전환은 안내 후 명시적으로 수행하며 다음 조합은 실행 원문을 합성 결과로 교체한다.

## 지원되는 정적 조립 범위

각 원문은 고정된 Engine alpha.8 공개 validate/plan에 통과해야 한다. 단일 start/end, 완전히 동일한 target, 모든 인스턴스가 한 번씩 연결되는 순차 외부 그래프를 지원한다. 내부 branch와 true/false 라벨은 보존한다. 인스턴스별 node/selector/variable 및 정해진 참조 필드를 매핑하고 secret.ref 외부 키는 바꾸지 않는다. start/end 경계를 접합하여 하나의 실행 session을 만든다. 블록별 driver 초기화·정리·독립 timeout/변수 scope는 제공하지 않는다.

references, testCase/preset metadata, target profile, raw authoring 반복은 초기 조합 subset 밖이다. 기존 직접 XML 또는 명시적인 공개 authoring expand 경로로 사용한다. target의 origin/environment를 합치거나 허용 범위를 넓히지 않는다. 최종 문서의 secret/capture 등 정책은 Engine 전체 검증이 판정한다. Checker 고유 실행 schema나 Engine 소스 복제는 없다.

## 검증 자료

현재 작업의 실제 결과와 최종 Release는 `docs/validation-xml-block-studio.md`에 기록한다. HTML 검증은 목업의 조작·배치만 확인한다. 실제 Windows/Engine 실행, 네이티브 파일 선택, 기존 terminal 회귀와 구분한다.
