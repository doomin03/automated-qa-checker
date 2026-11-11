# 로컬 협업 서버 실행

Node 24.18.0과 설치된 고정 Engine 배포물이 필요하다. 저장소 루트에서 실행한다. `.env.example`은 참고용이며 자동 로드하지 않는다.

```powershell
node apps/server/scripts/local-identities.mjs
$env:NODE_ENV='development'
$env:HOST='127.0.0.1'
$env:PORT='4319'
$env:QA_AUTH_MODE='local'
$env:QA_DATA_DIR=(Join-Path (Get-Location) '.local/platform-data')
$env:QA_ENGINE_CLI=(Join-Path (Get-Location) '.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs')
$env:QA_ENGINE_MANIFEST=(Join-Path (Get-Location) 'apps/app/assets/engine-runtime.json')
$env:QA_LOCAL_IDENTITIES_JSON=[IO.File]::ReadAllText((Join-Path (Get-Location) '.local/platform-identities.json'))
$env:CORS_ORIGINS='http://127.0.0.1:4318'
corepack pnpm --filter @automated-qa-checker/server dev
```

도구는 ignored `.local/platform-identities.json`에 무작위 토큰을 기록하고 원문을 출력하지 않는다. 기존 파일은 덮어쓰지 않는다. 파일의 author 토큰은 초안 작성·발행에, **별도 reviewer 사용자 토큰은 검수에** 사용한다. 자기 검수는 금지한다. tester는 실행 공유·pin, viewer는 조회만 가능하다. 프로젝트 ID는 demo다. 토큰을 저장소·스크린샷·공유 로그에 넣지 않는다. DB에는 토큰 SHA-256만 저장한다.

매 시작 시 설정이 사용자 활성 여부와 membership의 기준이다. 설정에서 제거한 사용자는 비활성화되고 membership은 갱신된다. 삭제·비활성 사용자 요청은 즉시 거절한다. OIDC 로그인, 웹 cookie session/CSRF, Desktop PKCE 교환은 구현했으며 로컬 RS256 provider와 실제 HTTP·웹·Flutter 경로로 검증했다. 외부 Slack 실계정 연동 인수는 pending이다. local/test 모드는 명시적인 development/test NODE_ENV와 loopback HOST만 허용하며 production 또는 외부 바인딩은 시작 시 거부한다. 이 제한과 별개로 oidc 모드는 HTTPS callback/web origin 등 인증 설정을 검증한다. `/api/v1/me`의 localMode는 local/test에서만 true이며 UI에 표시한다. 모드 미설정/disabled이면 health만 사용한다.

## 계약과 영속성

DTO/controller가 HTTP 계약 원본이며 offline exporter는 listener·DB·Engine·자격증명 없이 같은 AppModule에서 OpenAPI를 생성한다. 공개 SDK facade는 PlatformClient다. 모든 경로·입출력 모델은 생성물을 사용한다.

SQLite 버전별 migration, foreign key, unique constraint, BEGIN IMMEDIATE transaction과 중첩 SAVEPOINT로 발행·이벤트 배치·멱등 응답을 저장한다. Agent, 인증, 업무 상태, Suite, 예약, 역사증거 중복 제거와 운영 복구도 별도 migration으로 관리한다. 발행 버전은 UPDATE/DELETE trigger로 고정한다. DatabaseSync는 단일 로컬 서버 데모를 위한 동기 API다. 대규모 병렬 서비스·다중 서버 프로세스·분산 storage는 인수하지 않았다. Repository 경계에서 DB를 교체할 수 있다. QA_DATA_DIR 백업·보존 정책은 별도 운영 작업이다.

Registry는 qa_editor 이상 초안 작성, qa_manager 이상 독립 검수·발행, qa_tester 이상 개인 pin, viewer 이상 조회를 허용한다. 발행과 run 생성에는 idempotency-key가 필수다. 동일 key/본문은 저장된 응답을 반환하고 다른 본문은 409다. version/hash/dependency manifest는 고정되며 pin 업그레이드는 diff 조회 후 명시적으로 수행한다. 현재 draft XML은 수정 API 없이 새 초안을 만든다.

Engine JSON은 문자열 envelope다. 설치된 공개 schema와 CLI validate/plan만 사용하고 DSL을 복제하지 않는다. CLI는 shell=false, timeout/output cap, manifest SHA-256/exact version 검증을 적용한다. run 생성은 실제 seq1 run.started와 normalized Blueprint, Engine version/hash를 대조하고 서버 ID를 부여한다. blueprintJson 응답은 실행 당시 고정 snapshot이다. owner만 이벤트·result·artifact를 추가할 수 있다.

이벤트 cursor는 sequence다. 동일 sequence/본문 재전송은 성공, 다른 본문·gap·terminal 이후 새 이벤트는 409이며 배치는 원자적으로 반영한다. snapshot node 범위, start/finish, retry 한도와 재시작 금지, active node 종료를 검사한다. HTTP 오류는 공통 code/message/requestId/details를 유지한다. token/XML/Engine payload는 요청 로그에 기록하지 않는다.

## 증거와 제한

result는 공개 schema와 run/attempt/snapshot/terminal outcome/visited·unvisited를 검사하고 불변 저장한다. artifact는 result의 상대 논리 이름에 서버 opaque ID를 연결한다. 클라이언트 filesystem 경로를 읽는 API는 없다. 업로드 한도는 **파일당 10 MiB, 실행당 64 MiB, JSON HTTP body 16 MiB**다. base64 bytes·size·hash·MIME를 검사하고 임시 파일 sync 후 rename한다. check-report JSON은 1 MiB JSON complexity 제한 및 공개 schema/artifactRefs 검사를 받는다. 재시작 시 자체 staging 파일을 정리하고 실제 bytes를 다시 확인한다.

reportedOutcome은 외부 Engine의 보고다. evidenceStatus verified는 제출된 bytes/hash/identity/참조의 정합성 확인이며 서버 재실행·신뢰 보증이 아니다. 네트워크 업로드 실패를 로컬 QA 실패로 바꾸지 않는다. workStatus의 todo/in_progress/done 전이, 담당자 지정·triage, 비교 가능한 이전 baseline 선택과 regression 비교, 로컬 알림 fixture를 구현·검증했다. 업무 상태 변경은 원래 QA outcome을 변경하지 않는다. 외부 Slack 알림 전송과 실계정 로그인 인수는 pending이다. Agent 실행·증거 전송·운영 복구 및 주간 예약의 실제 인수는 [AGENT.md](AGENT.md)와 [인수 기록](../../openspec/changes/qa-agent-protocol/acceptance.md)에 구분해 기록한다.

공유 Registry/예약의 published XML은 외부 PNG/font 자산이 필요 없는 범위를 지원한다. 로컬 디자인 자산 작성·실행과 Agent의 bounded resource 다운로드·assertImage 인수는 완료했지만, 공유 자산 패키지 게시 UI를 구현했다는 의미는 아니다.

## 실제 검증

`apps/server/test/platform.test.mjs`는 실제 Nest HTTP·SQLite·공개 Engine CLI로 권한/발행 경쟁/재시작/삭제 사용자/이벤트 충돌/업로드 실패 복구를 확인한다. 생성 SDK 통합은 `node packages/contract/generator/platform-integration.mjs`로 실행한다. 두 SDK가 같은 Nest 서버에서 검수·발행·pin·run 생성·cursor polling·result를 왕복한다. 테스트 이벤트/result는 고정 Blueprint 기반 fixture이며 실제 브라우저 실행이라고 보고하지 않는다.
