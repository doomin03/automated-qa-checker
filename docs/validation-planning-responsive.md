# 기획 대응 · Desktop 반응형 인수

2026-11-12, `qa-desktop-planning-responsive`. 기준은 `main@3e73cd1`이며 이번 작업은 기존 D01–D08 사용자 경로와 창 제약을 정합한다. ScreenUtil은 추가하지 않았다. [화면/요구 대응표](../openspec/changes/qa-desktop-planning-responsive/mapping.md)와 [설계](../openspec/changes/qa-desktop-planning-responsive/design.md)를 함께 본다.

실제 native 창 크기와 사용자 경로·분석·전체 앱 회귀가 통과했다. 새 Release의 전체 파일 manifest와 startup 결과는 아래 별도 기록으로 확인한다.

## 변경

- 홈: 좁은 창에서는 섹션 선택과 목록/상세 전환으로 프로젝트·QA·수신·사본에 접근한다. 숨긴 pane은 focus 대상에서 제외하고 선택/입력 상태는 보존한다.
- XML 파일 블록: 중앙 캔버스는 안정된 key로 유지하며 좁은 속성/라이브러리는 대체 패널에서 편집한다. 사용자 글자 배율과 toolbar 높이를 반영한다.
- 직접 문서: XML/JSON 선택·커서·focus, 파일 블록 확대/선택을 창 왕복에서 유지한다. 합성 문서와 직접 문서의 실행 권한은 기존 VM이 소유한다.
- 결과/터미널: 낮은 높이에서는 bounded 작업 패널로 열어 캔버스를 유지한다. 닫기는 세션 종료가 아니다. 같은 PTY/버퍼를 유지하며 터미널 controller/스크롤은 부모 dock이 소유하고 활성 TerminalView는 하나다.
- 공유: 공개 SDK의 프로젝트 role/allowedActions/Engine 정보를 표시한다. 해당 정보는 조회 시점의 서버 설정이며 개별 mutation의 최종 권한·장치 접속을 보증하지 않는다. Suite pin 페이지를 다시 조회해 ordered case를 수신한다.
- 앱 alpha8과 기본 서버 alpha6의 게시 불일치는 표시하고 자동 게시를 막는다. 로컬 실행 판정과 PNG는 유지하며 서버를 자동 승격하지 않는다.

## 현재 검증 근거

`node scripts/flutter.mjs test --no-pub test/adaptive_workbench_test.dart --reporter expanded`: 2개 PASS, [로그](../artifacts/adaptive-widget-6.log). 1440×900/1024×768/800×600/1280×500 × text 1/1.25/1.5에서 속성·터미널·결과·홈·연결 폼 및 canvas/원문 상태 보존을 확인했다. 첫 실패 로그도 보존했다. `adaptive-widget-2`는 도구 Column overflow, `-3/-4`는 낮은 높이 inline terminal로 canvas 74px, `-5`는 inline 결과로 library 74px overflow다. 영역 스크롤과 공통 compact 작업 패널 정책으로 수정했다.

최종 보강한 동일 2개 회귀는 [adaptive-final.json](../artifacts/planning-responsive/adaptive-final.json)에서 exit0다. terminal controller/scrollController의 부모 소유·동일 인스턴스, 활성 TerminalView 하나, Delete/Ctrl+C의 canvas 비전파, 작은 창 실행 설정의 18회 Tab focus 가시성, DPR1/1.25/1.5에서 logical1024×768 유지도 확인했다. controller 수명 보존과 글자/행 재배치 후 정확히 동일한 스크롤 픽셀 보존은 별개이며 후자를 모든 상황에서 보증하는 인수는 아니다.

Backend 담당의 context 9개 + Home 1개 + 실제 shared Engine 1개 = 11개 PASS: [집중 로그](../artifacts/product-backend-context/app-context-final.log). context 실패/호환성/연결 교체와 pin 경계를 검사했다. 실제 shared 시험은 **격리 alpha8 서버**이며 수신만으로 실행 0, 실제 Chromium PASS, 검증된 업로드, 서버 중단 중 로컬 판정 유지와 복구 후 재전송을 확인했다. 기본 alpha6 서버가 alpha8 결과를 받아들이는 증거가 아니다.

첫 native 실행은 [로그](../artifacts/planning-responsive-native-1.log), [결과](../artifacts/planning-responsive/native/run-4a01a76/verification.json)에 보존한다. 실제 alpha6 context/Suite 수신과 alpha8 로컬 PASS, 공개 plan으로 PTY fixture 파일 수정 반영을 확인했다. 다만 이 실행의 `setSurfaceSize` 캡처는 렌더 제약이며 실제 descendant MediaQuery 크기와 같다고 확정하지 않는다. 최종 native 인수는 소유 테스트 HWND만 실제 resize하고 client geometry/MediaQuery/textScaler를 함께 기록한다.

**최종 native:** [native-acceptance.json](../artifacts/planning-responsive/native-acceptance.json) exit0, [최종 verification/13캡처](../artifacts/planning-responsive/native/run-a769fc/verification.json), 실행 시간 2분8초(별도 build35.4초). `resize-owned-window.ps1`는 PID와 실행 경로가 일치하는 테스트 앱 HWND만 변경한다. 실제 OS DPI 설정은 그대로이며 현재 DPR1.5에서 client2160×1350/1536×1152/1200×900과 descendant MediaQuery1440×900/1024×768/800×600이 각각 일치한다. 각 캡처의 `textScale14`도 별도 기록했다.

- 실제 alpha6 서버 context·Suite pin 재조회·case 수신, 수신으로 실행0 및 원본 version/사본 저장.
- 직접 XML의 alpha8 실행 PASS·검증 PNG. alpha6 공유 요청은 차단하고 로컬 PASS 유지.
- Provider scope 해제 후 재생성으로 원문/receipt 복원. OS 재시작 복원 시험으로 확대하지 않는다.
- 실제 PTY의 Node fixture가 `scenario.xml`을 수정하고, 앱 stable read→공개 alpha8 plan→Flow에 `end_terminal` 반영. compact 패널 닫기/창 복원 후 동일 PID, 명시 종료 후 cleanupUnknown=false.
- 800×600/text1.5의 수신 상세·원문·터미널·파일 블록 속성. 파일 블록의 검증/명시 실행도 PASS·PNG. 두 run/result와 reportDirectory는 verification에 각각 기록한다.

`node scripts/flutter.mjs analyze --no-pub`: [analyze-acceptance.json](../artifacts/planning-responsive/analyze-acceptance.json) exit0, No issues found. 이전 analyze의 braces lint12개는 동작 변경 없이 정합했고 실패 로그도 보존했다.

전체 앱 첫 실행은 [planning-responsive-app-tests.log](../artifacts/planning-responsive-app-tests.log)의 74 PASS/1 skip이지만 PowerShell 리다이렉션이 native compiler stderr를 NativeCommandError로 처리하여 바깥 exit1이었다. 전체 게이트로 쓰지 않고 Node spawn의 실제 child code/signal을 저장하는 최종 실행으로 교체한다. candidate 전용 시험은 별도 승인된 격리 Engine 환경이 없을 때 skip하며 앱 기본 pin을 변경하지 않는다.

최종 전체 회귀는 [app-tests-acceptance.json](../artifacts/planning-responsive/app-tests-acceptance.json)의 **exit0/signal null, 74 PASS/1 skip**, 실행 로그 기준7분51초다. 명령은 `node scripts/flutter.mjs test --no-pub --concurrency=1 --reporter expanded`. native 최종 소스와 lint 정합 뒤 실행했고 [source-freeze-final.json](../artifacts/planning-responsive/source-freeze-final.json)의 앱/생성 Dart SDK/config287파일을 고정했다. actual Engine PASS/FAIL/cancel·디자인 report/PNG·공유 복구·파일 충돌·MVVM 수명·Flow/파일 블록·새 context/adaptive 회귀를 포함한다. candidate 전용 skip을 이번 alpha8 설치 미검증이나 앱 실패로 집계하지 않는다.

저장소 `corepack pnpm run verify`는 backend의 최종 [verify.log](../artifacts/product-backend-context/verify.log) exit0를 재사용한다. 이후 변경은 Flutter/앱 검증·문서·새 Release 기록/시작 스크립트에 한정한다. 새 OpenSpec 23/23 strict, foundation, 경계7개 PASS를 별도로 실행했다. 생성 SDK drift와 서버/TS/Dart HTTP 인수는 [backend 검증](validation-product-backend-context.md)을 따른다. 전체 `verify:all`을 한 명령으로 실행했다고 보고하지 않는다.

소유 앱/검증/문서 범위의 `git diff --check`는 exit0다. 전체 저장소 검사는 생성 TS JSDoc의 trailing spaces13곳으로 exit2이며 생성기의 재현 결과를 수동 수정하지 않았다. backend 검증 문서와 [diff-check.log](../artifacts/planning-responsive/diff-check.log)에 그대로 기록한다.

## 사용자 동작

넓은 창에서는 탐색·속성·AI를 inline으로 사용하고 작은 창에서는 `탐색`, `보기`, `속성`, 홈의 섹션/`선택 상세`를 사용한다. 낮은 창의 `터미널 열기`와 `실행 로그 / 결과`는 별도 패널이다. `작업실로`/`결과 닫기`로 돌아오며 터미널의 `종료`만 실제 세션 정리를 요청한다. 가로 toolbar는 스크롤할 수 있고 키보드 focus 이동으로도 버튼에 접근한다.

프로젝트/QA 수신·검증·AI 변경은 테스트를 자동 실행하지 않는다. 앱의 명시 `검증 → 실행` 경로를 사용한다. 서버 호환되지 않음 안내가 있어도 로컬 문서와 실행은 사용할 수 있다.

## 범위와 보존

이번 PTY 인수는 실제 native 터미널에서 실행한 Node fixture의 파일 수정이며 Codex 모델 편집 성공이 아니다. 실제 Codex 로그인·모델 호출의 과거 인수는 별도 기록이다. OS DPI 설정은 변경하지 않는다. 위젯의 devicePixelRatio와 사용자 textScaler 검사는 각각 구분한다.

기존 Release, 원본 목업, Engine 패키지/앱 alpha8 pin, 기본 서버/Agent alpha6 pin과 저장 포맷은 보존한다. 개인 배정함·Desktop Suite 전체 일괄 실행·모바일/TV/recorder 등 후속 목표를 이번 완료로 표시하지 않는다. Source/SDK/Release 최종 manifest와 실행 경로는 아래 기록을 따른다.

## 새 Release와 재현

실행 파일은 `artifacts/releases/desktop-planning-responsive-alpha8/Release/automated_qa_desktop.exe`다. **Release 폴더 전체**를 함께 유지한다. 이 PC의 검증된 alpha8 설치/Node 경로는 생성 asset에 들어 있으며 다른 checkout/PC로 옮길 때는 [설치 안내](desktop-ai-quickstart.md)에 따라 재설치·재빌드한다. 기존 Release는 덮어쓰지 않았다.

`node scripts/flutter.mjs build windows --release --no-pub`는 [release-build.json](../artifacts/planning-responsive/release-build.json) exit0, build74.6초다. `node scripts/record-planning-responsive-release.mjs`가 별도 폴더에 복사하고 모든 bytes를 재대조했다. `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/smoke-planning-responsive-release.ps1`는 별도 APPDATA의 소유 프로세스로 Flutter native window 초기화를 확인한 뒤 그 프로세스만 종료했다. 이 startup을 실제 전체 사용자 여정 실행으로 확대하지 않는다.

| 산출물 | 검증 |
|---|---|
| [전체 Release manifest](../artifacts/releases/desktop-planning-responsive-alpha8/manifest.json) | 19파일, manifestSha256 `f574738e59e59519700808ca9c5b1a312761d4d4309beb79d96fcfd75da8e145` |
| Dart AOT `data/app.so` | SHA256 `09856b06aabb5082b845aed949b009467c40a61b6238f34e184f5bb31349855d` |
| [앱 source manifest](../artifacts/releases/desktop-planning-responsive-alpha8/source-manifest.json) | lib73파일 + pubspec/lock, plugin 구성, Engine pin/생성 asset |
| [SDK source manifest](../artifacts/releases/desktop-planning-responsive-alpha8/sdk-source-manifest.json) | Dart SDK lib209파일 + pubspec/lock |
| [native startup](../artifacts/releases/desktop-planning-responsive-alpha8/launch.json) | 동일 Release manifest, native window 초기화 및 isolated APPDATA |

실제 사용은 새 앱에서 프로젝트/QA를 연 뒤 XML 파일 블록을 배치하거나 직접 XML/JSON 문서를 연다. 로컬 예제는 repo에서 `node scripts/desktop-demo.mjs`를 실행하고 출력되는 XML을 가져와 **검증 → 실행**한다. 기존 alpha6 서버 연결은 공용 QA/Suite 수신용으로 사용 가능하지만 alpha8 실행 결과 게시에는 호환되지 않음이 표시된다. 서버/앱 계약을 임의로 변경하거나 이 오류를 로컬 테스트 실패로 바꾸지 않는다.

소유 테스트 창만 HWND resize했고 기존 사용자 앱/작업 공간을 종료·삭제하지 않았다. 새 서버 context/Suite pins SDK를 포함한 앱·SDK 고정 source287파일의 마지막 SHA 재대조는 [acceptance.json](../artifacts/planning-responsive/acceptance.json)에 기록한다. Git commit/push 및 OpenSpec archive는 수행하지 않았다.
