# 서버·Agent alpha.10 인수 기록

2026-11-13, Checker `main` 기준 HEAD `3e73cd1f14b0aab658748e9c9b5c1be4a87794ad`의 승인된 미커밋 변경을 검증했다. OpenSpec은 `qa-server-agent-alpha10-runtime`이다. 실행 안내는 [서버·Agent 연결](server-runtime-alpha10.md), Desktop 배포는 [별도 portable 안내](portable-desktop-quickstart.md)를 따른다.

## 고정 계약과 보존

- 현재 서버 pin: `packages/contract/runtime/engine-runtime.json`, Engine `0.1.0-alpha.10`, execution contract `0.3.0-draft.2`.
- archive SHA256: `0476445261b2596954167f335968d8bbb0a513867c930553604ba9b2b1c780e3`.
- execution bundle SHA256: `b99337961c1477549d9dd52b65f6ec888d47679f4735d3025435ee06881f93c1`.
- 별도 `.local/engine-server-alpha10` 설치의 package 167파일과 CLI 버전·bundle을 확인했다. 재준비는 검증된 설치를 재사용한다.
- A07 동결 SDK 339파일, legacy 계약·앱 asset 5파일, 기존 `.local/engine` package 74파일은 변경되지 않았다. `artifacts/runtime-alpha10/preservation.json`에 파일 SHA와 비교 결과가 있다.
- alpha.6→alpha.10 Agent HTTP protocol은 동일하다. execution schema는 `visitedNodes`/`unvisitedNodes` 최대 항목 수 확장으로 raw SHA가 다르다. 같은 HTTP protocol이라는 이유로 기존 Agent 등록/lease를 새 runtime에 재사용하지 않는다.

## 실제 실행 결과

`node apps/server/scripts/verify-runtime-integration.mjs`는 exit 0이었다. 본 인수는 `artifacts/runtime-alpha10/run-unCN6f/verification.json`에 기록했으며, 실행 시간은 UTC 01:17:32–01:18:25였다. 독립 loopback 서버·대상·임시 DB·새 Agent token/state와 설치된 실제 Engine CLI/Chromium을 사용했다.

| 항목 | 실제 결과와 경계 |
| --- | --- |
| 공유 결과·PNG | 실제 로컬 Run 결과와 PNG를 HTTP 게시·조회·다운로드하고 bytes/SHA 및 viewer 거부를 확인했다. |
| 게시 Suite | HTTP 실행 요청 후 실제 Agent가 순서대로 2개 case를 통과했다. Suite 준비·검토·게시 fixture는 내부 Service를 호출했다. |
| 예약 Suite | Scheduler의 제어 clock으로 occurrence를 생성하고 실제 Agent가 2개 case를 통과했다. 서버 재시작 후 동일 clock 재tick에서도 occurrence/execution은 1개였다. 실제 일주일 대기는 아니다. |
| 실패 중단 | 신뢰된 fixture enqueue 후 실제 Agent의 첫 case가 실패했고 후속 case의 Run을 합성하지 않았다. |
| 취소 | 실제 assertion 시작 후 HTTP 취소를 요청했다. 요청 시 claimed와 최종 cancelled를 구분하고 최종 `run.finished`, `cleanupErrors: []`, cleanup confirmed, evidence verified를 확인했다. |
| 정리·전송 | 4개 Agent lease 모두 closed, receipt ACK, resource 해제, owner retired를 확인했다. |
| 과거 이력 | 실제 기록된 alpha.6 Chromium Run을 저장한 DB를 alpha.10 서버로 재시작해 version/Run/events/등록/lease 원본을 보존했다. 새 ingestion의 runtime 불일치와 구 Agent claim을 거부했다. 구 lease는 blocked 프로토콜 fixture이며 새 실기기 실행으로 세지 않는다. |

현재 runtime의 실제 Run은 7개(5 passed, 1 failed, 1 cancelled), PNG는 6개다. `durable-evidence-comparison.json`은 7개의 로컬 `result.json`·`events.jsonl`과 서버 저장 JSON을 경로별로 읽어 정확히 대조한 후속 검사이며 모두 일치했다. 취소 Run의 durable/수신 마지막 이벤트와 빈 cleanupErrors도 포함한다.

5개 실제 실행 child에서 PID와 생성 시각으로 관측한 소유 프로세스는 종료 후 잔존하지 않았다. 2개 XML export child는 main process close만 확인했다. 주기적 관측이므로 전체 OS 프로세스 누수 부재를 증명하지 않는다.

## 회귀와 근거

| 명령 | 결과/로그 |
| --- | --- |
| `node apps/server/scripts/prepare-server-runtime.mjs <approved archive>` | 설치·재사용 모두 exit 0, `artifacts/runtime-alpha10/install.log`, `reuse.log` |
| `node --test apps/server/test/server-runtime.test.mjs` | 2/2, paired override/기존 DB read-only guard/설치 tamper 거부, `preparation-tests.log` |
| `node apps/server/scripts/verify-runtime-integration.mjs --history-only` | exit 0, `history-final.log`; 초기 capability fixture 오류는 `history.log`로 보존 |
| `node apps/server/scripts/verify-runtime-integration.mjs` | exit 0, `actual-integration.log` 및 위 actual verification |
| `pnpm run verify` | exit 0, `artifacts/runtime-alpha10/verify.log`; 서버 56/56, TS SDK 12/12, foundation/lint/boundaries/types/packages/OpenSpec/build/실제 웹 UI·route 회귀 포함 |

전체 verify 이후 schedule demo의 기본 폴더·paired runtime helper 정합과 현재 공용 문서만 추가 반영했다. 이 후속 변경은 `final-checks.log`의 syntax/helper tests/foundation/lint 및 `strict-final.log`로 별도 검증한다. 전체 verify를 후속 변경 이후 재실행했다고 주장하지 않는다. 명령별 exit·최종 파일 SHA는 `artifacts/runtime-alpha10/acceptance.json`에 연결한다.

관리 독립 검토는 상위 `coordination/remaining-implementation-20261112/server-runtime-review.json`과 `server-integration-review.json`에 보존했다. A07 별도 계약/권한/SDK HTTP 회귀는 [관리 API 인수](validation-project-administration.md)에 있다.

## 인수하지 않은 범위

현재 결과는 로컬 Windows PC의 실제 Chromium·Agent·HTTP 인수다. 원격 배포, 다른 PC 실물 실행, 모바일/Appium 실기기, 실제 외부 Slack 발송, A07 웹 관리 화면을 완료로 간주하지 않는다. 기존 DB·Agent identity를 자동 승격하지 않으며 기존 alpha.6 설치와 과거 validation/Release는 유지한다. 서버는 명시 runtime·identity 환경 설정이 필요하고 Desktop portable의 최종 Release/다른 PC 인수는 앱 담당 기록을 따른다.
