# Engine 서비스 소비 점검 · 2026-11-07

Checker는 공개 Engine package/CLI의 소비자다. 이번 점검의 기준 pin은 alpha.6 / 실행 contract0.3.0-draft.1이며 기존 Release와 목업을 보존한다. 신규 Engine 후보는 관리자가 검증한 version/hash의 별도 설치로 인수한 뒤에만 승격할 수 있다.

## 재현과 개선

| 경계 | 실제 관찰 | 조치/근거 |
| --- | --- | --- |
| UI 이벤트 구독 pause | 실제 Node child가3MiB stdout에서 정지하고 UI resume 뒤만 진행 | OS pipe를 즉시 읽는 별도 bounded transport; `before-pressure.json` |
| 과대 stderr | devices가4MiB 진단을 제한 없이 소비 | stderr2MiB 누계 제한, 원문 보관/화면노출 없음 |
| inherited pipe | Windows fixture에서32초 뒤 이미 완료; hang 미재현 | 재현 결함으로 주장하지 않음; exit+EOF 전체 기한은 방어적으로 보완 |
| 큰 Flow 캔버스 | 40/1000node 마지막 bottom1230/31950px, canvas1000px로 잘림 | node 좌표 기반 동적 범위·스크롤 접근, 선택과 이동 구분 |
| 서버 CLI bridge | 900KB chunked UTF8 응답, 진단 한도, 잘못된 JSON,15초 hang 모두 예상 처리·child 종료 | 서버 제품 코드 변경 없이 회귀 테스트 추가 |

근거 파일은 `artifacts/service-audit/`의 `before-pressure.json`, `before-pipe.json`, `before-large-flow.json`, `server-regression.json`이다. 실제 transport의 비정상 child 테스트와 실제 공개 Engine 실행 인수는 구분한다.

## 소비 정책

Flutter 명령은30초+정리2초, 실행은 앱 자체120초 예산+취소 grace10초+정리2초가 상한이다. Engine API의 최대300초 허용과 앱의120초 제한은 별개다. stdout16MiB/stderr2MiB 누계를 UI pause 여부와 무관하게 검사한다. 제한내 stdout 큐는 UI가 재개하면 순서대로 처리한다. stdout JSON/UTF8 오류와 stderr 원문은 그대로 사용자 오류에 복사하지 않는다.

run의 UI 구독 취소·dispose·프로토콜/출력 오류·watchdog는 공개 control stdin 취소를 먼저1회 전송한다. 취소 grace가 끝나면 직접 시작한 child를 강제 종료한다. 이미 시작된 grace를 다시 연장하지 않는다. command/export는 제어 stdin이 없어 직접 종료한다. 강제 종료 뒤 하위 writer/브라우저/모바일 세션 정리는 확인되지 않은 상태이며 정상 cancelled를 합성하지 않는다. 정상 취소는 기존 terminal·exit5·result·snapshot·artifact 대조를 통과해야 한다. 협력 child가 자신의 descendant를 정리하는 fixture는 가능하지만 임의 프로세스 트리나 실기기 cleanup 보증은 아니다.

서버 EngineContractService는 테스트 실행 없이 validate/plan만 호출한다. argument array/shell false, 공개 schema 검사, 임시 document-root, 파일 hash pin, stdout/stderr2MiB,15초 timeout+5초 종료fallback을 사용한다. Agent 실행 child·outbox·취소·cleanup은 별도 Engine Agent package가 소유한다. Checker 서버는 lease/fence·인증·진행/결과·자료 정합성을 확인하며 실행 프로세스를 직접 제어하지 않는다.

## 적용 가능한 대상과 운영 제약

- 웹: 설치된 Chromium/Playwright 경로를 실제 로컬 실행으로 검증한다. 실제 서비스 URL의 계정·데이터·동의·네트워크 정책은 별도 운영 설정이다.
- Android/iOS: Appium adapter와 로컬 W3C fixture는 구현됐으나 실제 기기/앱 인수는 별도다. 정적 devices 응답의 `connectionVerified:false`를 연결 성공으로 취급하지 않는다.
- Windows: Flutter 도구 자체를 Windows에서 실행한다는 의미다. 임의 Windows native 앱의 UI Automation/WinAppDriver 제어 adapter가 제공된다는 의미가 아니다.
- 독립 CLI: Node24와 고정 package 설치, Playwright Chromium 설치가 필요하다. Flutter/중앙 서버는 Engine 자체의 필수 의존성이 아니다.
- package tgz와 자체 파일 SHA를 확인하지만 transitive node_modules 전체를 매 실행 재검증하지 않는다. 정확한 직접 dependency 버전과 npm lock/integrity, 브라우저 cache·OS toolchain 관리 범위를 구분한다. 현재 preview package는 공개 npm 운영 배포나 서명 설치 프로그램 인수가 아니다.
- API/Agent 서버의 영속 상태·권한·복구는 기존 로컬 인수 근거가 있다. 외부 Slack 실계정, 운영 HTTPS/비밀관리, 실제 모바일 기기·production 부하/SLA를 이번 로컬 점검으로 완료 처리하지 않는다.

## 재현

```powershell
node scripts/flutter.mjs test test/cli_process_test.dart test/large_flow_view_test.dart --concurrency=1
node scripts/flutter.mjs test test/engine_bridge_test.dart test/engine_ui_test.dart --concurrency=1
node --test apps/server/test/engine-consumption.test.mjs
node scripts/flutter.mjs analyze
```

테스트는 실제 로컬 Node child와 설치된 공개 package를 사용한다. 서버 테스트는 먼저 기존 `pnpm build:server` 결과가 있어야 한다. 관련 OpenSpec은 `qa-engine-service-consumption`이며 최종 실제 결과와 후보 소비 상태는 [검증 기록](../validation.md)에 기록한다.

## alpha.6 소비 회귀 체크포인트

### 신규 후보의 격리 인수와 운영 승격

관리 승인 alpha.7 candidate-3를 `.local/service-audit/`의 별도 version/hash 설치와 파일 manifest로 실제 Service에 주입했다. `AQA_TEST_ENGINE_ROOT` / `AQA_TEST_ENGINE_MANIFEST`로 PASS/FAIL/cancel·1000node 결과·지연 assertion을 인수했다. source pin·`.local/engine`·앱 assets·기존 Windows Release와 서버/Agent 설정은 alpha.6을 유지한다. 기존 installer는 기본 경로와 assets를 함께 수정하므로 이번 격리 설치에 사용하지 않았다. Windows 재빌드도 이번 인수에 필요하지 않다.

후속 기본 승격에는 별도 설치 경로·source 계약/manifest·참조 테스트/문서 정합 및 새 Windows Release 빌드가 필요하다. 기존 Release는 내장 alpha.6 hash를 확인하므로 기존 `.local/engine`을 alpha.7로 덮으면 실행을 거절한다. 서버의 실행 version과 Agent runtime/contract/hash도 정확히 일치해야 하므로 서버 CLI/manifest를 한 쌍으로 관리하고 활성 lease·queued job·예약 pin을 검토해야 한다. 기존 앱의 로컬 실행 보존이 새 서버와의 진행 게시 호환을 뜻하지는 않는다. 이번에 운영 서버를 교체하거나 다중 버전 지원을 추가하지 않는다.

후보 게이트 전 준비한 `apps/app/test/engine_candidate_service_test.dart`는 주입 환경이 없으면 명시적으로 skip한다. 승인된 설치에서 기본 PASS, 명시 mismatch FAIL,350ms 지연 text/1500ms 단언,1000node의 visited999/unvisited1 및 visited3/unvisited997 결과를 실제 Service로 검사한다. 기존 `engine_service_integration_test.dart`는 같은 주입 manifest로 paused-cancel을 검사한다. 준비된 harness 자체를 후보 인수 PASS로 계산하지 않는다.

관리 hash 승인 후 격리 설치 receipt의 절대 경로를 사용한다. 아래 명령은 후보 게이트 전 실행하지 않는다.

```powershell
$env:AQA_TEST_ENGINE_ROOT = '<검증된 후보 설치의 packageRoot>'
$env:AQA_TEST_ENGINE_MANIFEST = '<검증된 후보의 독립 engine-runtime.json>'
$env:AQA_TEST_ENGINE_VERSION = '<관리 승인된 정확한 engineVersion>'
$env:AQA_TEST_ENGINE_SHA = '<관리 승인된 tgz SHA256>'
node scripts/flutter.mjs test test/engine_candidate_service_test.dart test/engine_service_integration_test.dart --concurrency=1 --reporter expanded
Remove-Item Env:AQA_TEST_ENGINE_ROOT, Env:AQA_TEST_ENGINE_MANIFEST, Env:AQA_TEST_ENGINE_VERSION, Env:AQA_TEST_ENGINE_SHA
```

### 실제 현재 결과

2026-11-07 고정 source의 focused Flutter20개가2분23초에 통과했고 analyze는6.3초에 통과했다. 위 transport·Flow 외에도 실제 CLI PASS/FAIL/cancel, Provider 화면 경로, 재마운트·stale 응답·DI 소유권을 포함했다. 테스트의 강제종료·협력 child fixture는250ms~1초의 짧은 예산을 주입하며 제품 기본10초 grace를 바꾸지 않는다.

마지막 `large-flow-view.json`의1000node debug widget 측정은 build3393ms/스크롤·선택1216ms이며40node는1101/318ms다. 앞선1000node 관측은3601/1388ms였다. 이는 마지막 node 접근과 원문/좌표/undo 보존 근거이지 release 성능이나 부하 SLA 인수가 아니다. 현재 모든 노드를 만드는 비용은 남아 있다.

공개 alpha.6의 마지막 paused-cancel 인수는 준비4127ms·pause까지4563ms·취소 요청부터 disk result688ms이며 UI 구독을 멈춘 동안 실제 cancelled 결과가 저장됐다. 앞선142ms 관측과 마지막688ms를 서로 다른 측정으로 보존한다. 이 alpha.6 체크포인트 당시 후보 소비는 미완료였으며 후속 인수는 아래에 별도로 기록한다.

위 alpha.6 체크포인트 이후 alpha.7 candidate-3 격리 인수를 완료했다. tgz SHA는 `0199b719baaf2f41c46b6e6cb07dc8ddd80464923c639ed724cae612f31c80c3`, 공개 bundle SHA는 `36ceac45564c61f5f0b442136488838299a56846992b65ce360a5ea5c4dde7fe`이며 contract는0.3.0-draft.2다. 실제 Service5사례와 paused-cancel1사례(총6실행)가2개 테스트/1분1초에 통과했다. 1000node 방문999/미방문1 및 방문3/미방문997 결과를 소비했고350ms 지연 text가1500ms 단언 예산 안에서 통과했다. UI pause 중 취소 결과가702ms에 저장됐다. 이 시간은 단일 로컬 관측이며 성능 보장이 아니다. Service run 시간에는 재검증·capability·snapshot plan 등의 여러 CLI 호출이 포함되므로 Engine 단독 실행 벤치마크와 직접 비교하지 않는다.

`artifacts/service-audit/public-0.1.0-alpha.7/service-candidate.json`, `paused-cancel.json`, `flutter-candidate3.log`, `flutter-candidate3-analyze.log`가 근거다. 설치 receipt는 `.local/service-audit/candidates/0.1.0-alpha.7/0199b719baaf2f41c46b6e6cb07dc8ddd80464923c639ed724cae612f31c80c3/installation.json`이다. 후보79파일 및 기존alpha.6설치74파일/Release14파일을 hash로 확인했다. 후보 인수는 기본 환경 승격이나 운영 배포 완료가 아니다.
