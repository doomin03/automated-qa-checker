# Desktop 준비 진단 및 portable 인수

2026-11-13 portable Release/상대 runtime/실제 웹 인수를 마쳤다. readiness 기능을 구현했으나 실제 interactive AI 파일 수정, Claude 및 OS IME는 미인수다. 기존 alpha.9 배포는 보존하며 서버 alpha.10 승격은 별도 담당의 통합 gate를 따른다.

## 준비 진단

실행 파일 선택, provider별 경로 기억/삭제, 공식 설치 안내, 명시 재진단 및 가이드 상태 확인을 Provider/MVVM으로 연결했다. `artifacts/multi-terminal/readiness-focused.json`은 실제 child exit0/10 PASS, `readiness-analyze-2.json`은 analyze exit0이다. 가이드 파일 준비/hash 검증은 CLI가 실제 skill을 발견·사용했다는 뜻이 아니다.

작성 환경 dialog의 별도 UI 인수 `readiness-environment-ui-2.json`은 exit0/1 PASS다. 제품 TerminalDock/Repository를 사용해 실제 준비 파일을 확인하고, exact Clipboard 문구/newline0, A의 dialog 중 B를 선택해도 A에만 미제출 입력, dialog 생성 뒤 epoch 변경의 write0, guide 읽기 await 중 epoch 변경의 오류/입력 disabled를 확인했다. 원문은 보존하고 Engine run0이다. PTY 출력과 모델은 fixture다. 최초 `readiness-environment-ui.json`은 test fake zone에서 만든 Completer를 real runAsync가 기다려 timeout3회를 기록했다. Completer 생성도 동일 runAsync로 옮긴 test-only 수정 후 통과했으며 제품/Release bytes는 변경하지 않았다.

실제 Codex 시험은 기존 로그인과 repo 밖 합성 QA만 사용했다. 최초 `native/run-eebfd8a2`는 사후 터미널 진단 부족으로 실패 원인을 확정하지 않았다. 허용된 한 번의 복구 `artifacts/terminal-readiness/native/run-6cb831f3/verification.json`에서는 요청 전달 뒤 사용량 한도 오류가 표시됐다. XML SHA는 전후 동일하며 GUI 새 노드는 없고 sync 오류도 없다. 소유 PID 종료, cleanupUnknown=false, 전역 config SHA 동일이다. 모델 변경·추가 구매·영구 trust UI 선택·추가 재시도는 하지 않았다. 따라서 XML/JSON 모델 편집→GUI→실행과 실제 skill 사용은 미완료다. Claude는 미설치이며 OS 한글 IME 인수도 별도다.

## Portable 입력 및 집중 회귀

관리 승인 alpha.10 archive SHA `0476445261b2596954167f335968d8bbb0a513867c930553604ba9b2b1c780e3`를 별도 `.local/desktop-engine/0.1.0-alpha.10/<SHA>`에 설치하고 승인 167파일을 대조했다. authoring metadata의 `artifact`를 안전한 상대경로로 읽어 legacy alpha.9 및 alpha.10 bundle을 찾는다. `node --test scripts/authoring-artifact.test.mjs`는 정상 두 형식과 path escape/pin/manifest 오류를 검증했다.

`node scripts/prepare-portable-runtime.mjs`는 공식 Node 24.18.0 ZIP 및 exe SHA를 대조하고 LICENSE, 전체 npm dependency, 별도 Chromium을 고유 staging에 준비한다. Playwright `.links`와 npm 설치 `.package-lock.json`은 절대 개발경로를 가진 실행 불필요 metadata여서 새 staging에서만 제외한다. 기존 설치/cache는 바꾸지 않는다. 첫 runtime은 1882파일, manifest SHA `40d1174aedcc5d9280db1c069c2205bf20aaa7e3806c6df69e1377f8ba01782e`이며 관리자가 독립 대조했다.

`portable-focused.json` exit0/6 PASS, `portable-focused-2.json` exit0/3 PASS: 무결성 오류/캐시 변경 감지/외부 CLI 환경 분리/자동 기본값 relocation/명시 및 과거 설정 보존/검증 대기 중 cancel 또는 dispose 후 spawn0을 확인했다. 최초 전체 SHA는 isolate에서 수행하고 이후 파일 목록·size·mtime/ctime이 바뀌면 재검증한다. 이는 적대적 timestamp 위조 방어가 아니다.

## 이동 경로 및 성능 인수

한글·공백 경로의 실제 Service 웹 PASS/FAIL/cancel은 `artifacts/portable-runtime/relocation-test.json` exit0 및 `relocation/verification.json`으로 확인했다. child PATH는 Windows/System32만, browser 경로는 해당 복사본만 사용했다. 3개 결과/terminal snapshot과 PNG 2개를 관리자가 독립 대조했다.

초기 순수 Dart 전수 검증은 38,102ms였다. 승인 Node 자체 SHA를 Dart에서 먼저 확인하고 앱 고정 builtin verifier로 전수 검사하는 최적화 뒤 `native-verifier-test.json`도 3 runs PASS이나 새 복사본 첫 검증은 39,492ms였다(Node 선검증 3,516ms). 이를 무조건 속도 개선으로 해석하지 않는다. 같은 경로의 별도 새 Service 측정 `verifier-performance.json`은 최초 4,630ms(Node 1,258/list 611/hash 1,821), 캐시 775ms이며 같은 크기 변조 거부와 복원 후 검증을 통과했다. 복사 직후 cold 환경과 재사용 환경을 구분해 모두 보존한다.

같은 PC relocation을 실제 새 물리 PC/Windows prerequisite 인수로 표현하지 않는다. 기존 설정의 provenance가 없으면 사용자 명시값인지 추측하지 않고 보존하며, 사용자가 실행 환경의 `이 앱의 기본 실행 환경 사용`을 선택해 전환한다.

2026-11-13 추가 인수: `artifacts/multi-terminal/portable-native-3.json` actual exit0, `artifacts/portable-runtime/native/run-ca202f47/verification.json`은 실제 Windows Provider의 상대 runtime 자동 설정→명시 검증→명시 웹 실행 PASS→`PNG 1개` 버튼의 MemoryImage 표시를 확인한다. `02-relative-settings.png`와 `04-visible-png.png`로 설정 필드 간격 및 실제 증거 화면을 확인했다. 닫힌 진단 상세를 빈 결과/누락 PNG로 판정하지 않는다. 이 시험은 debug host에 relocation root를 주입한 것이며 최종 portable Release 위치 해석/기동은 별도다.

`verifier-performance-breakdown.json`의 같은 경로 새 Service는 총 5,304ms(Node 1,114ms/list 518ms/stat 152ms/realpath 272ms/hash 1,484ms), 캐시 648ms였다. 새 복사본의 39.5초와 구분하며 cold 지연의 원인은 확정하지 않는다. per-file canonical 검사 정책은 유지했다. `portable-junctions.json` exit0은 root/중첩 junction 및 같은 크기 변조 거절을 확인한다. 초기 UI에는 실행 환경 확인 중이라는 안내를 표시한다.

## 최종 회귀와 배포

`artifacts/multi-terminal/portable-full-final.json`은 실제 exit1이다. 원본 전체 실행에서 87 PASS/3 조건부 skip/1 FAIL을 기록했다. 실패는 800×600/text1.5 설정 창의 Tab wrap 후 컨트롤이 위쪽 화면 밖에 남는 접근성 문제였다. 해당 dialog에만 명시적인 포커스 스크롤을 적용했고 `portable-focus-recovery.json` exit0/2 PASS로 원래 전체 adaptive 파일을 재검증했다. 단일 전체 명령 PASS로 바꾸어 기록하지 않는다. 3개 skip은 별도 승인 candidate 환경 및 portable root 환경변수 조건이며 portable 전용 실행은 위 relocation/실제 verifier 증거로 별도 인수했다. `portable-analyze-final.json`은 exit0/No issues다.

`build-2026-11-13T01-20-32-058Z.json`은 `--dart-define=QA_PORTABLE=true` 실제 Windows build exit0이다. 최초 pack은 recorder가 빈 목적지를 만든 뒤 `cp(errorOnExist:true)`를 호출해 EEXIST/exit1이었다. 성공 Release는 존재하지 않았으며 빈 실패 폴더를 `Release-empty-recording-failed-20261113`으로 보존했다. recorder만 수정하고 동일 빌드 bytes를 다시 기록해 pack exit0을 확인했다. 제품 소스를 바꾸거나 전체 빌드를 반복하지 않았다.

최종 `artifacts/releases/desktop-portable-alpha10/manifest.json`은 1904파일(앱21/runtime1882/외부receipt1), manifest SHA `4afd1ad8339eda3f2c9ec2cca4b139feaa71823be716d3370f9fdd8226d87cc9`다. 앱83/SDK224/vendor172 및 설정과 tooling8개를 포함한 `source-freeze.json`은 총501파일, SHA `9294d8704dd9778fca2a7d7ac93fb905525c5e86ae85e4f3529b6a092d873c82`다. 관리자가 전수 대조했다. ignored embedded installation은 portable/version/archiveSHA만 가지며 개발 절대경로를 포함하지 않는다. 원래 개인 installation receipt는 `.local`에 보존했다.

`portable-native-relative.json` actual exit0, `native/run-4229a654/verification.json`은 sanitized asset으로 빌드한 native host가 root 주입 없이 `Platform.resolvedExecutable`의 부모에서 runtime을 해석하고, 자동 설정→검증→명시 실행 PASS→실제 PNG 표시를 확인했다. 이는 debug integration host의 실제 사용자 경로다. 별도로 최종 Release 자체는 `launch.json`에서 PATH=Windows/System32, 격리 APPDATA 및 실제 HWND 기동을 확인하고 소유 프로세스만 종료했다. Release 기동과 integration host의 실행을 같은 시험이라고 합치지 않는다.

사용 절차는 [portable 시작 안내](portable-desktop-quickstart.md)를 따른다. 최종 서버/SDK 검증은 서버 담당의 `qa-server-agent-alpha10-runtime` 증거를 함께 참고하며 앱의 서버 호환 검사 우회는 없다. `verify:all` 단일 전체 명령은 실행하지 않았다.
