# Design

## Context

Checker `main`/`4f97e920a399d4a5434ab1ecbe44c4d879d397a4`에는 이전 작업의 dirty 파일이 존재한다. 제품 기본은 alpha.6/draft.1, 직전 격리 인수는 alpha.7/draft.2 candidate-3이다. Engine counterpart는 `qa-engine-modular-refactor`이고 alpha.8/draft.2의 내부 모듈 분리가 대상이다. 명세 작성 시 후보 게이트 전이었으며 이후 관리 승인 candidate-1을 별도 설치해 소비 인수했다. 기본 환경은 승격하지 않는다.

## Goals / Non-Goals

Goals: 새 내부 모듈이 독립 tarball에 포함되고 현재 공개 호출·타입·XML·JSONL·결과를 유지하는지 실제 소비자로 검증한다.

Non-Goals: Engine 내부 구현의 Checker 복제, 기능 추가, 앱 스타일 변경, 기본 설치 승격, 다중 버전 서버, 운영 Agent 교체, 기존 Release 재빌드.

## Decisions

### D1. 실제 소비 경계

2026-11-07 `apps`, `packages`, `scripts`, `tests`, `design`의 소스를 `rg`로 검색했다. `packages/core`, `runners`, `packages/agent`의 Engine 내부 JS를 import하는 제품 경로는 발견되지 않았다. 내부 파일 이름과 같은 Checker 자체 `apps/web/.../xml.mjs`는 Engine import가 아니다.

| 소비자 | 현재 의존 | 모듈 분리 인수 |
| --- | --- | --- |
| Flutter `engine_cli_service.dart` | 사용자 CLI 절대 경로, manifest `entrypoint` 및 모든 파일 SHA, CLI의3단계 상위 package root | `packages/cli/aqa.mjs` 공개 진입점/깊이 유지, 실제 새 파일 manifest 전수 대조 |
| Nest `engine-contract.service.ts` | CLI dirname의2단계 상위 package root; `contracts/schemas/qa.schema.json`; `contracts/releases/qa-contract-<version>.json` | 공개 경로·bundle metadata·schema definitions·`--version --json`/validate/plan 유지 |
| 웹 | vendored 공개 bundle와 Checker 자체 XML serializer; runtime import 없음 | 동일 Blueprint/XML이 새 공개 CLI import/validate/plan/export와 의미 일치 |
| 실행 스트림/결과 | UTF8 JSONL, `runId/attempt/sequence`, terminal/exit/outcome, 상대 result/artifact 경로·bytes SHA | 누락/오염 이벤트 거부, PASS/FAIL/cancel·1000node 결과·실행 snapshot 동일성 |
| Agent 서버 | Engine version/contract/bundle SHA exact, Checker Agent HTTP 고정 schema | protocol hash 유지; alpha.6 실행 설정과 queue/lease를 이 검사에서 승격하지 않음 |
| 이전 Agent 진단 harness | `agent-artifact-loss.mjs`가 설치 package를 기준으로 third-party `playwright`를 resolve | 제품 Engine private import가 아니나 dependency 배치에 결합된 시험 도구임을 구분; 새 공개 API 인수에 이 방식 사용 안 함 |

Flutter 공개 명령은 `--version`, `devices --json [--target --appium-config]`, `import`, `expand --out --document-root`, `preset expand --preset-version --bindings --out`, `export --format xml --out`, `validate`, `plan`, `run --json --report --control-stdin --diagnostics stderr [--reference-root --appium-config]`다. 서버는 별도 validate/plan만 수행한다. `run.finished.resultPath`, report-root/runId 구조, 취소 JSONL `{type:"cancel"}`와 exit5 의미도 유지해야 한다.

### D2. 공개 표면으로만 새 설치 검사

Engine 전체 verify와 관리 hash 승인 후 `.local/service-audit/candidates/<version>/<tgzSHA>`에 설치한다. SHA/정확한 기대 버전/contractVersion·bundle SHA를 필수 입력으로 받고 기존 디렉터리는 덮지 않는다. alpha.7 하드코딩을 없애되 임의 버전 자동 수용은 하지 않는다. 테스트는 명시 expected version을 받으며 누락되면 후보 테스트를 실행하지 않는다. 실제 package 파일 수를 기록하되79개로 고정하지 않는다.

`automated-qa-engine`, `automated-qa-engine/playwright`, `automated-qa-engine/appium`의 package exports와 선언 타입을 외부 consumer에서 resolve/import한다. Checker 제품이 이 API를 현재 사용한다고 주장하지 않는다. Engine 담당의 전체 API 행동 인수를 대체하지 않고 exports/타입 포장 누락을 독립 확인한다. private deep import로 실패를 우회하지 않는다. 공개 `bin.aqa`와 기존 CLI path도 확인한다.

### D3. 기존 회귀를 재사용하는 작은 검증 변경

주입 `AQA_TEST_ENGINE_ROOT`/`AQA_TEST_ENGINE_MANIFEST`와 명시 후보 기대 버전으로 기존 Service 테스트를 확장한다. PASS/FAIL/350ms 지연 assertion/1000node visited999 및 unvisited997/paused-cancel에 XML export→import→plan 의미동등성과 실제 XML 실행 경로를 더한다. 문서 편집·실행 정책/제품 Service 코드는 바꾸지 않는다. 결과의 schema/identity/hash와 exit 판정은 기존 제품 검사를 그대로 사용한다.

### D4. 버전별 증거 보존

alpha.8 결과는 별도 버전 폴더에 저장한다. alpha.7 설치79파일 및 직전 acceptance/6runs 자료를 변경하지 않는다. alpha.6 설치74파일·내장 manifest·Release14파일·source pin·HTTP/Agent 계약은 기존 보존 검사로 대조한다. 새 version에 맞춰 이전 증거를 재생성하지 않는다.

## Risks / Trade-offs

- [CLI path가 내부 파일처럼 보임] → 현재 공개 문서/bin 및 소비 root 계산에 사용되므로 호환 shim을 Engine가 유지한다. 파괴 변경은 관리 검토 없이 Checker에서 우회하지 않는다.
- [파일 분리로 tarball 누락] → 새 manifest 전수 hash와 외부 exports/타입/CLI 실행을 확인한다.
- [출력 의미의 미세한 변경] → 동일 fixture의 snapshot·결과를 확인하되 runId/시간 같은 비결정 값은 동일 bytes로 요구하지 않는다.
- [제품 승격과 검사 혼동] → 독립 후보 인수만 보고하며 기존 alpha.6 앱/서버가 alpha.8로 바뀌었다고 표현하지 않는다.

## Migration Plan

명세 strict·관리 검토 후 harness만 확장한다. 후보 수신 전에는 설치/실행을 하지 않는다. 후보 소비 결함은 원인별로 Engine 담당 또는 Checker 관리 검토에 보고하며 기존 버전의 expectations를 완화하지 않는다. 이번 범위에 rollback할 운영 변경은 없고 실패한 후보는 해당 격리 폴더/실패 근거로 남긴다.
