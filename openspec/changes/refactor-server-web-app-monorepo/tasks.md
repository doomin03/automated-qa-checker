# Tasks

원본 tasks 1~7의 번호를 유지한 QA 대응 목록이다. 문서 이관만으로 구현 task를 체크하지 않는다. 과거 검증은 [integration.md](integration.md)의 소유 change에서 재사용하되 각 범위가 전부 충족될 때만 이 인수표에 증거를 연결한다. 현재는 관리 명세 검토 후 구현 재할당을 기다린다.

## 1. 기준선과 도구 확정

- [ ] 1.1 현재 QA checkout의 frozen install/build/dev와 Blueprint 재생 기준선을 기록하고 실제 브라우저 재현 절차를 확인한다. 과거 이관 전 증거와 새 중간 수정의 미검증 상태를 구분한다.
- [ ] 1.2 QA 엔진 공개 계약·version/hash·CLI·adapter 지원을 Engine 담당 인계와 대조하고 소유 경계 표 및 검증 증거를 기록한다.
- [ ] 1.3 Node/pnpm/Turbo/React/Router/Nest/TS/Flutter/Dart/Java/generator 호환 버전을 고정하고 작은 build/generate/analyze로 확인한다.
- [ ] 1.4 OpenAPI3.0.3 required/optional/nullable/enum/error fixture로 typescript-fetch/dart-dio spike를 수행하고 양 SDK compile/analyze 및 직렬화 증거를 남긴다.

## 2. Workspace 기반

- [ ] 2.1 apps/server, apps/web와 JS 공용 packages를 활성화하고 pnpm 명시 목록이 의도한 package만 포함하는지 검사한다. Dart/외부engine 제외를 검증한다.
- [ ] 2.2 기존 web entry/assets/config를 보존해 QA 사용자 화면의 dev/production build가 기준선 문서·이벤트 관찰을 유지하는지 확인한다.
- [ ] 2.3 현 pnpm lockfile을 보존하고 깨끗한 설치 환경에서 frozen install을 재현한다. 원본 npm→pnpm 삭제 작업은 QA에 불필요하므로 파일을 제거하지 않는다.
- [ ] 2.4 root build/lint/check-types/test/dev와 앱별 명령을 연결하고 Flutter 없는 JS 실행 및 persistent cache:false/실패 전파를 검사한다.
- [ ] 2.5 Windows 명령과 public export 경계를 문서화하고 cross-app/deep import/동일 FSD layer cross-slice 위반 검사를 통과한다.

## 3. React 사용자 QA 앱

- [ ] 3.1 독립 Engine 공개 계약 artifact를 소비하고 source copy/submodule/커밋된 외부경로 의존 없이 schema/fixture 검증이 성공함을 확인한다.
- [ ] 3.2 React SPA/FSD QA route와 공개 slice 경계를 연결하고 역방향·cross-slice 위반 및 route 인수를 검증한다.
- [ ] 3.3 비동기 파일/요청 및 구독 취소를 검증하여 문서 교체와 StrictMode 재mount에서 이전 응답이 최신 상태를 덮어쓰지 않음을 확인한다.
- [ ] 3.4 관찰 timer/listener/observer의 반복 cleanup과 route 왕복·resize에서 자원/이벤트 누적이 없음을 실제 browser로 검증한다.
- [ ] 3.5 공용·사용자 정의 Blueprint/XML 전달과 서버 없이 로컬 이벤트 관찰을 확인하고 shell/자동실행 및 AI판정 PASS가 없음을 검증한다. XML 첫 slice 증거는 qa-user-web-desktop-handoff에서 연결한다.
- [ ] 3.6 사용자 앱·관리자 권한업무·Desktop 실행 역할을 문서와 화면에 일치시키고 XML/진행 파일 전달과 후속 서버 자동전달 범위를 인수표에 구분한다.

## 4. Nest와 공개 계약

- [ ] 4.1 server config/common/modules/health 구조를 생성하고 isolated build 및 health controller/service 테스트를 통과한다.
- [ ] 4.2 /api/v1, 명시 query conversion, ValidationPipe, requestId/error filter를 구성하고 정상/invalid enum/unknown/repeated query의 200/400 E2E를 검증한다.
- [ ] 4.3 getHealth DTO/operationId 및 200/400/500과 API404 schema를 정의하고 client 생략=null/web/app·공용 오류 JSON을 실제 schema에 대조한다.
- [ ] 4.4 production Swagger metadata와 동일 compilation의 offline exporter를 구현하고 외부 자격증명/DB/listener 없이 prefix/schema가 동일한지 검증한다.
- [ ] 4.5 테스트 전용 module로 body/path/query/nullable/optional/numeric/time/list/error fixture를 검증하고 production document에 시험 endpoint가 없음을 확인한다.
- [ ] 4.6 서버 endpoint·설정·오류 문서를 작성하고 curl 예시와 실제 HTTP 결과를 대조한다. health bootstrap을 P3 OIDC/Registry 완료로 기록하지 않는다.

## 5. SDK 생성과 웹 소비

- [ ] 5.1 정렬된 OpenAPI/fixture/generator version·JAR checksum·옵션을 추가하고 duplicate operationId/broken ref 거부를 검증한다.
- [ ] 5.2 contract:generate의 server build/export→TS/Dart generation→필요 build_runner 순서를 구현하고 같은 입력의 연속 두 출력이 동일함을 확인한다.
- [ ] 5.3 생성 TS client를 web shared/api와 domain adapter에 연결하고 endpoint/model 중복 없이 health 성공/실패 UI를 검증한다.
- [ ] 5.4 API error/timeout/transport error와 unknown 추가 response field의 호환성을 client adapter 테스트로 검증한다.
- [ ] 5.5 contract:check 격리 재생성을 구현하고 수동수정·누락·신규 untracked·삭제·미생성을 모두 감지하며 working tree를 수정하지 않는지 검사한다.
- [ ] 5.6 계약 변경·SDK import 경계를 문서화하고 server의 generated SDK 역참조 거부 및 독립 Engine의 HTTP 비의존 증거를 확인한다.

## 6. Flutter Desktop

- [x] 6.1 기존 apps/app에 기능별 MVVM/Provider Windows 앱을 생성하고 SDK/provider/pubspec.lock 고정 후 pub get/analyze, VM 상태·비동기 dispose·widget 연동 tests 및 Windows build/서버 없는 앱 실행을 통과한다. 생성 담당은 qa-flow-editor 2.1과 하나로 묶는다. 근거: docs/validation.md의 MVVM shell 검증.
- [ ] 6.2 generated api_client_dart를 같은 저장소 local path dependency로 연결하고 TS source 비의존 및 Dart package analyze/test를 확인한다.
- [ ] 6.3 API_BASE_URL origin 검증·Dio 구성·repository model mapping을 구현하고 중복 /api/v1 및 missing/malformed config와 로컬 모드 독립성 테스트를 통과한다.
- [ ] 6.4 health loading/success/API error/transport failure/retry UI를 구현하고 widget test에서 상태 및 단일 retry 요청을 검증한다.
- [ ] 6.5 Windows Desktop 실제 앱에서 server 호출·서버 종료/재시작 retry를 검증하고 주소·실행 로그를 문서화한다. Windows build artifact와 실행 증거가 없으면 미완료다.
- [ ] 6.6 root dev:app/app:analyze/app:test/app:build wrapper를 구현하고 Windows 인자 전달·build 성공·SDK 누락 시 명확한 실패를 검증한다.

## 7. 통합 인수

- [ ] 7.1 생성 TS/Dart SDK가 같은 실제 server health를 호출하고 정상/오류 fixture의 HTTP status와 의미가 동일함을 확인한다.
- [ ] 7.2 수용된 base branch schema 대비 breaking diff gate를 구현하고 삭제/type/required/nullable/operationId/enum 변경 및 unknown 추가 필드를 검증한다.
- [ ] 7.3 JS/contract/Flutter CI와 verify:all을 구성하고 drift/build/type/lint/test/Dart analyze/test/Windows build 실패가 전파되는지 확인한다.
- [ ] 7.4 web/server production artifact와 QA deep-link를 검증하고 missing API/asset이 index.html200으로 바뀌지 않는지 확인한다.
- [ ] 7.5 담당 changes의 중복 작업·완료 범위를 대조하고 baseline/ADR과 각 spec scenario의 실제 증거를 연결한다. 실행결과·업무상태·미실행 및 Appium 미지원 표기를 확인한다.
- [ ] 7.6 새 설치 환경에서 문서 순서대로 설치/dev/generate/전체검증을 재현하고 OpenSpec strict를 통과한다.

## Workflow follow-up

- 관리 검토 뒤 소유자별 제품 작업을 할당한다. 현재 문서 이관 단계에서 구현을 재개하지 않는다.
- 전체 인수와 사용자 Git 권한 범위를 확인한 뒤 sync/archive를 검토한다. 자동 commit/push/merge는 수행하지 않는다.
