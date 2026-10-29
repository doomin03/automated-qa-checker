# Design

## Context

원본 MD가 지정한 scratch-3d 로컬 `origin/feature`의 모노레포 OpenSpec을 QA에 이관한다. 원본과 후속 checkout의 SHA·파일 대응은 [integration.md](integration.md)에 기록한다. 원본을 이동·삭제하거나 게임 소스를 복사하는 작업이 아니다.

Checker에는 이미 pnpm/Turbo, React Blueprint 화면, 공개 엔진 계약 소비가 있다. Nest와 Flutter 앱은 아직 생성되지 않았다. 이관 시점의 웹 XML serializer 변경은 미검증 중간 작업으로 보존하며 구현 완료의 근거로 쓰지 않는다. 이번 이관 후 관리 에이전트가 전체 명세를 검토하기 전 제품 구현을 재개하지 않는다.

## Goals / Non-Goals

원본의 세 앱·공통 API·생성 SDK·도구·인수 기준을 보존하되 QA 원본 MD 및 최신 사용자 역할에 맞춘다. Engine interpreter/driver를 Checker에 구현하지 않는다. 계정/RBAC/registry/예약 제품 기능은 qa-platform-services, 전체 블록 builder는 qa-flow-editor, XML 첫 전달은 qa-user-web-desktop-handoff가 소유한다.

## Decisions

### D1. 세 앱과 공통 패키지

```text
automated-qa-checker/
  apps/server/src/{config,common/errors,modules/health}/
  apps/server/scripts/export-openapi.ts
  apps/web/src/{app,pages,widgets,features,entities,shared}/
  apps/app/lib/{app,core/config,core/network,features}/
  apps/app/{test,integration_test,windows,pubspec.yaml,pubspec.lock}
  packages/contract/{openapi.json,fixtures,generator,generated/engine-contract.json}
  packages/api-client/
  packages/api_client_dart/
  packages/typescript-config/
  scripts/  openspec/  docs/
```

목표 구조이며 현재 모든 파일이 존재한다는 뜻이 아니다. pnpm 명시 목록은 server/web/contract/api-client/typescript-config만 포함한다. Dart는 pnpm에서 제외하고 root wrapper가 apps/app cwd와 인자·종료코드를 유지한다. `apps/app`은 Flutter, `apps/web/src/app`은 웹 FSD 최상위다. 원본의 packages/engine와 후속 root engine 배치는 모두 제외한다. 별도 automated-qa-engine 저장소의 공개 artifact만 소비한다.

### D2. 서버 원본과 다언어 HTTP 계약

Nest DTO/controller → OpenAPI 3.0.3 → TypeScript fetch SDK/Dart Dio SDK → web/Flutter data adapter 순서다. 서버는 생성 SDK나 contract package를 runtime import하지 않는다. packages/contract의 OpenAPI는 생성 결과이며 편집 원본은 서버 DTO/controller다. 엔진 실행 JSON Schema와 HTTP OpenAPI는 별개다.

OpenAPI Generator의 typescript-fetch/dart-dio를 원본 목표로 유지한다. 정확 generator/JAR checksum/옵션/Java 버전은 작은 nullable/required/enum fixture spike로 검증 후 고정한다. SDK가 모든 런타임 검증을 보장한다고 가정하지 않는다. 수동 TS interface 공유나 TypeScript RPC는 Dart 동등 계약을 대체하지 못하므로 채택하지 않는다.

### D3. HTTP 규칙과 health 첫 연결

- `/api/v1`, Swagger UI `/api/docs`, JSON `/api/openapi.json`. 문서 UI 노출 환경은 설정으로 제한하고 generation은 실행 서버 다운로드에 의존하지 않는다.
- 고유 고정 operationId, 직접 response 반환. 공용 data envelope를 덧붙이지 않는다.
- ApiErrorResponse의 `code,message,requestId,details`는 required. details 원소는 `field,code,message`; 없으면 빈 배열. 400 VALIDATION_ERROR, 404 NOT_FOUND, 500 INTERNAL_ERROR. 서버 생성 requestId는 헤더/body/log가 일치하고 stack·secret은 노출하지 않는다.
- 입력은 transform/whitelist/forbidNonWhitelisted와 명시 query 변환을 사용한다. 문자열 `false`를 truthy boolean으로 변환하지 않는다.
- required/optional/nullable을 구분한다. UTC RFC3339, string identifier, finite number, 안전 정수 초과 decimal string. 출력 entity를 직접 반환하지 않고 mapper를 사용하며 실제 JSON/schema E2E로 검증한다.
- 첫 endpoint `GET /api/v1/health`, operationId `getHealth`. optional client는 web/app만 허용한다. 응답 `{status:"ok", service:"automated-qa-checker", apiVersion:"v1", client:"web"|"app"|null}`의 네 필드는 required이고 client만 nullable이다.
- 생략 client는 null, 빈 값·중복 query·unknown key·client=desktop은 400이다. Desktop은 원본의 앱 식별자 `app`을 사용한다. 연결되지 않은 서버는 transport error이지 HTTP 400이 아니다.
- 일반 body/path/query/numeric/date/list 검증은 테스트 전용 module fixture를 사용하고 production에 echo endpoint를 추가하지 않는다.

### D4. 순환 없는 생성과 root 명령

frozen install/pub get → server build(Swagger metadata 포함) → listen/외부 DB 없이 공통 configureApp을 이용한 OpenAPI export → 정렬·host/time/temp 제거 → lint/ref/operationId/fixture 검사 → 같은 artifact로 TS/Dart generation → 필요한 build_runner/formatter → SDK compile/analyze → web/app 검증 순서다. export 후 app을 close하고 production의 prefix/DTO/module 의미를 유지한다.

`contract:generate`는 명시 실행한다. `contract:check`는 격리 출력에서 생성하고 기존/신규/삭제 파일을 모두 비교하며 working tree를 고치지 않는다. 기본 build는 저장된 SDK를 사용한다. server→codegen→client→web의 역방향 의존은 금지한다.

| 명령 목표 | 의미와 현재 상태 |
| --- | --- |
| dev, dev:web, build, build:web | 현재 구현된 JS web 동작; server가 활성화되면 JS dev에 포함 |
| dev:server, dev:app | 목표, 앱별 독립 실행. Flutter 기기/API 인자 전달 |
| contract:generate, contract:check | 목표, 오프라인 export 및 deterministic/drift 검사 |
| lint, check-types, test | 목표, JS workspace 검증. 현재 verify의 실제 checks와 구분 |
| app:analyze, app:test, app:build | 목표, Windows Desktop build와 Flutter 검사 |
| verify:all | 목표, 계약·JS·Flutter 전체 실패 전파. 현재 verify는 JS만 |

Flutter task는 초기 cache하지 않는다. persistent dev는 cache:false다. cache를 도입한다면 pubspec/lock/SDK/generated client/platform/API_BASE_URL 입력을 명시한다. 누락된 SDK를 성공 처리하지 않는다.

### D5. 사용자 웹 FSD와 관찰 lifecycle

apps/web은 사용자 공용 시나리오·XML 전달·진행 앱이다. 관리자 게시·승인·권한 기능은 이후 권한별 화면으로 제공하고 별도 관리자 backend를 만들지 않는다. React SPA의 app→pages→widgets→features→entities→shared와 공개 slice API, cross-slice 검사 목표를 유지한다. 현재 단일 화면에서 router/deep-link가 검증된 것처럼 쓰지 않는다.

shared/api가 생성 SDK를 구성하고 entities가 화면 모델로 변환한다. XML serializer는 공개 엔진 문서 규격의 소비자이며 엔진 parser/실행 core를 복사하지 않는다. 파일 다운로드/열기가 첫 전달이고 direct/live server sync는 별도다. 입력 XML→정규 Blueprint→schema/graph 검증→실행계획→adapter 제어는 엔진 소유다. 현재 Playwright 실제, Appium/TV 후속이다.

원본 게임 canvas/RAF/physics lifecycle는 제외하고 QA 구독/타이머/비동기 파일 읽기의 소유권으로 대체한다. unmount/문서 교체/StrictMode에서 오래된 응답을 버리고 정리를 반복해도 안전해야 한다. server unavailable이어도 로컬 파일 관찰은 유지한다. 테스트 outcome·업무 progress·예약 occurrence·unrun은 혼합하지 않는다.

### D6. Flutter Desktop와 공유 범위

2026-10-29 사용자 추가 결정: Flutter는 기능별 MVVM과 package:provider를 사용한다. 이번 할당은 최소 Windows 앱과 Provider 구조·로컬 초안 편집 검증이며 엔진/API/전체 P2 구현은 포함하지 않는다.

```text
lib/app/qa_app.dart
lib/app/providers/app_providers.dart
lib/core/config/                  공용 환경 설정
lib/core/errors/                  표시 가능한 공용 오류
lib/features/scenario_editor/
  models/                        immutable ScenarioDraft
  views/                         UI 및 화면 수명의 controller
  view_models/                   ChangeNotifier 상태·사용자 액션
  repositories/                  데이터의 원본과 service 조합
  services/                      파일 IO, 후속 API/engine CLI 접근
```

원본 data/domain/presentation 책임은 유지하되 관리하기 쉬운 기능별 MVVM 폴더로 구체화한다. data→repositories/services, domain→models 및 필요 시 순수 업무 규칙, presentation→views/view_models로 매핑한다. 복잡한 재사용 규칙이 생기기 전에는 빈 use-case 계층을 추가하지 않는다. View는 service/IO를 직접 호출하지 않고 ViewModel 액션에 위임한다. ViewModel은 BuildContext·widget·File·Process 객체를 보유하지 않는다. Repository는 transport 세부를 숨기며 Model은 immutable 데이터다.

app/providers의 MultiProvider가 Service→Repository→ChangeNotifierProvider 순서로 조립한다. provider create가 만든 ViewModel의 dispose를 소유한다. View는 context.select/Consumer로 필요한 상태를 관찰하고 read로 액션을 요청한다. 비동기 작업 완료 전에 화면이 해제되면 notify하지 않고 중복 저장을 방지한다. controller는 View가 dispose한다. 테스트는 Repository/Service를 교체할 수 있어야 한다.

Flutter3.47.5/Dart3.13.4를 기준으로 provider6.1.5+1을 정확 고정한다. 공식 pub metadata의 Dart>=2.12.0<4.0.0/Flutter>=1.16.0 제약을 만족하며 pub get/analyze/test로 실제 호환성을 확인한다. Riverpod로 변경하지 않는다. 앱 pubspec.lock과 toolchain manifest를 남긴다.

생성 HTTP SDK의 `../../packages/api_client_dart` path dependency는 같은 Checker 저장소 내 Dart 관계이므로 허용한다. 외부 engine 소스에 대한 커밋된 file/path dependency 금지와 구분한다. engine은 버전/hash가 고정된 독립 CLI 배포판이다.

API_BASE_URL은 --dart-define origin이며 SDK가 /api/v1을 붙인다. Windows 개발 예시는 http://127.0.0.1:3000, release는 HTTPS다. missing/malformed origin은 HTTP 기능 설정 오류로 표시한다. 로컬 XML/Flow 편집과 엔진 실행에는 서버 연결을 요구하지 않는다. health loading/success/API error/timeout·unreachable/retry를 구분한다.

원본 Android emulator/debug 인수는 사용자 요구에 맞춰 Windows Desktop 실제 앱/build로 대체한다. Android/iOS·실기기 Appium은 후속이며 원본의 테스트를 수행한 것으로 표기하지 않는다. Desktop는 블록/Flow 및 XML 테스트 개발·저장·검증·명시 실행을 소유한다. 전체 builder는 qa-flow-editor, XML 첫 단위는 qa-user-web-desktop-handoff에서 구현하며 하나의 기능을 두 번 구현하지 않는다.

### D7. 테스트와 호환성

required nullable/omitted optional/enum/error/query/path escaping/numeric bounds/UTC/list fixture와 실제 TS/Dart 동일 server 호출을 모두 검증한다. generated parser의 shape 처리와 schema E2E의 책임을 구분한다.

v1 field 삭제/rename/type/required/nullability/error/status/operationId/enum 변경은 수용된 base branch 계약과 비교한다. 최초 baseline이 없다면 검증 후 최초 기준을 만들고 같은 변경 안의 현재 파일끼리 비교하지 않는다. optional 추가도 구버전 fixture의 unknown field 처리를 확인한다. breaking 변경은 v2 병행·전환 제안이 필요하다.

## Risks / Trade-offs

문서 이관을 구현 인수로 오인 → 모든 제품 tasks는 미완료이고 과거 JS 증거는 범위 한정한다. 코드 생성 diff/SDK 차이 → 버전·옵션 고정과 실제 fixture 검사. 두 계약 혼합 → HTTP는 Checker, 실행 의미는 Engine. 현재 working tree 미커밋 → 자동 commit/reset 없이 소유자별 변경을 보존한다.

## Migration Plan

1. 원본 출처·변환·의존 관계를 관리 에이전트가 검토한다.
2. 현재 web/contract와 lockfile·검증 명령을 보존하며 부족한 monorepo/runtime 검증을 채운다.
3. Flutter 로컬 테스트 개발/CLI와 서버 health·codegen은 의존 가능한 단위로 분리하여 담당 할당한다. 로컬 CLI 단계가 OIDC/예약을 요구하지 않는다.
4. 동일 서버 TS/Dart smoke, desktop 실제 실행, API/asset routing과 full CI를 인수한다.
5. 증거를 각 spec scenario에 연결한 뒤에만 sync/archive를 검토한다. 원격 push/merge와 commit은 별도 지시 범위다.
