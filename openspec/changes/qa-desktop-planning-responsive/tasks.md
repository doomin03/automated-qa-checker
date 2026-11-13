# Tasks

현재 상태: 관리 승인 후 구현 및 로컬 인수 완료. 위젯 행렬·context/pin 회귀·실제 native 창 크기·전체74회귀/1조건부skip·별도 Release를 검증했다. 근거는 `docs/validation-planning-responsive.md`와 `artifacts/planning-responsive/acceptance.json`이다. 서버/생성 SDK는 counterpart 담당 인수를 참조하며 후속 로드맵이나 실제 AI 모델 호출을 완료로 확대하지 않는다.

## 1. Adaptive shell and home

- [x] 1.1 기존 layout의 800×600/1280×500·text1.5 baseline을 재현하고 제약 기반 shell/패널 정책을 적용한다. ScreenUtil 추가 없이 geometry/필수 액션/resize 상태 보존 위젯 회귀 및 결정 문서로 확인한다.
- [x] 1.2 D01–D04 홈/QA/수신/로컬 사본의 상단·sidebar·목록/상세·검색·dialog를 조정한다. 긴 한국어·다수 목록·empty/error/offline·dirty전환·키보드 focus/scroll 회귀와 화면 대응표 갱신으로 확인한다.

## 2. Editor, tools and results

- [x] 2.1 D05 파일 블록의 좁은 inspector 대안, library/dialog/toolbar·속성 scroll을 구현한다. compact 선택/속성 수정·pan/zoom/fit/연결·sourceMap 불변 회귀 및 사용 안내로 확인한다.
- [x] 2.2 D06/D07 직접 문서·설정/미리보기·결과/PNG를 bounded viewport에 맞춘다. 큰 글자/긴 오류·원QA/snapshot 표시·결과 탐색 위젯 회귀와 문서로 확인한다.
- [x] 2.3 D08 terminal/AI와 결과의 높이 예산/대체 패널·접기·포커스를 정합한다. resize 중 PTY/문서 보존, terminal Delete/Ctrl+C 격리, 직접 문서 안정 파일 반영·dirty/stale충돌·합성 모드 보호 회귀와 명확한 도구 안내로 확인한다.

## 3. Backend context consumption

- [x] 3.1 검증된 counterpart Dart SDK의 getProjectContext를 연결한다. 역할 진입권한/최종 mutation 권한 구분, runtime 불일치·404/권한철회·늦은 응답·offline 로컬 사용 테스트와 문서로 확인한다.
- [x] 3.2 listSuitePins의 페이지 조회와 ordered case 재수신을 홈에 연결한다. 기존 pin/원본version/hash/사본 보존, 수정 후 귀속 해제·수신 자동run0·연결 교체 회귀와 안내로 확인한다.

## 4. Integrated acceptance and delivery

- [x] 4.1 전체 D01–D08 위젯 행렬(1440×900/1024×768/800×600/1280×500, text1/1.25/1.5)을 실행한다. 패널 geometry·필수 버튼·스크롤/focus·긴 내용·양 dock을 확인하고 DPI/text scaling 구분과 결과 파일을 기록한다.
- [x] 4.2 실제 Windows 창에서 홈→수신→블록/직접 편집→검증→명시 실행→PNG/결과, compact inspector/terminal/resize를 인수한다. 실제 Engine/서버 결과·alpha6 공유 불일치·로컬판정 보존·PTY fixture 파일 편집을 증거와 연결한다. 실제 Codex 모델 편집은 가능한 경우 추가하고 외부 조건 미인수는 별도 기록하며 UI 완료의 필수 게이트로 만들지 않는다.
- [x] 4.3 flutter analyze/영향 앱 회귀와 저장소 요구 검사, OpenSpec strict를 실행한다. 별도 alpha8 Release 전체 파일/source manifest·native launch·기존 Release/pin 보존을 확인하고 재현 명령/변경 목록/미완료 범위를 validation 및 앱 README에 기록한다.

## Workflow follow-up

- 관리자가 명세/계약·실제 화면·결과를 교차 검토한 후 인수한다. archive는 별도 시점이며 이 작업의 제품 완료 체크와 혼동하지 않는다.
