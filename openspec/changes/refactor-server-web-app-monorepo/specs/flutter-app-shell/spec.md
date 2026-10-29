# Flutter App Shell

## Purpose

Flutter 앱을 같은 저장소의 독립 실행 단위로 제공하고 공용 OpenAPI에서 생성한 Dart SDK로 서버에 연결한다. 별도 QA 엔진을 CLI로 소비하는 Desktop 화면과 환경 설정을 통해 실제 교차 클라이언트 동작을 확인한다.

## ADDED Requirements

### Requirement: Feature scoped MVVM state management
Flutter SHALL 기능별 Model/View/ViewModel과 Repository/Service 경계를 사용하고 Provider를 통해 상태와 의존성을 제공한다. View는 상태를 표시하고 액션을 요청하며 IO와 실행 의미를 직접 구현하지 않는다.

#### Scenario: View model state propagation
- **WHEN** 사용자가 초안을 편집하거나 로컬 저장 액션의 성공·실패를 받는다
- **THEN** immutable 모델과 ViewModel 상태가 바뀌어 관찰하는 View에 반영되고 저장 실패를 성공으로 표시하지 않는다.

#### Scenario: Provider lifecycle
- **WHEN** 비동기 작업 중 ViewModel을 소유한 화면이 해제된다
- **THEN** 완료 콜백이 해제된 상태에 notify하지 않으며 Provider가 생성한 ViewModel과 View의 controller가 정리된다.

### Requirement: Native application and generated API dependency
apps/app은 Flutter 앱으로 실행되며 local Dart API package를 통해 서버에 접근하도록 SHALL 구성한다. TypeScript source 또는 엔진 내부 객체의 직접 공유를 요구하지 않는다.

#### Scenario: Resolve and analyze desktop dependencies
- **WHEN** 고정 Flutter SDK로 앱 의존성을 설치하고 분석한다
- **THEN** local api_client_dart package가 해석되고 앱 및 SDK의 Dart 분석이 성공한다.

#### Scenario: Keep transport details outside presentation
- **WHEN** health 화면을 구현하거나 테스트한다
- **THEN** presentation은 repository/domain 결과를 사용하고 Dio와 generated transport model의 세부사항은 data/network 계층에 한정된다.

### Requirement: Explicit environment-specific API origin
Flutter 앱은 실행 환경에서 제공한 API origin을 검증하고 문서화된 endpoint 경로와 결합하도록 SHALL 동작한다.

#### Scenario: Connect from Windows Desktop
- **WHEN** API_BASE_URL을 http://127.0.0.1:3000으로 설정하고 로컬 server가 준비되어 있다
- **THEN** 앱이 /api/v1/health?client=app으로 요청하여 성공 결과를 표시한다.

#### Scenario: Missing or malformed origin
- **WHEN** API_BASE_URL이 없거나 유효한 HTTP(S) origin이 아니다
- **THEN** 앱은 명확한 설정 오류를 표시하고 잘못된 URL로 무한 재시도하지 않는다.

#### Scenario: Production network policy
- **WHEN** production 배포 설정으로 앱을 빌드한다
- **THEN** HTTPS origin을 사용하고 개발용 cleartext 허용이 release 설정에 포함되지 않는다.

#### Scenario: Use local QA without server
- **WHEN** 서버 API를 설정하지 않고 로컬 테스트 개발 모드를 연다
- **THEN** HTTP 기능의 설정 부족만 표시하고 로컬 문서 편집과 호환 엔진 실행을 막지 않는다.

### Requirement: Observable health request lifecycle
Desktop health 화면은 loading/success/API failure/transport failure와 사용자 재시도를 구분하여 SHALL 표시한다.

#### Scenario: Successful request
- **WHEN** 화면이 health를 요청하고 서버가 정상 response를 반환한다
- **THEN** loading 후 service/apiVersion/client 값을 정상 상태로 표시한다.

#### Scenario: Request fails and user retries
- **WHEN** API error 또는 연결 실패가 발생한 뒤 사용자가 retry를 선택한다
- **THEN** 실패 종류에 맞는 상태에서 새 요청을 한 번 시작하고 복구 시 정상 화면으로 전환한다.

### Requirement: Concrete desktop acceptance target
이번 변경은 Windows Desktop의 실제 API 연결과 Windows Desktop build를 완료 조건으로 SHALL 삼으며 Appium 실기기 지원을 완료 조건으로 주장하지 않는다.

#### Scenario: Verify app delivery
- **WHEN** 리팩터링 완료 검토를 수행한다
- **THEN** Windows Desktop artifact와 Desktop의 실제 server 호출 증거가 있고 fixture-only test를 실제 연결 검증으로 대체하지 않는다.

### Requirement: Separate local test development from HTTP transport
Desktop SHALL 블록/Flow 또는 XML으로 개별 테스트를 작성하고 고정 엔진 CLI에 명시 실행을 요청한다. XML은 외부 표현이며 파싱·schema/graph 검증·실행계획·adapter 제어는 엔진 책임이다.

#### Scenario: Author and run a test
- **WHEN** 사용자가 블록 또는 XML으로 테스트를 만들고 검증 후 실행한다
- **THEN** engine가 동일 선언형 의미를 실제 실행하며 JSONL 진행·결과·증거를 표시한다. XML 편집만 제공한 상태는 전체 블록 편집 완료가 아니다.

#### Scenario: Import without execution
- **WHEN** 웹에서 받은 XML을 열거나 사용자 XML을 붙여넣고 저장·검증한다
- **THEN** 테스트를 자동 실행하지 않으며 임의 shell 스크립트를 실행 액션으로 허용하지 않는다.
