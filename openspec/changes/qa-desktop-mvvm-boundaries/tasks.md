# Tasks

## 1. 설정과 소유권

- [x] 1.1 immutable 실행 설정·Provider VM·문서 revision을 구현하고 값 변경/같은 값/재마운트 보존 테스트로 확인한다.
- [x] 1.2 composition root의 기본 생성·외부 borrowed 소유권과 VM 구독 정리를 구현하고 하위 소비자 제거/전체 scope 종료/외부 주입 exactly-once 테스트 및 소유권 문서를 추가한다.

## 2. 작업 공간과 화면

- [x] 2.1 coordinator의 명시 액션과 문서·설정·작업 generation guard를 구현하고 대기 중 편집/설정 변경/원문 원복/dispose 회귀로 늦은 결과 적용을 거절한다.
- [x] 2.2 상위 workbench 화면과 작은 Run 설정·진단·결과 View를 구성하고 원문 정본 projection·재마운트·기존 버튼/입력 Provider widget 인수 및 feature→app 역참조 없음을 확인한다.
- [x] 2.3 Shared/Auth/Flow의 기능 간 조합을 명시 coordinator 명령으로 옮기고 인증된 연결/수신·자동실행 없음/Flow 원문 적용 기존 회귀와 구조 안내를 정합한다.

## 3. 통합 인수

- [x] 3.1 Flutter analyze/전체 test 및 실제 CLI validate-run-cancel·디자인/공유 사용자 경로를 통과하고 Engine/HTTP pin 불변을 확인한다.
- [x] 3.2 별도 Windows Release build·전체 파일 hash·직접 시작한 프로세스 smoke와 OpenSpec strict/foundation을 통과하고 기존 사용자 PID·stable Release 보존 및 재현 경로를 기록한다.

2026-10-31 인수: analyze/최종 고정 source Flutter29개/Windows native 서버 재시작1개/Release52초/14파일 hash·창 초기화 PASS. feature33개 Dart 파일의 app 역참조 없음, 기존 모노레포 경계7개 PASS. 상세 실패 이력과 최종 증거는 [검증 기록](../../../docs/validation.md), 구조·소유권은 [MVVM 안내](../../../docs/architecture/flutter-mvvm.md)를 따른다. 이전 stable·계약 pin 보존, 새 경로는 `artifacts/releases/alpha6-mvvm/Release`다.

## Workflow follow-up

- 관리 검토 뒤 기준 spec 반영/archive를 검토한다. 기존 변경을 보존하고 commit/push하지 않는다.
