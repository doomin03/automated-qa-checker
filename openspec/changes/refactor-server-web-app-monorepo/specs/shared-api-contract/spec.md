# Shared API Contract

## Purpose

서버와 웹 및 Flutter 앱이 동일한 HTTP 요청·응답·오류 의미를 사용하도록 공개 계약을 관리한다. 언어마다 수작업 모델이 달라지는 문제를 막고 생성 결과와 실제 서버 응답의 일치를 검증한다.

## ADDED Requirements

### Requirement: One editable HTTP contract source
공개 endpoint의 path/method/query/body/status/response/error는 하나의 작성 원본에서 OpenAPI로 내보내고 TypeScript와 Dart 소비자를 생성하도록 SHALL 관리한다. 생성 결과의 직접 편집은 계약 변경 절차로 인정하지 않는다.

#### Scenario: Change an API field
- **WHEN** 작성 원본에서 공개 필드의 type 또는 required 의미를 변경하고 생성 명령을 실행한다
- **THEN** OpenAPI와 양 언어 SDK에 같은 변경이 반영되며 웹/앱에 수동 transport model을 중복 선언하지 않는다.

#### Scenario: Export without application infrastructure
- **WHEN** 외부 데이터 서비스 자격증명과 실행 중 서버가 없는 환경에서 export한다
- **THEN** network listener나 외부 서비스 초기화 없이 production과 동일한 API prefix/DTO 계약을 생성한다.

### Requirement: Stable bootstrap health contract
서버는 GET /api/v1/health를 operationId getHealth로 제공하고 optional query client를 web 또는 app으로 제한하도록 SHALL 동작한다. 200 응답은 required status=ok, service=automated-qa-checker, apiVersion=v1, nullable client를 포함한다.

#### Scenario: Identify a web or app request
- **WHEN** 생성 client가 client=web 또는 client=app으로 health를 호출한다
- **THEN** 서버는 200을 반환하며 client는 요청한 값이고 나머지 required 필드는 정의된 값이다.

#### Scenario: Omit an optional query
- **WHEN** client query 없이 health를 호출한다
- **THEN** 서버는 200을 반환하고 response의 client 필드는 생략되지 않고 null이다.

#### Scenario: Reject malformed query
- **WHEN** client=desktop, client 빈 문자열, 반복 client 또는 알 수 없는 query를 전송한다
- **THEN** 서버는 400 VALIDATION_ERROR를 반환하며 성공 응답으로 처리하지 않는다.

### Requirement: Runtime input and output agreement
서버는 공개 입력을 런타임에서 검증하고 실제 JSON 출력이 명세와 일치함을 계약 검증으로 확인하도록 SHALL 구성한다. 컴파일 시 타입 호환성만으로 이 요건이 충족된 것으로 간주하지 않는다.

#### Scenario: Invalid request values
- **WHEN** 계약 테스트에서 잘못된 enum/범위/형식의 query, path 또는 body가 입력된다
- **THEN** 서버는 문서화된 validation error를 반환하고 유효하지 않은 입력으로 도메인 작업을 실행하지 않는다.

#### Scenario: Server response diverges from schema
- **WHEN** 실제 응답에서 required 필드가 빠지거나 field type이 OpenAPI와 다르다
- **THEN** schema 기반 e2e 검사가 실패하여 단순 TS cast로 차이를 숨기지 못한다.

### Requirement: Cross-language JSON semantics
공개 계약은 required/optional/nullable, enum, UTC 시간, 식별자, 숫자 범위 및 collection의 의미를 명시하고 양 언어에서 동일하게 해석하도록 SHALL 정의한다.

#### Scenario: Null and omission fixtures
- **WHEN** TS/Dart client가 nullable required, omitted optional, 실제 값 fixture를 직렬화하거나 역직렬화한다
- **THEN** 계약이 허용한 의미가 보존되고 required 필드 누락을 정상 nullable 값으로 조용히 취급하지 않는다.

#### Scenario: Numeric and timestamp boundaries
- **WHEN** 숫자·시간 필드를 포함하는 테스트 계약의 fixture를 검증한다
- **THEN** non-finite number가 거부되고 안전 정수 범위 초과 값은 계약상 string이며 UTC 시간 표현이 양 언어에서 일치한다.

### Requirement: Consistent error contract
모든 /api/v1 JSON 실패는 HTTP status를 유지하면서 required code/message/requestId/details를 갖는 ApiErrorResponse를 SHALL 반환한다. details 항목은 field/code/message로 구성되며 내부 오류 정보는 노출하지 않는다.

#### Scenario: Validation failure
- **WHEN** health 요청의 client 값이 허용되지 않는다
- **THEN** 400과 VALIDATION_ERROR, field detail을 반환하며 응답 header와 body 및 서버 로그의 requestId가 일치한다.

#### Scenario: Not found or unexpected server failure
- **WHEN** API 경로가 존재하지 않거나 처리 중 예상하지 못한 오류가 발생한다
- **THEN** 각각 404 NOT_FOUND 또는 500 INTERNAL_ERROR와 공용 오류 body를 반환하며 stack 또는 HTML SPA를 반환하지 않는다.

#### Scenario: Network failure is not an API error
- **WHEN** client가 timeout 또는 연결 실패로 HTTP response를 받지 못한다
- **THEN** adapter는 이를 transport failure로 구분하고 존재하지 않는 서버 status/code를 만들어 내지 않는다.

### Requirement: Compatible public contract evolution
v1의 공개 계약 변경은 수용된 이전 계약과 비교하여 구버전 Desktop·웹 소비자에 대한 영향을 검사하도록 SHALL 관리한다.

#### Scenario: Breaking change in current version
- **WHEN** 공개 필드 삭제/rename/type/required/nullability/status/operationId 또는 enum 호환성을 깨는 변경이 발생한다
- **THEN** 호환성 gate가 실패하고 새 버전·병행 지원 계획 없이는 수용하지 않는다.

#### Scenario: Add an optional response property
- **WHEN** 기존 필드를 유지하면서 optional response property를 추가한다
- **THEN** 구버전 fixture와 소비자 검증으로 unknown property 처리 및 기존 요청/응답 성공을 확인한다.
