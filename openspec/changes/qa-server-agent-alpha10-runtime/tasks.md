# Tasks

관리 검토·strict 및 apply 승인 후 구현과 로컬 실제 인수를 완료했다. 근거는 `docs/validation-server-runtime-alpha10.md`와 `artifacts/runtime-alpha10/acceptance.json`에 기록한다. 실제 Agent/브라우저 인수는 앱 담당자의 heavy 실행 슬롯과 분리했다. 다른 PC/원격 운영 인수는 포함하지 않는다.

## 1. Runtime preparation

- [x] 1.1 서버/앱 소유 경계와 alpha6 보존·alpha10 pin을 관리 승인받고 strict 검증한다.
- [x] 1.2 서버 canonical manifest·분리 설치 helper·tamper/reuse 경계 검사를 구현하고 exact archive/설치 SHA를 검증한다.
- [x] 1.3 새 demo/admin 기본 runtime 및 새 identity/state를 정합하고 혼합 override·옛 등록 재사용을 거부한다.

## 2. Real integration

- [x] 2.1 실제 alpha10 Chromium 결과·PNG를 HTTP 게시/조회/다운로드하고 snapshot/권한/증거 경계를 검증한다.
- [x] 2.2 alpha6 데이터가 있는 동일 DB의 upgrade/restart 후 oldGET 보존과 newingestion mismatch·old Agent claim 거부를 검증한다.
- [x] 2.3 실제 alpha10 Agent의 Suite·제어 clock 예약·취소·delivery receipt·cleanup 및 process 종료를 인수한다.

## 3. Handoff

- [x] 3.1 기존 서버·contract/schema·repository 회귀와 legacy 파일/SDK 불변 hash를 확인한다.
- [x] 3.2 실행 절차·legacy/current 차이·실제 인수와 외부 미인수 범위를 기록하고 앱 담당자에게 최종 공유 가능 상태를 인계한다.
