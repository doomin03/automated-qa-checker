# 다중 터미널 · 공개 문서 작성 통합

2026-11-12, `qa-multi-terminal-workbench`, 기준 `main@3e73cd1`. 실제 다중 터미널·공개 작성 통합과 별도 alpha.9 Windows Release의 인수 기록이다. 기존 목업 완료, 기존 alpha.8 Release의 인수와 구분한다.

## 구현과 책임

`TerminalWorkbenchViewModel`은 최대 8개 보관 세션과 QA별 writer/epoch/barrier를 관리한다. 세션별 `TerminalSessionViewModel`은 별도 Service/Terminal/파일 사본/감시/후보를 소유한다. 화면을 접거나 다른 QA를 열어도 PTY를 종료하지 않는다. 명시 종료는 해당 세션만 정리하며 전체 종료는 진행 중 close Future에 합류한다. 정리 미확인은 종료 성공으로 표시하지 않고 해당 QA 작성 권한을 차단한다.

자동 반영 작성자는 QA마다 하나다. 살아 있는 이전 작성자는 검토 사본으로 남길 수 있으며 양도 때 epoch를 증가시킨다. QA·writer·문서 모드의 A→B→A, 늦은 compile/read, 새 GUI 편집은 후보를 폐기한다. 합성 모드에서 터미널 후보는 검토 상태로 보류하고 정상 합성 XML/sourceMap을 보존한다. 직접 문서 전환은 사용자가 명시한다. 파일 반영은 draft만 바꾸며 저장·QA 실행을 자동 요청하지 않는다.

도크는 세션별 입력/선택/스크롤 controller를 유지한다. 좁은 창은 한 pane 또는 bounded 작업 패널로 접근하며, 큰 창은 두 pane을 분할한다. 확대/접기와 PTY 종료는 별개다. 시작 cwd는 줄임/Tooltip으로 표시하고 셸의 현재 cd를 추적한다고 하지 않는다.

`DocumentAuthoringRepository`와 선택적 `EngineDocumentAuthoring` Service가 공개 templates/compose를 소비한다. Dart 실행 합성 컴파일러는 제거했다. 공개 Engine가 namespace/참조/전체 검증/XML/sourceMap을 생성하며 Checker는 파일 출처·UI 상태·응답 무결성·stale 적용을 관리한다. 구 runtime은 unsupported이며 로컬 fallback이 없다. sourceMap은 두 snapshot과 전체 생성 node 집합·원본 asset/node를 검증한다. CLI 공통 `details: []` 오류와 작성 진단 객체를 모두 안전하게 표시한다.

## 버전과 보존

- 앱 runtime `0.1.0-alpha.9`, 실행 계약 `0.3.0-draft.2`, 작성 계약 `0.1.0-draft.1`.
- archive SHA256 `09d0669d247c18cf88c7967156f801d15e2a871eb2e2b6d740ba245d7ca933e6`.
- execution bundle `b675005334c1345ef66b47e95eb8042ce45ade23941a1a0747ef3cfc485ea335`.
- authoring bundle `c38e5c1ce5caa0242cb6bdea81460252e6594f1a2e327388e0ef4ea4eda751a1`.
- `.local/desktop-engine/0.1.0-alpha.9/<archiveSHA>/installation.json`과 164개 payload를 관리자가 원본 승인 package와 독립 대조했다. 앱 전용 asset/pin만 갱신했다. 기본 서버/Agent alpha.6, alpha.8 설치·기존 Release는 별도로 보존한다. 서버와 runtime이 다르면 게시 호환성 오류를 표시하며 로컬 결과를 바꾸지 않는다.

## 집중 증거와 재현

명령은 저장소 root의 `node artifacts/multi-terminal/run-check.cjs <label> <flutter args>`로 실행했다. wrapper는 stdout/stderr 파일과 실제 child exit/signal receipt를 저장한다.

- `pool-6`: 7 PASS. 기존 단일 경로와 세션 분리/writer ABA/closing/cleanup/preview coalescing/합성 보호/guide 준비.
- `dock-4`: 1 PASS. 80줄 출력의 scroll 복원, 세션 입력/선택 분리, 지연 clipboard의 원래 세션 대상, 키보드 resize 및 작은 창 접근.
- `authoring-1`: 3 PASS. 설치 alpha.9 공개 compose 결정성/namespace/target·연결 오류, template hash, 구 runtime unsupported, 불완전 sourceMap 거절, sidecar 충돌 보존. 이 시험의 run 요청은 0이다.
- `focused-7`: 6 PASS, exit0. 생성 중 bindings 입력 잠금·후속 수정의 후보 무효화, 기존 XML과 같은 후보의 저장 실패를 실패로 유지, provider help 끝부분/64KiB 한도/비UTF8/timeout 및 기존 writer 회귀.
- `native-1`: alpha.8 시점의 초기 다중 PTY/1440·1024·800 화면 인수. 현재 alpha.9 템플릿/합성 실행 인수로 확대하지 않는다.
- `analyze-2`: integration fixture의 없는 dropdown.items getter와 lint로 실패했다. 실패 이력은 보존하며 정정 후 분석을 최종 근거로 기록한다.

## 사용과 한계

프로젝트/QA를 열고 하단 터미널 추가에서 공급자를 선택해 준비를 확인한 뒤 시작한다. Codex/Claude는 사본의 provider skill과 공개 Engine 예제/계약을 준비한다. 작성자로 지정한 직접 문서의 유효 파일만 자동 반영한다. 검토 사본은 자체 파일과 출력만 유지한다. 충돌은 원문을 보존한 상태로 명시 해결한다. Ctrl+C는 터미널 입력이며 앱 QA 취소 버튼과 별개다.

파일 메뉴의 **템플릿으로 새 QA**에서 고정 공개 template/bindings로 생성·검증하고 XML 미리보기 후 저장한다. 파일 블록 연결은 공개 compose로 검증한 뒤 사용자가 실행한다. 개인 credential은 앱에 복사하지 않는다.

PowerShell/cmd 실제 실행, Codex help 준비 확인과 Codex TUI 시작/실제 모델 요청은 서로 다른 인수다. Claude는 이 PC에 미설치이며 실제 모델 인수로 보고하지 않는다. skill 파일 준비는 CLI의 discovery/활용 성공을 보증하지 않는다. 일반 셸에는 AI skill 준비 배지를 붙이지 않는다. 기존 사용자/전역 설정·인증은 변경하지 않는다. 검토 역할과 cwd는 OS sandbox/read-only 권한을 뜻하지 않으며 터미널에서 사용자가 직접 실행한 임의 명령을 앱 QA 결과로 추적하지 않는다.

## 최종 통합 결과

`native-2.json`은 실제 exit0다. [최종 verification](../artifacts/multi-terminal/native/run-b2dc5845/verification.json)에 8캡처, 소유 HWND/client 크기와 MediaQuery 1440/1024/800/DPR1.5, 두 PID·사본·명령이 만든 파일, 포인터 크기 변경·확대 후 원래 높이 복원을 기록했다. 공개 template PASS와 두 동일 파일 블록을 합성한 PASS/FAIL/cancel의 네 run을 인수했고 관리자가 원본 events/result/sourceMap/PNG bytes·hash를 독립 대조했다. Codex는 업데이트 선택 TUI 시작까지만 확인하고 입력·설치 변경·모델 요청 없이 종료했다. 이후 dialog 간격12/제목·안내 문구와 braces lint 정합만 변경했으며 해당 폼 회귀에서 확인했다. native 전체를 다시 실행하지 않았다.

`app-tests-final.json`은 **77 PASS / 3 실패 / 1 조건부 skip, exit1**이며 실패 이력을 보존한다. 첫 두 실패는 단일 터미널의 옛 key/무세션 fixture와 manual coordinator fixture의 실제 CLI preview가 fake time에서 시작된 pending timer였다. 전자는 실제 fake session+세션별 key를 준비하고 controller/scroll/focus assertions를 유지했다. 후자는 명시 검증 fixture에 preview dependency를 분리하여 실제 IO를 제거했다. timer 무시/Zone.root 변경이나 제품 source 변경은 하지 않았다.

세 번째는 organization fixture의 origin 준비30초·종료15초 대기 실패다. 폐기된 초기 stderr 때문에 정확 지연 단계는 미확정이다. 동일 Node fixture의 독립 `auth-startup-probe.json`은 약7초/exit0/stderr0으로 통과했다. 앱 fixture에 bounded stderr 수집과 소유 child timeout 정리만 추가했으며 시간 제한이나 서버 코드는 바꾸지 않았다. 실제 조직 IdP 계정 인수로 확대하지 않는다.

`recovery-1`은 세 실패 복구를 포함해 6 PASS였으나 새 pending-spawn 검사의 닫힌 PTY pid getter 때문에 exit1이었다. spawn 당시 PID를 캡처하도록 fixture만 정정한 `spawn-close-final.json`은 exit0이며 close/dispose 두 경우 모두 소유 PID 종료를 확인했다. **합산 고유 회귀는 81 PASS / 1 조건부 skip**이다. 모든 테스트를 한 명령으로 exit0 받았다고 표시하지 않는다. skip은 별도 승인 candidate 환경을 요구하는 격리 Engine 시험이며 앱 alpha.9 공개 소비 실패가 아니다.

`analyze-acceptance.json`은 최종 테스트 수정까지 포함한 exit0/No issues found다. `source-freeze.json`의 앱·SDK·vendor·config 468파일은 동결 후 SHA drift0를 확인했다. `verify-final.json`은 저장소 `pnpm run verify` exit0이며 foundation/경계/lint/type/package/strict/build/browser/route 검증을 포함한다. 최초 `verify.json`의 nested pnpm PATH 실패는 보존하고 기존 로컬 toolbin을 PATH에 지정한 최종 명령과 구분한다. `verify:all` 전체 명령을 실행했다고 주장하지 않는다.

`build-release.json`은 Windows release build exit0이다. `node scripts/record-multi-terminal-release.mjs`와 `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/smoke-multi-terminal-release.ps1`로 별도 `artifacts/releases/desktop-multi-terminal-alpha9/Release` 전체 20파일을 기록하고 격리 APPDATA로 실제 Flutter window 초기화를 확인했다. manifest SHA는 `6f6a6fcdb82167ef746fd3c9ba2e32088cef34eb34bca397eb2ac920208d8c18`이다. 같은 상위 디렉터리에 앱·config/SDK/vendor source manifest와 `launch.json`이 있다. startup smoke는 새 Release 시작 증거이며 전체 사용자 여정은 앞선 native-2의 실제 제품 경로를 근거로 한다. 기존 Release를 덮거나 사용자 앱을 종료하지 않았다.

사용 순서와 저장된 alpha.8 설정에서 alpha.9 경로를 명시 선택하는 방법은 [다중 터미널 시작 안내](multi-terminal-quickstart.md)를 따른다. 최종 기계 판독 기록은 `artifacts/multi-terminal/acceptance.json`이다.
