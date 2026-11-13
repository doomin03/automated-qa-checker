# Tasks

## 1. P0 기획과 구조

- [x] 1.1 실제 저장소·참조 branch·도구 현황과 제약을 문서화한다.
- [x] 1.2 역할 경계·계약 초안·counterpart·인수 시나리오를 작성한다.
- [x] 1.3 고정 dependency 설치와 foundation/OpenSpec strict 검증 결과를 기록한다. 근거: docs/validation.md.

## 2. P2 구현 및 인수 — 개별 작업별 실제 증거

- [x] 2.1 Flutter/Dart/Windows toolchain과 provider 버전을 검증·고정하고 apps/app의 기능별 MVVM shell을 생성한다. analyze/상태·생명주기/widget tests 및 Windows build와 실제 실행 증거를 상위 모노레포 6.1과 공유한다. 근거: docs/validation.md.
- [x] 2.2 engine 검증 release/version/hash를 pin하고 schema/fixture를 소비한다.
- [x] 2.3 TC/Flow CRUD, drag/drop node editor, branch/settings, undo/redo와 validation을 구현한다.
- [x] 2.4 capability/device picker 및 argument-array CLI bridge를 구현한다. 실제 public CLI Provider 테스트에서 Chromium target과 native 정적 지원·미연결 상태를 구분했다.
- [x] 2.5 event/result/artifact 경로 검증과 run view/취소를 구현한다.
- [x] 2.6 UI round-trip contract test와 실제 engine web PASS/FAIL 통합을 실행한다.

- [x] 2.7 alpha.5 공개 expand로 반복 폼·직접 authoring XML을 전개하고 원본/sourceMap hash·회차 표시·편집 후 무효화를 실제 CLI로 인수한다. capture/optional screenshot 계약도 소비한다.

## 3. 완료 처리

- [ ] 3.1 실제 검증 증거를 연결하고 미완료 기능이 없는지 확인한 뒤 기준 spec sync/archive를 수행한다.


2026-10-31 인수 근거: docs/validation.md의 로컬 CLI·블록·웹 XML·서버 기반 인수 및 apps/server/VALIDATION.md. 미체크 항목은 부분 구현/후속 검증으로 유지한다.

2026-10-31 alpha.5 인수 근거: docs/validation.md 및 artifacts/flutter-design/verification.json, flutter-design-ui/ui-verification.json, flutter-authoring/verification.json, flutter-shared/verification.json, flutter-shared-ui/verification.json, shared-web-verification.json. 전체 서버 OIDC/Agent/Suite/예약 인수와 구분한다.
