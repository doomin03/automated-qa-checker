# Tasks

## 1. P0 기획과 구조

- [x] 1.1 실제 저장소·참조 branch·도구 현황과 제약을 문서화한다.
- [x] 1.2 역할 경계·계약 초안·counterpart·인수 시나리오를 작성한다.
- [x] 1.3 고정 dependency 설치와 foundation/OpenSpec strict 검증 결과를 기록한다. 근거: docs/validation.md.

## 2. P2 구현 및 인수 — MVVM shell 완료, 제품 기능 미완료

- [x] 2.1 Flutter/Dart/Windows toolchain과 provider 버전을 검증·고정하고 apps/app의 기능별 MVVM shell을 생성한다. analyze/상태·생명주기/widget tests 및 Windows build와 실제 실행 증거를 상위 모노레포 6.1과 공유한다. 근거: docs/validation.md.
- [ ] 2.2 engine 검증 release/version/hash를 pin하고 schema/fixture를 소비한다.
- [ ] 2.3 TC/Flow CRUD, drag/drop node editor, branch/settings, undo/redo와 validation을 구현한다.
- [ ] 2.4 capability/device picker 및 argument-array CLI bridge를 구현한다.
- [ ] 2.5 event/result/artifact 경로 검증과 run view/취소를 구현한다.
- [ ] 2.6 UI round-trip contract test와 실제 engine web PASS/FAIL 통합을 실행한다.

## 3. 완료 처리

- [ ] 3.1 실제 검증 증거를 연결하고 미완료 기능이 없는지 확인한 뒤 기준 spec sync/archive를 수행한다.

