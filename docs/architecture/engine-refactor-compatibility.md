# Engine 모듈 분리 소비 호환 인수

현재 기본 환경은 alpha.6이며 alpha.7 candidate-3의 실제 소비 인수는 보존한다. alpha.8/draft.2 candidate-1은 Engine 전체 verify와 관리 hash 게이트 이후 격리 설치해 소비 인수를 완료했다. [명세](../../openspec/changes/qa-engine-refactor-compatibility/design.md)의 경계표와 작업을 따른다. 앱/서버 제품·기본 pin·기존 Release는 변경하지 않았다.

## 준비한 검사

- `node --test tests/engine-candidate.test.mjs`: 잘못된 기대 version/contract/hash, 변조 archive, 중복 파일 목록과 기존 설치 폴더를 설치 전 거부한다. inert 임시 fixture만 읽고 npm 호출0을 확인한다.
- `scripts/engine-candidate.mjs`: 정확한 기대 값과 Engine `verification.json`을 대조한 뒤 version/fullSHA별 독립 폴더에 설치한다. 실제 package 전체 파일 목록·SHA를 Engine verification의 `installedFiles`와 직접 비교한다. 이전79파일 같은 개수를 고정하지 않는다. source assets와 기본 installer는 수정하지 않는다.
- `scripts/check-engine-candidate-public.mjs`: 외부 consumer가 공개 root/playwright/appium exports를 import하고 유효 TypeScript는 tsc exit0, 잘못된 public 호출은 tsc exit2로 거부한다. XML 공개 API roundtrip도 비교하며 private deep import를 쓰지 않는다. 후보 게이트 전에는 이 검사를 실행하지 않는다.
- `engine_candidate_service_test.dart`: 명시 환경의 version/SHA와 manifest가 같아야 한다. PASS/FAIL/지연 text/1000node 양쪽 결과 목록에 XML export→import→plan 의미동등과 XML 실제 실행을 더했다. paused-cancel 회귀와 함께 실행한다. 후보 환경이 전혀 없으면 candidate 테스트는 명시 skip이며 일부만 지정하면 실패한다.

후보 이전 준비 인수는 preflight 검사1개 PASS(npm0), Dart analyze PASS(68.8초), JS syntax check였다. 이후 실제 후보 인수는 아래 별도 결과로 기록한다.

## alpha.8 candidate-1 실제 인수

- runtime0.1.0-alpha.8 / contract0.3.0-draft.2, tgz SHA `4215662445780eeecd016ad6acf2a7b2c5e16b9a4e62cf8ae88e30ee0452e77f`, bundle SHA `638d48f182d12819ebd167d42457c7dceaa90928abb38c32a4867e3c94b10763`로 별도 설치했다. 실제148파일 목록/bytes SHA가 Engine `verification.json`의 installedFiles와 일치했다.
- 공개 root/playwright/appium import와 공개 XML API roundtrip PASS, tsc 정상 consumer exit0/잘못된 호출 exit2를 확인했다. Engine private deep import는 사용하지 않았다.
- 실제 Service2개 테스트/7실행 PASS(59초): JSON PASS, XML export→import→plan 동등·XML 실행 PASS, 의도한 assertion FAIL,350ms 지연 text/1500ms 단언 PASS,1000node 방문999/미방문1 및 방문3/미방문997 PASS, UI pause 중 실제 cancelled result 저장107ms. 시간은 단일 로컬 관측이며 성능 보장이 아니다.
- 최종 Flutter analyze PASS(79.1초). 제품 코드 변경이나 Windows 재빌드는 없으며 새 엔진을 기본 앱에 배포한 것으로 보고하지 않는다.
- 근거는 `artifacts/engine-refactor/0.1.0-alpha.8/4215662445780eeecd016ad6acf2a7b2c5e16b9a4e62cf8ae88e30ee0452e77f/`의 `public-surface.json`, `service-candidate.json`, `paused-cancel.json`, `acceptance.json`이다. 로그는 `artifacts/engine-refactor/alpha8-service-tests.log`와 `alpha8-analyze.log`다. 기존alpha.6설치74/Release14/제품source43파일과alpha.7설치·증거128파일의 hash를 보존한다.

## 후보 수신 후 재현

아래 인자는 관리자가 승인한 정확한 값으로 설정하며 임의 최신 버전을 검색하거나 자동 승격하지 않는다.

```powershell
node scripts/engine-candidate.mjs $env:QA_CANDIDATE_TGZ $env:QA_CANDIDATE_VERSION $env:QA_CANDIDATE_SHA $env:QA_CANDIDATE_BUNDLE_SHA 0.3.0-draft.2 $env:QA_CANDIDATE_VERIFICATION
# 위 명령이 출력한 installation.json을 읽는다.
$receipt = Get-Content -Raw -Encoding UTF8 $env:QA_CANDIDATE_RECEIPT | ConvertFrom-Json
node scripts/check-engine-candidate-public.mjs $env:QA_CANDIDATE_RECEIPT $env:QA_CANDIDATE_VERSION $env:QA_CANDIDATE_SHA
$env:AQA_TEST_ENGINE_ROOT = $receipt.packageRoot
$env:AQA_TEST_ENGINE_MANIFEST = $receipt.manifestPath
$env:AQA_TEST_ENGINE_VERSION = $env:QA_CANDIDATE_VERSION
$env:AQA_TEST_ENGINE_SHA = $env:QA_CANDIDATE_SHA
node scripts/flutter.mjs test test/engine_candidate_service_test.dart test/engine_service_integration_test.dart --concurrency=1 --reporter expanded
Remove-Item Env:AQA_TEST_ENGINE_ROOT, Env:AQA_TEST_ENGINE_MANIFEST, Env:AQA_TEST_ENGINE_VERSION, Env:AQA_TEST_ENGINE_SHA
```

모든 후보 실행 결과는 `artifacts/engine-refactor/<version>/<tgzSHA>/`에 기록한다. 기존 `artifacts/service-audit/acceptance.json`, alpha.7 결과와 설치는 덮지 않는다. 기존 alpha.7 전용 ignored installer는 과거 인수 도구로 보존하고 새 후보에는 위 version 검증 도구를 사용한다. 후보 실패 시 expectations를 약화하지 않고 원인·수정 소유권을 관리 에이전트에게 보고한다.
