# XML 파일 블록 작업실 검증 — 2026-11-11

담당 저장소는 Checker, branch `main`, HEAD `4f97e920a399d4a5434ab1ecbe44c4d879d397a4`다. 기존 대규모 미커밋 변경 위에 승인된 `qa-desktop-xml-block-studio`를 적용했다. commit/push, Engine 수정, 기존 Release 교체는 하지 않았다.

## 실행과 산출물

- 새 Windows 앱: `artifacts/releases/desktop-xml-block-studio-alpha8/Release/automated_qa_desktop.exe`. 같은 폴더의 DLL/data를 함께 유지한다.
- [사용 흐름과 조합 범위](xml-block-studio.md), [새 로컬 목업](../design/mockups/xml-block-studio/index.html).
- [Release manifest](../artifacts/releases/desktop-xml-block-studio-alpha8/manifest.json), [source/configuration manifest](../artifacts/releases/desktop-xml-block-studio-alpha8/source-manifest.json), [격리 APPDATA startup smoke](../artifacts/releases/desktop-xml-block-studio-alpha8/launch.json).
- 최종 manifest SHA-256: `284ac508189911f6cf18b3a99a592ceb9755864f9d9ddc6f78de31b3a04c4928`, 19개 파일. file_selector_windows_plugin.dll 및 flutter_pty2.dll 포함.

Desktop Engine은 `0.1.0-alpha.8`, contract `0.3.0-draft.2`, package SHA `4215662445780eeecd016ad6acf2a7b2c5e16b9a4e62cf8ae88e30ee0452e77f`, contract bundle SHA `638d48f182d12819ebd167d42457c7dceaa90928abb38c32a4867e3c94b10763`을 유지한다. 서버/Agent의 alpha.6 pin은 변경하지 않는다.

## 실제 Windows·Engine 인수

명령: `node scripts/flutter.mjs test --no-pub integration_test/xml_block_studio_test.dart -d windows --dart-define=QA_REPO=C:/workspace/QA/automated-qa-checker`.

[최종 테스트 로그](../artifacts/xml-block-studio/native-final-test.log)는 **exit 0 / 05:05 +1 All tests passed**다. [run-16739622 verification](../artifacts/xml-block-studio/native/run-16739622/verification.json)에 실제 report 경로와 PNG 실측 크기가 있다.

| 경로 | 실제 결과 |
| --- | --- |
| 파일 3개 가져오기·배치·핀 연결 → 조합 검증 → 명시 실행 | passed, 실제 PNG |
| 같은 조합을 직접 XML 문서로 명시 전환 → 검증·실행 | passed, 실제 PNG |
| 직접 XML 의도 assertion 불일치 | failed |
| 직접 XML 장시간 assertion 실행 중 취소 | cancelled |
| 실패 XML 파일 블록 조합 → 실행 → 원인 블록 보기 | failed, 당시 instance/asset 선택 |
| 장시간 XML 파일 블록 조합 실행 중 취소 | cancelled |

추가로 0.5배에서 실제 20 screen pixel 이동→40 document unit, pin 연결, layout undo의 실행 validation 유지, terminal/xml-block 두 차단 이유의 독립 해제, 재Provider 시작 시 composition/direct mode·assets·layout·sourceMap 복원, 과거 run의 같은 instance ID가 다른 asset으로 바뀐 경우 오선택 거부, native picker 주입 취소의 무변경을 확인했다. 가져오기·검증 시 run event는 없었다.

관리자가 별도 APPDATA `manager-picker-appdata`로 candidate Release의 실제 Windows OS picker를 독립 확인했다. 새 프로젝트/QA → XML 가져오기 → Windows `QA XML` Open dialog → Escape 취소 시 0블록/저장됨 유지 → 재열기 → 실제 login.xml 선택 → 라이브러리 7개 내부 동작/dirty 표시를 확인했다. 소유 PID 15656만 종료했고 기존 사용자 앱은 보존했다. 이 검증은 native test의 주입 picker 검사와 구분한다.

6run native 및 OS picker 검증 후 결과 요약의 표시 소유권만 보완했다. 조합 뒤 직접 실행하면 과거 파일명/원인 버튼도 숨기도록 `currentRunMapping`에 기존 owner/hash/runId 가드를 공통 적용했다. [추가 회귀](../artifacts/xml-block-studio/run-mapping-regression.log) 1 PASS, analyze 및 Release 재빌드/새 manifest startup smoke로 인수했다. 6run을 최종 표시 수정 후 다시 실행했다고 주장하지 않는다. 제품 source 차이는 [2개 파일 기록](../artifacts/xml-block-studio/final-source-delta.json)에 한정된다. 관리자가 이 영향 검증 범위를 승인했다.

최종 캡처:

- [1440×900 파일 3개](../artifacts/xml-block-studio/native/run-16739622/01-workspace-1440.png)
- [읽기 전용 원문](../artifacts/xml-block-studio/native/run-16739622/02-source-inspection.png)
- [1024×768 전체 보기](../artifacts/xml-block-studio/native/run-16739622/04-workspace-1024.png)
- [작은 화면 라이브러리](../artifacts/xml-block-studio/native/run-16739622/05-library-1024.png)
- [직접 XML 실패](../artifacts/xml-block-studio/native/run-16739622/06-direct-failed.png)
- [조합 실패·원인 파일·접힌 진단 상세](../artifacts/xml-block-studio/native/run-16739622/07-composition-failed.png)

## 회귀와 계약 감사

- `pnpm run verify`: exit 0, [로그](../artifacts/xml-block-studio/repository-verify.log). foundation/boundaries/types/package checks/OpenSpec/build/실제 browser routes 포함. 셸에 pnpm shim이 없어 저장소 artifact의 Corepack shim을 현재 프로세스 PATH에만 추가했다.
- `node scripts/flutter.mjs analyze --no-pub`: **No issues found**, [로그](../artifacts/xml-block-studio/analyze-final.log).
- 전체 Flutter 초회: 54 PASS, 기존 격리 candidate 1 SKIP, 영향 테스트 2 FAIL. [원래 로그](../artifacts/xml-block-studio/flutter-tests.log)를 보존했다. SKIP은 명시 승인된 별도 Engine candidate 환경을 요구하는 기존 테스트다.
- 두 실패를 정합했다. 기존 Desktop 테스트는 새 sidecar load 완료를 기다리고 직접 문서를 명시 선택한다. 기존 Flow 테스트는 새 방향 가드가 end→start 연결을 미리 거부하므로 source/edge 불변과 문서의 계속된 유효성을 확인한다. 수정 2개 파일 및 새 compiler/repository 파일의 **7검사 PASS**, [로그](../artifacts/xml-block-studio/flutter-targeted-final.log). 이 결과를 전체 초회가 처음부터 통과한 것처럼 기록하지 않는다.
- 새 단위 검사는 deterministic namespace/source map, 미연결·순환·target 차이·references 조립 거부, sidecar mode 복원·revision 충돌·손상 파일 보존을 확인했다.
- 기존 terminal_workspace_test의 실제 파일 경합/QA 경계·zoom 좌표·pin 방향 3검사는 전체 회귀에서 통과했다. 별도 `qa-desktop-interactive-terminal`의 미완료 실제 AI 편집 자동 반영 인수를 완료로 변경하지 않았다.
- Engine 담당 독립 읽기/실행 감사: `automated-qa-engine/artifacts/checker-xml-composition-review-20261111/review.json` 11case PASS. 동일 파일 2인스턴스·branch 라벨·captureText/captureValue·expectedRef·condition.variable·secret.ref 보존, 최종 secret+capture POLICY_DENIED 및 미지원 입력 거부, 설치 148파일 drift 0. VM 저장/late result/run map 경계는 `checker-xml-block-state-review-20261111/final-closure-review.json`에서 별도 읽기 확인했다.

## 빌드와 보존

`node scripts/flutter.mjs build windows --release --no-pub` exit 0([최종 빌드 로그](../artifacts/xml-block-studio/release-build-final.log)). `node scripts/record-xml-block-release.mjs`와 `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/smoke-xml-block-release.ps1` exit 0. startup smoke는 새 Release 소유 프로세스만 생성·종료했고 별도 APPDATA를 사용했다. 전체 source 파일 및 pubspec/lock/Windows plugin 등록/CMake 해시를 manifest로 고정했다. 표시 가드 전 candidate(manifest `8204999d5975cc7ada0549b03368ee6d4584797dcd446c7ffb7b6f8712233528`)는 관리자의 소유 프로세스 종료 확인 후 `artifacts/xml-block-studio/release-candidate-before-run-map-display`로 manifest/launch와 함께 보존했다.

file_selector `1.1.0` / Windows endorsed `0.9.3+6`을 정확히 사용한다. 첫 pub get은 Windows Developer Mode 미활성으로 plugin symlink 단계에서 exit 1이었다([기록](../artifacts/xml-block-studio/pub-get-initial.txt)). 시스템 설정을 변경하지 않고 resolved pub cache를 가리키는 repo ephemeral junction을 생성한 후 pub get를 다시 실행해 exit 0 및 공식 plugin 등록을 확인했다([로그](../artifacts/xml-block-studio/pub-get-final.log)). 해당 ephemeral 링크는 빌드 캐시이며 제품 Release에는 DLL로 포함된다.

이전 Release와 product-flow-review 목업의 baseline **85파일 drift 0**: [preservation.json](../artifacts/xml-block-studio/preservation.json). 첫 Material assertion/축소 이동 문제를 발견한 중간 native 폴더는 과정을 보존하는 실패·중간 자료다. 최종 인수에는 `run-16739622` 및 외부 Flutter exit 0 로그만 사용한다. 초기 artifact의 자체 status가 framework 예외를 덮을 수 있던 테스트 기록 순서도 수정했다.

HTML 목업은 [16검사 PASS](../design/mockups/xml-block-studio/verification.json), 1440×900/1024×768 캡처와 저장복원·직접 XML 편집 보존을 확인했다. 목업은 Engine 실행 증거가 아니다.
