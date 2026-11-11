# 실제 인수 기록

2026-10-31 Checker 서버 담당 기록이다. 개발용 서버와 target은 검사 후 종료했으며 ignored DB/artifact를 삭제하지 않았다. commit/push는 하지 않았다.

## 고정 계약

- Agent wire `0.1.0-draft.1`: `8c25e3c853f3b8d24003464d2ddc55a20675b7ac3f741a46c238a50ce4149490`, 관리자·Engine 동일 bytes 수용.
- 전체 Nest HTTP: `f705acfa8a30d4c89ec8f588a2d85bd49a837ee1084d93fa273a725f3a09ef90`, 관리자 수용. 운영 복구 네 nullable 필드를 포함한다.
- 실제 candidate2 archive: `0dce64bf4b3be2bab09cce56c96e394f1cfa759eae3b7535f5fbc7e8ae908c45`. Engine 최종 alpha6 승격 후 기본 설치를 사용한 서버 회귀도 별도 수행했다. candidate2 실제 실행을 최종 archive bytes 실행으로 바꿔 기록하지 않는다.
- candidate1 checkpoint는 archive `917c6ae0…deee1` / 이전 wire `754b35b5…f9de`로 보존한다. 이후 wire와 혼합하지 않는다.

## 서버·SDK 자동 회귀

- Agent 실제 Nest HTTP/SQLite: durable claim 멱등·remaining TTL, 두 credential 자원 독점·다른 Agent 권한 거부, 동일 Agent 다른 resource의 중복 lease 거부, deadline 경계, restart quarantine, 역사증거 identity/dedup, nullable recovery, 동시 complete 영수증 보존, retired owner, 101개 이력의 pagination 및 누적 100+1 receipt ACK.
- OS 시간을 바꾸지 않고 Date.now를 ±24시간 주입해도 monotonic remaining TTL은 동일하다. 약 6.25MiB인 두 lease의 실제 HTTP reconcile은 개수 한도 전에 byte budget으로 1개씩 나누며 각 응답은 8MiB 미만이고 다음 cursor에서 모든 lease를 빠짐없이 반환한다. 큰 fixture는 Blueprint JSON의 합법적인 whitespace만 늘리며 parsed snapshot/hash는 바꾸지 않는다.
- 업그레이드 전 고정 job은 새 Engine Agent에 전달하지 않고 `engine_pin_incompatible` 미실행으로 보존한다. 실행 결과를 합성하지 않는다.
- Scheduler: DST gap/overlap/반시간 offset, unique occurrence, 두 번 tick/서버 restart, missed와 assert outcome 분리, disable/동일 enable 멱등, exact deadline, 잘못된 예약 한 개의 실패 격리, 고정 pin 불일치, 역할별 운영 metadata null/복구403.
- Platform 공통 ingestion: retry는 started 한 번→retrying→finished, retry 뒤 started 거부, optional screenshot의 step skipped 허용/terminal skipped 거부. 기존 Registry·영속 run·artifact 실패/재시도 인수도 같은 경계를 사용한다.
- 생성 TS 9 tests와 Dart 7 tests/analyze, Agent draft와 DTO slice 참조 해제 동등성 검증. expanded fixture는 별도 DTO→고정 generator→TS compile/Dart analyze→동일 실제 Nest HTTP에서 nullable/optional/enum/list/numeric/date/한 번 path encoding/HTTP 오류를 확인한다. `.local/contract-spike/report.json`은 제품 HTTP bytes 불변을 포함한다.

## 독립 설치 Engine와 실제 Nest

서버 원본 근거: `.local/agent-demo-alpha6-candidate2/server-verification.json`, SQLite `data/platform.sqlite`, bytes `data/artifacts`. 관리자가 read-only로 교차 확인했다.

- idle204 owner crash→같은 durable state restart, 다른 state root에서 같은 credential 동시 실행 거부.
- 두 case FAIL→PASS 순서/stopOnFailure true/false, 실제 취소, 각 실행 side effect counter 대조. 이 두 case fixture는 published Suite 게시 인수와 구분한다.
- recovered-only: 원래 lease fence6/cleanup unknown/receipt 없음 보존, operator fence7, 새 execution fence8.
- mixed owner: A의 실제 closed receipt ACK, B의 crash lease fence10→operator11, B의 8 events와 cleanup unknown/receipt 없음 보존, 새 execution fence12. 원래 QA 결과를 합성하지 않았다.
- PNG resource opaque download: `assets/baseline.png`, 420 bytes, SHA `b1eba2bd8b8eca4655f76e1c2de94771c326e54893569448d59bb7e46a34df77`, 실제 assertImage PASS. DB에 저장된 13 artifact의 bytes/size/hash를 모두 확인했다.
- published Blueprint 독립 reviewer→publish→한 case Suite publish/pin→UTC 주간 예약: schedule `2bbb8fcd-df5a-4864-a53b-1a40a43e127a`, due `2026-10-31T06:36:00.000Z`, execution `784b24cd-640c-4cc5-a7fe-190864127630`. occurrence 한 개, 실제 대상 POST 한 번, 16 events, closed/confirmed/receipt ACK. Agent restart 후 중복 실행 없음.

candidate1 실제 claim-response/event-ACK loss/cancel 근거는 `.local/agent-demo-alpha6/server-verification.json`에 별도 보존한다.

## 최종 alpha6 artifact 응답 유실과 경로 경계

최종 archive SHA `33dbcacea025fb98a52fb0411af05cb113bc85e47e84a98463912b6aace1acef`와 현재 Agent wire를 사용한 별도 실제 Nest 인수다. 실행 도구는 `apps/server/scripts/agent-artifact-loss.mjs`, 성공 기록은 `.local/agent-artifact-loss-final/matrix-247e7680-ef18-4a4b-ad8f-64081b58e3f5/verification.json`, DB는 `.local/agent-artifact-loss-final/data/platform.sqlite`다.

- execution `37bbb2c8-bbac-4fa7-8ec4-158760fc6ed4`, lease `abbf0c41-04a7-4f46-862f-5d1ef34062e3`, 서버 run `bc3e5f26-d530-4539-83e8-687c56f86b12`.
- 첫 artifact PUT을 서버가 저장한 뒤 proxy가 응답을 한 번 끊었다. Agent의 complete/receipt 재조회는 uploaded 1/missing 3을 반환했고 나머지만 업로드했다. 최종 uploaded 4/missing 0, closed/confirmed, receipt ACK, sequence 10, 실제 대상 POST 1회를 확인했다.
- PNG 세 개와 report JSON 한 개의 실제 bytes/size/SHA를 DB와 대조했다. 같은 durable state 재시작도 exit 0이며 QA 중복 실행이 없었다. 관리자가 DB와 네 파일을 독립 read-only 검증했다. fixture 서버·target·proxy는 종료했고 증거는 보존했다.
- 이미 저장된 파일의 PUT 생략은 정상 복구다. 실제 Agent가 같은 PUT을 두 번 보냈다고 기록하지 않는다. 동일 본문 업로드의 서버 멱등성은 Platform HTTP 회귀와 구분한다.

Checker 업로드/리소스 경계는 opaque ID, 10MiB 파일·64MiB 실행·16MiB HTTP 제한, hash/size, 실패 후 원자 복구를 검증한다. 파일 materialize의 UNC/symlink 검증은 Engine 소유다. Engine `tests/agent-protocol.test.mjs`의 `Agent rejects UNC and absolute resource paths before requesting resource bytes`는 Windows UNC, slash UNC, Windows drive 두 형식, POSIX absolute를 schema/policy/materialize 경계에서 거부하고 resource HTTP 요청 0회를 확인했다. 같은 파일의 font/subdir·hash·대소문자 충돌 회귀, `tests/design.test.mjs`의 실제 Windows junction escape, `tests/input-evidence.test.mjs`의 외부 absolute/junction 거부를 함께 참조한다. Engine `docs/validation-alpha.6.md`에 상세 근거가 있다. UNC 추가 검증은 test-only이며 최종 archive는 불변이다.

## Desktop·업무 상태·fresh 검증의 최종 합산

Checker owner가 Desktop Provider/Nest의 published Suite 두 case 수신·version pin과 연결 교체 시 기존 pin 보존을 인수했다. `artifacts/flutter-shared-ui/verification.json`을 참조한다. Desktop 개별 실행 경로와 Agent의 ordered 다중 case 실행을 결합한 인수이며 Desktop 일괄 실행 기능으로 확대하지 않는다.

업무 비교·triage/assignment·권한·실패 재시도는 Auth/Workflow HTTP 및 실제 browser/Provider 인수를 결합한다. `artifacts/workflow-web-verification.json`은 실제 디자인 증거 PASS/FAIL의 regression, workStatus done 이후 원래 failed outcome 보존, localNotification true/externalNotification false를 기록한다. 이 기록의 원래 Engine 버전은 alpha5이며 최종 alpha6 전체 검증과 구분한다.

fresh clean dependency 설치에서 제품·SDK 검증과 Windows release build 단계는 통과했다. **전체 `verify:all` 명령의 원래 exit 1과 fullVerification false는 유지한다.** 마지막 native smoke의 PInvoke 검증 도구를 수정한 뒤 같은 fresh 산출물의 native process/window 초기화 재실행은 exit 0이었다. 전체 명령을 다시 실행해 성공한 것으로 표시하지 않는다. `artifacts/fresh-install-verification.json`, `artifacts/fresh-attempt-2-smoke-failure.json`, `artifacts/fresh-recovery-verification.json`에 원래 실패와 회복을 각각 보존한다. source 666개 대조에서 변경은 `scripts/smoke-windows-release.ps1` 검증 도구 하나이며 나머지 source drift는 0이다. native smoke의 범위는 프로세스·창 초기화이고 제품 상호작용은 별도 Windows integration_test/Provider 인수가 담당한다.

## 완료 표시 경계

task3.3/4.1은 경로 경계와 최종 artifact 응답 유실 근거, task4.2는 Desktop 및 Agent의 구분된 인수, task4.4/4.5는 owner의 업무 상태 및 fresh 단계별 회복 근거를 합산해 완료한다. 단일 전체 명령의 exit 0을 뜻하지 않는다. 외부 Slack 실계정 로그인·알림은 pending이다. Android/iOS 실기기 및 다중 서버 DB 운영은 이번 로컬 fixture 인수에 포함하지 않는다.

현재 공유 Registry/예약은 외부 PNG/font가 필요 없는 published XML을 지원한다. 로컬 디자인 자산 작성·실행 및 Agent bounded resource 전달을 공유 자산 패키지 게시 기능으로 표시하지 않는다.
