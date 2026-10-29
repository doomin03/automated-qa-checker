# Tasks

## 1. 역할과 계약

- [ ] 1.1 README/AGENTS/설계/진행 OpenSpec의 사용자 웹·Desktop 역할을 정정하고 strict 검증한다.
- [ ] 1.2 Engine alpha.2 공개 artifact version/hash를 고정하고 계약 검사와 round trip으로 확인한다.

## 2. 사용자 웹

- [ ] 2.1 편집 Blueprint의 XML 내보내기를 구현하고 engine import round trip 및 실제 browser 다운로드 테스트를 통과한다.
- [ ] 2.2 웹→Desktop 파일 전달 및 결과→웹 관찰 안내를 구현하고 브라우저 인수에서 자동 실행 없음을 확인한다.

## 3. Flutter Desktop

- [x] 3.1 정확 Flutter SDK/내장 Dart/Windows 도구를 기록하고 기존 apps/app의 MVVM/Provider shell을 생성하여 analyze와 widget test를 실행한다. 상위 모노레포 6.1/qa-flow-editor2.1과 같은 shell 증거이며 엔진 통합은 포함하지 않는다. 근거: docs/validation.md.
- [ ] 3.2 XML 원문 붙여넣기·파일 열기·편집·저장 및 CLI validate/plan을 구현하고 잘못된 입력/버전/실행 없는 검증 테스트를 통과한다.
- [ ] 3.3 명시 CLI run과 JSONL/결과 표시를 구현하고 실제 엔진 PASS/FAIL 및 비정상 종료 검증을 수행한다.
- [ ] 3.4 XML/엔진 통합 제품의 Windows Desktop build 성공과 실제 실행을 검증하고 시작 명령·증거를 문서화한다. shell build만으로 완료하지 않으며 toolchain 제약/실패만 확인한 경우 미완료로 유지한다.

## 4. 통합 인수

- [ ] 4.1 전체 JS verify, Flutter 검사, 사용자 정의 XML 실제 실행 증거와 미완료 drag/drop/서버/Appium 한계를 기록한다.
