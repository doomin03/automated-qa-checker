# HTTP 계약 생성

편집 원본은 `apps/server/src`의 Nest DTO/controller다. `packages/contract/openapi.json`과 TS/Dart SDK는 생성 결과다. Engine 실행 schema/배포 pin과 분리되어 있다.

## 재현

저장소 루트에서 실행한다. Node24.18.0/pnpm10.34.8, Flutter3.47.5에 포함된 Dart3.13.4를 사용한다. 기본 Dart 경로가 없는 환경은 `QA_DART`를 해당 dart executable로 설정한다. Java는 `QA_JAVA`로 지정할 수 있고 정확한 21.0.13 버전을 검사한다.

```powershell
& ./packages/contract/generator/setup.ps1
npx --yes pnpm@10.34.8 --filter @automated-qa-checker/server build
node packages/contract/generator/contract-tools.mjs generate
node packages/contract/generator/contract-tools.mjs check
node --test packages/contract/generator/contract-tools.test.mjs
npx --yes pnpm@10.34.8 --filter @automated-qa-checker/api-client check
```

setup은 `.local/server-tools`에만 Java와 JAR를 받고 SHA-256을 확인한다. 전역 환경을 변경하지 않는다. 정확한 버전/URL/hash/옵션은 [toolchain.json](toolchain.json)에 고정한다. Nest12.3.2, Swagger12.0.5와 TypeScript6.0.3을 사용한다.

공식 참고: [Nest OpenAPI](https://docs.nestjs.com/openapi/introduction), [typescript-fetch](https://openapi-generator.tech/docs/generators/typescript-fetch/), [dart-dio](https://openapi-generator.tech/docs/generators/dart-dio/). dart-dio의 json_serializable 옵션은 공식 beta 표시이며 health·협업·Agent 모델 및 아래 확대 fixture를 실제 생성·분석·직렬화·HTTP로 검증했다. 이 검증 범위 밖의 future API 타입을 자동 지원한다고 가정하지 않는다.

생성은 offline export→operationId/ref 검사→고정 Generator7.26.0→Dart build_runner→unused import 자동 수정→format 순서다. custom template은 pubspec dependency/analyzer 설정, collection 기본값의 const, path parameter의 Uri.encodeComponent 한 번 적용을 담당한다. api.mustache는 고정 JAR의 dart/libraries/dio/api.mustache를 기준으로 path 치환만 보정했다. 모델과 결과를 직접 패치하지 않는다. 생성 parser가 보장하지 않는 required/type/date 검증은 생성 schema를 읽는 adapter guard로 보완한다.

check는 임시 폴더에 다시 생성하여 전체 파일 목록과 byte를 비교한다. 수동 수정·삭제·신규/untracked·미생성 파일을 감지하고 저장소 결과를 수정하지 않는다. SDK 소비 build는 저장된 생성 결과를 사용하며 generator를 자동 실행하지 않는다. 검토된 HTTP baseline과 compatibility gate는 contract 패키지의 관리 baseline을 따른다.

## 실제 같은 서버 통합

```powershell
Push-Location packages/api_client_dart
& C:/workspace/QA/.tools/flutter-3.47.5/bin/cache/dart-sdk/bin/dart.exe pub get --enforce-lockfile
& C:/workspace/QA/.tools/flutter-3.47.5/bin/cache/dart-sdk/bin/dart.exe analyze
& C:/workspace/QA/.tools/flutter-3.47.5/bin/cache/dart-sdk/bin/dart.exe test
Pop-Location
node packages/contract/generator/integration.mjs
```

integration runner는 PORT=0인 실제 Nest 한 프로세스를 시작하고 TS 및 Dart 생성 SDK/adapter가 같은 origin을 호출한 후 종료한다. client 생략/null, web/app, HTTP400 공통 오류, 연결 실패를 확인한다. Windows Desktop GUI 실제 연결과 웹 브라우저 health 화면은 소비 앱이 별도 인수한다.

## 확대 fixture 생성 spike

`node packages/contract/generator/fixture-spike.mjs`는 테스트 전용 FixtureModule의 DTO/controller를 offline export하고 `.local/contract-spike`에 별도 TS/Dart SDK를 생성한다. 제품 OpenAPI와 공개 SDK 디렉터리를 수정하지 않으며 실행 전후 제품 OpenAPI SHA가 같음을 검사한다. 반복 디버깅용 `--reuse-generated`도 fixture schema bytes가 같은 경우만 허용한다.

고정 generator로 TS compile, Dart build_runner/analyze를 수행한 뒤 동일한 실제 Nest 서버에서 두 SDK를 왕복한다. required null/optional omission/enum/list, MAX_SAFE_INTEGER와 decimal, 범위 밖 정수의 문자열 표현, UTC millisecond 날짜, `/`, `?`, `%`, Unicode가 포함된 경로의 정확한 한 번 encoding, repeated query 거부, HTTP400/500 공통 오류 및 unknown response addition을 검증한다. generated schema guard는 잘못된 날짜·enum·범위·required 누락을 거부한다. `report.json`에 fixture/제품 hash와 인수 항목을 기록한다. 원본 모노레포 task1.4의 확대 fixture 양 SDK spike에 해당하며 제품의 새 route가 아니다.

Agent nullable reference의 null/object roundtrip과 운영 복구 메타데이터의 역할별 null은 양 SDK 단위 테스트와 실제 서버 권한 테스트로 별도 검증한다. drift check가 base-branch compatibility gate 또는 외부 OIDC/실기기 인수를 대신하지 않는다.
