# Tasks

## 1. 프로젝트 컨텍스트

- [x] 1.1 관리 설계 승인 후 context DTO/service/controller를 구현하고 HTTP role/401/403/metadata·secret 미노출·무실행 테스트로 확인한다.
- [x] 1.2 context의 action 진입권한·archive pin 의미·alpha.6/alpha.8 호환 분리를 docs/architecture/product-backend-context.md에 명시하고 기존 자기 검토/runtime 거부 회귀로 확인한다.

## 2. 고정 목록과 업무 회원 조회

- [x] 2.1 GET Suite pins를 구현하고 개인/프로젝트 격리·bounded cursor·재시작·구버전 보존 HTTP 테스트로 확인한다.
- [x] 2.2 manager members 조회를 구현하고 역할·active 프로젝트 scope·limit/cursor·최소 필드 및 기존 assignee membership/revision 테스트로 확인한다.
- [x] 2.3 D/W/A endpoint 대응과 6상태축·후속 범위를 architecture 문서에 기록하여 앱 소비 범위와 대조한다.

## 3. 계약 및 생성 SDK

- [x] 3.1 서버 build 후 OpenAPI/TS/Dart SDK를 정식 generator로 생성하고 contract check/compatibility 및 SDK build/analyze로 검증한다.
- [x] 3.2 새 response DTO serialization/실제 HTTP 계약을 검사하고 확정 operation/DTO를 Flutter 담당자에게 인계한다.

## 4. 통합 인수

- [x] 4.1 서버 전체 테스트와 관련 contract/경계 검사를 실행하고 docs/validation-product-backend-context.md에 실제 명령·결과·제약을 기록한다.
- [x] 4.2 OpenSpec strict 및 변경 소유권/Engine pin 불변 검사를 마치고 관리 검토에 실제 증거를 제출한다.
