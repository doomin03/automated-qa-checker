# apps/server

Nest 12.3.2 HTTP 서버. health, 사용자·프로젝트 권한, SQLite Registry/Suite 검수·발행, 실행 이벤트·증거, 업무 상태·비교, Agent lease와 주간 예약을 제공한다. [협업 실행 및 제약](PLATFORM.md), [Agent와 예약](AGENT.md), [실제 인수 기록](../../openspec/changes/qa-agent-protocol/acceptance.md)을 따른다. OIDC는 로컬 provider 인수 완료이며 외부 Slack 실계정은 별도 인수한다. 로컬 Desktop 문서 편집·Engine CLI는 이 서버를 요구하지 않는다.

## 실행

저장소 루트에서 고정 pnpm 설치 후 실행한다. `.env.example`은 설정 예시이며 자동으로 읽지 않는다.

```powershell
$env:PORT='4319'
$env:HOST='127.0.0.1'
$env:CORS_ORIGINS='http://127.0.0.1:4318'
npx --yes pnpm@10.34.8 --filter @automated-qa-checker/server dev
```

dev는 최초 TypeScript build 후 compiler watch와 서버 restart를 실행한다. production은 `build` 후 `start`를 사용한다. `API_DOCS=true`일 때만 `/api/docs`와 `/api/openapi.json`을 노출한다. CORS는 명시된 정확한 origin과 cookie credentials를 허용하며 wildcard는 사용하지 않는다. OIDC cookie mutation은 CSRF 검사를 별도로 통과해야 한다. 원격 배포 TLS는 앞단 proxy에서 제공한다.

```powershell
curl.exe -i 'http://127.0.0.1:4319/api/v1/health?client=web'
curl.exe -i 'http://127.0.0.1:4319/api/v1/health?client=desktop'
```

첫 요청은 200 및 `{"status":"ok","service":"automated-qa-checker","apiVersion":"v1","client":"web"}`을 반환한다. client를 생략하면 필드는 null이다. client=app도 가능하다. 빈 값·중복 client·알 수 없는 query는 400이다.

모든 API 오류는 HTTP status와 `code/message/requestId/details`를 유지한다. 400 VALIDATION_ERROR, 404 NOT_FOUND, 500 INTERNAL_ERROR이며 details는 field/code/message 배열이다. requestId는 서버에서 새로 생성해 응답 헤더와 본문 및 요청 로그에 동일하게 기록한다. 내부 exception/stack/query 값은 반환하지 않는다.

## 계약과 검증

편집 원본은 src의 DTO/controller다. Swagger 명시 decorator를 production/export 모두 같은 TypeScript compilation으로 사용한다. 서버는 생성 SDK나 contract package를 역참조하지 않는다.

```powershell
npx --yes pnpm@10.34.8 --filter @automated-qa-checker/server check
node apps/server/dist/scripts/export-openapi.js packages/contract/openapi.json
```

exporter는 listen/init/DB/외부 자격증명 없이 document를 생성하고 앱을 닫는다. 시험용 body/path/boolean/nullable/optional/numeric/UTC/list controller는 test module에만 있다. production AppModule과 OpenAPI에는 포함하지 않는다.

실제 Nest HTTP 테스트가 response schema, 400/404/500, requestId 로그, CORS preflight, offline/runtime 문서 일치를 확인한다. 다언어 확대 fixture는 별도 생성 TS/Dart SDK로 같은 Nest 서버에서 왕복한다. 관리 baseline과 compatibility gate는 contract 패키지에서 관리한다. 생성·통합 명령은 [generator 안내](../../packages/contract/generator/README.md)를 따른다.

