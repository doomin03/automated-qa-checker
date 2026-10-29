# Tasks

이번 단계는 명세 작성만 완료한다. 아래는 제품 구현·인수 tasks이며 모두 미완료다. 기존 작업과의 소유권/공유 증거는 design D5를 따른다.

## 1. 공개 계약 소비

- [ ] 1.1 Engine counterpart의 reviewed 계약·preset/CLI·profile·reference/report 경로 fixture를 받아 소비 대응표와 미지원 사유를 문서화하고 양 저장소 계약 검토로 확인한다. 초안 이름을 Checker 정본 schema로 복제하지 않는다.
- [ ] 1.2 신규 기능을 포함한 실제 공개 Engine version/hash/capability를 고정하고 정상 fixture·변조 hash·미지원 엔진 검사를 통과한다. 현재 alpha.1 pin이나 alpha.2 독립 CLI 증거를 신규 기능 완료로 대체하지 않는다.

## 2. 로컬 기준과 프리셋 입력

- [ ] 2.1 MVVM/Provider에 로컬 PNG·수치 JSON·URL/profile·selector 매핑 입력을 추가하고 정상 입력/파일 누락/잘못된 형식/범위 밖 경로 검사를 통과한다. 로컬 사용 방법과 파일 한도를 기록한다.
- [ ] 2.2 공개 UX 팩 선택·필수 바인딩·XML 전개를 기존 scenario_editor에 연결하고 Engine round trip, 누락 back/입력 기대값, 미지원 실제 OS 키보드 검사를 통과한다. 합성 overlay fixture 한계를 UI와 안내에 표시한다.
- [ ] 2.3 기준 version/hash 및 실행 snapshot 연결을 구현하고 실행 중 기준 변경·새 기준 명시 선택 테스트로 과거 결과/기준 자동 덮어쓰기 없음을 확인한다.

## 3. 공유 CLI와 결과 화면

- [ ] 3.1 handoff3.2의 공유 bridge로 validate/plan을 연결하고 가져오기·팩 전개·검증만으로 브라우저 실행이 발생하지 않는 테스트를 통과한다. 정확 CLI 인자와 오류 안내를 기록한다.
- [ ] 3.2 flow-editor2.4/handoff3.3의 공유 bridge로 명시 run/cancel을 연결하고 중복 실행·cancel 요청/종료·비정상 종료·dispose 후 갱신 테스트를 통과한다. shell 문자열 실행은 사용하지 않는다.
- [ ] 3.3 flow-editor2.5의 공유 Run 화면에 단계·측정값·baseline/actual/diff 경로를 표시하고 run/attempt/snapshot 불일치, 누락 최종 결과, artifact 경로 이탈 테스트를 통과한다.
- [ ] 3.4 비교 불가/미지원/환경오류와 실제 failed를 구분하고 사용자 검토 상태가 outcome을 바꾸지 않는 테스트를 통과한다. 표시 규칙과 제공되지 않은 증거의 한계를 문서화한다.

## 4. 실제 제품 인수

- [ ] 4.1 실제 웹에서 시각 PASS/의도적 FAIL 및 back/focus/input/overlay 팩을 실행하고 Engine 결과·측정·증거를 대조한다. profile/hash mismatch·지원되지 않는 검사·취소도 기록하고 CLI 증거와 Desktop 증거를 구분한다.
- [ ] 4.2 서버 없는 Flutter에서 기준 입력→팩 매핑/XML→validate/plan→실행→결과·취소 사용자 경로를 실제 검증하고 flutter analyze/test 및 Windows release build를 통과한다. native 창 초기화 smoke만으로 완료하지 않는다.
- [ ] 4.3 변경 범위의 Checker verify와 OpenSpec strict를 통과하고 재현 명령·artifact/version/hash·기능 한계 및 기존 tasks별 공유 인수 증거를 기록한다. 서버/Appium/전체 builder를 완료 처리하지 않는다.

## Workflow follow-up

- 관리 검토와 구현 할당 후 apply를 시작한다. 모든 실제 인수 이후에만 기준 spec 반영/archive를 검토한다.
