# packages/api-client

`PlatformClient(origin, bearerToken)`은 로컬 협업 API의 공개 facade다. me/projects, createDraft/drafts/reviewDraft/publishDraft, versions/version/pins/pin/upgradeDiff, createRun/runs/run/events/appendEvents/result/uploadArtifact/downloadArtifact/audit를 제공한다. 입력·응답은 root에서 export한 생성 모델이다. `decodeEngineEvents`와 `decodeEngineResult`로 opaque Engine JSON을 읽는다. 요청별 AbortSignal과 client.close() 취소, 공통 오류 분류를 지원한다. [서버 실행/권한](../../apps/server/PLATFORM.md), 실제 양 SDK 검증 `node packages/contract/generator/platform-integration.mjs`를 참고한다.

Checker 서버의 OpenAPI에서 OpenAPI Generator typescript-fetch로 생성한 SDK다. `src/generated`는 직접 편집하지 않고 [생성 명령](../contract/generator/README.md)을 사용한다. `src/index.ts` 공개 export로 소비한다.

추가 facade는 업무 상태/비교/알림(work/updateWork/compare/selectBaseline/notifications/enqueueNotification), Suite(suiteDrafts/createSuiteDraft/reviewSuiteDraft/publishSuiteDraft/suites/suite/pinSuite), 실행(createExecution/executions/execution/cancelExecution/recoverExecution), 예약(createSchedule/schedules/setScheduleEnabled/occurrences)을 제공한다. `OrganizationClient`는 getSession/logout/desktopExchange/loginUrl을 제공한다. 웹 cookie 모드는 `PlatformClient(origin, '', {session:true, csrfToken})`이며 Desktop은 교환한 bearer token을 사용한다. 실행 결과와 업무 상태·운영 복구 기록은 별도 필드다.

```ts
import { HealthClient, ApiFailure, TransportFailure } from '@automated-qa-checker/api-client';
const client = new HealthClient('http://127.0.0.1:4319');
const result = await client.getHealth({ client: 'web' }, { signal: abortController.signal });
```

base URL에는 origin만 넣는다. `/api/v1/health`와 query는 생성 SDK가 소유한다. HealthClient는 생성 OpenAPI schema를 사용해 런타임 required/nullable/enum을 검사한다. 추가 optional response 필드는 허용한다. API 오류는 ApiFailure(status/body), timeout·connection·cancelled는 TransportFailure(reason), 잘못된 응답은 ContractFailure다. transport 오류에 가상의 HTTP status를 넣지 않는다.

`pnpm --filter @automated-qa-checker/api-client check`로 build와 어댑터 검증을 수행한다. 실제 Nest 양 SDK 검증은 generator의 integration runner를 사용한다. 이 package는 server/app source에 의존하지 않는다.

