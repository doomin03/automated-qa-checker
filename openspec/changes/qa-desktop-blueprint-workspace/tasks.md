# Tasks

## 1. Desktop 작업 공간

- [x] 1.1 이전 목업 checksum과 공개 XML fixture 출처를 기록하고 별도 blueprint-workspace 파일을 만든다. 기존 인수 bytes 보존을 검증한다.
- [x] 1.2 프로젝트/QA 목록과 차콜 도킹 작업 공간·접기·내부 스크롤을 구현하고 1440×900/1024×768 탐색과 첫 캡처로 검증한다.
- [x] 1.3 단일 XML 모델·node 참조·graph/XML 선택·팬/줌을 구현하고 미지원/잘못된 XML 원문 보존 및 stale graph 미표시 회귀를 통과한다.

## 2. AI 제안과 실행 상태

- [x] 2.1 선택 수정/edge 기준 앞·뒤 삽입/현재 모델 기반 전체 변경의 예시 제안을 구현한다. 네 범위 preview/apply/cancel/undo와 결과 XML을 브라우저 및 공개 CLI validate/plan 비실행 검사로 검증한다.
- [x] 2.2 문서/revision/선택 context의 stale 제안을 거절하고 변경 후 재검증·자동 실행 0회, ambiguous branch/start/end 삽입 거부를 회귀한다.
- [x] 2.3 실행 snapshot별 node 진행·하단 로그/타임라인·명시 실행·중단을 구현한다. 실행 중 편집/QA전환 잠금과 변경 후 old run overlay 제거, 실패/환경 오류/미실행 구분을 검증한다.
- [x] 2.4 제공자 password 입력·표시/숨김·연결/해제를 구현하고 가짜 값으로만 인수한다. 외부 HTTP·영속 저장 API 0회 및 새로고침 초기화를 실제 브라우저로 검증한다.

## 3. 검토 인수

- [x] 3.1 프로젝트/QA 목록·Blueprint/XML·AI 네 범위·키 설정·진행/실패·좁은 창 캡처와 검증 JSON을 저장하고 관리 시각 검수를 받는다.
- [x] 3.2 한국어 UX/실행 안내/지원 XML subset/실제 제품 대비 한계와 기존 목업 링크를 문서화하고 OpenSpec strict를 통과한다.

## Workflow follow-up

- 명세 strict 후 조건부 apply 승인 수신. 첫 작업 공간 캡처를 기능 전체 인수 전에 관리 에이전트에 전달한다.
- 제품 이식·실제 AI/키 저장·원격 게시·commit/push는 수행하지 않는다.

## Acceptance

`node design/mockups/desktop/blueprint-workspace/verify.mjs`: 30검사 PASS, 공개 CLI validate/plan 10회 PASS(run 0), 캡처 14개. 외부 HTTP·영속 저장 API·페이지 오류 0. 이전 목업 19파일 SHA 보존 확인. 1024 접기에서 발견한 grid 자동 배치 겹침을 명시적 열/행으로 수정하고 실제 패널 bounding box·최소 canvas 너비·fit node 가시성 회귀를 통과했다. 관리자가 최신 프로젝트/QA/1440 Blueprint·AI/키/실행 및 1024 접기·펼치기 캡처를 직접 검토해 인수했다.

사용 안내·지원 subset·제약: `design/mockups/desktop/blueprint-workspace/README.md`, `UX.md`. 실제 결과는 같은 폴더 `verification.json`, CLI 입력은 `evidence/*.xml`, 캡처는 `screenshots/`에 보존한다. 첫 시안 `first-workspace.png`는 중간 디자인 기록이며 최종 인수는 verification의 14개 캡처를 따른다.
