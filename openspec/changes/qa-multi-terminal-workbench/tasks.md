# Tasks

제품 구현과 이 change의 12개 인수를 완료했다. 기존 목업 완료와 본 제품 tasks를 혼합하지 않는다. 관리 승인 alpha.9를 별도 앱 경로에 설치했고 164개 payload hash 독립 대조를 통과했다. 기존 alpha.6 서버와 alpha.8 설치/Release는 보존한다. Claude 미설치·Codex 모델 미요청·실제 조직 IdP/모바일 기기 미인수는 완료 범위 밖이며 아래 증거와 검증 문서에 구분한다.

집중 근거: `artifacts/multi-terminal/pool-6.json` 7 PASS, `dock-4.json` 1 PASS, `authoring-1.json` 3 PASS. 초기 `native-1.json`은 alpha.8 시점 두 PTY/화면 인수이며 alpha.9 작성/실행 통합 인수와 구분한다. `analyze-2.json`은 integration fixture getter 오류/lint로 실패한 이력이며 최종 `analyze-acceptance.json` exit0를 인수 근거로 사용한다.

## 1. Session foundation

- [x] 1.1 세션 runtime/pool과 DI 소유권을 구현하고 서로 다른 두 서비스 callback·buffer·watcher, spawn 중 종료·전체 dispose·8세션 상한 회귀 및 구조 문서를 남긴다.
- [x] 1.2 provider별 경로/옵션 준비 상태와 문맥 생성을 구현하고 실제 PowerShell/cmd·Codex help/start 및 Claude missing/설정 경로를 검증한다. 설치/로그인/실제 모델 인수 범위를 문서화한다.
- [x] 1.3 세션별 파일 감시/compile queue와 canonical cwd 보호를 연결하고 동시 출력·한쪽 종료·부모 선종료·cleanup_unknown 유지의 native/fixture 증거를 기록한다.

## 2. Writer and document safety

- [x] 2.1 QA writerEpoch/activation ticket/명시 양도와 keyed run blockers를 구현하고 A→B→A·살아 있는 검토 전환·closing/unknown 양도 거부·서로 다른 기능 차단 집계를 검증한다.
- [x] 2.2 최종 read 후 모든 stamp 검사·GUI/Flow dirty·실행 중 후보·양쪽형식·undo·사본 보존을 구현하고 지연 compile/read/사본저장 중 편집·QA 삭제/전환 회귀와 정책 설명을 남긴다.

## 3. Dock experience

- [x] 3.1 실제 세션 추가/이름/전환/종료·split·접기/확대·keyboard/pointer resize를 구현하고 세션/controller 독립·한글/단축키 focus·미제출 입력·scroll/editor 보존 widget 회귀를 통과한다.
- [x] 3.2 1440/1024/800/낮은높이 및 text1/1.25/1.5의 geometry·접근 대안·두 실제 PTY resize를 인수하고 대표 native 캡처를 관리 시각 검토에 제출한다.

## 4. Public Engine authoring integration

- [x] 4.1 Engine 확정 template/compose 계약 및 관리 승인 version/full SHA를 기록하고 별도 앱 설치의 payload 전수 hash/공개 CLI 인수, 구 runtime unsupported를 검증한다. 근거: app `engine-runtime-pin.json`, 별도 `installation.json`, `authoring-1.json` 및 관리 `coordination/multi-terminal-implementation-20261112/checker-install-verification.json`(164개). execution draft.2 / authoring 0.1.0-draft.1; archive SHA `09d0669d247c18cf88c7967156f801d15e2a871eb2e2b6d740ba245d7ca933e6`.
- [x] 4.2 새 QA template 및 파일 블록 compile을 공개 작성 Service/Repository로 이관하고 기존 지원 fixtures의 namespace/참조/sourceMap/진단/결정성·late 결과·workspace 자료 보존을 검증한다.
- [x] 4.3 공개 생성/합성 XML로 실제 Chromium PASS/FAIL/cancel·증거/원본 블록 표시를 인수하고 자동 실행0 및 직접 XML 경로 회귀를 기록한다.

## 5. Integrated acceptance

- [x] 5.1 최종 source에서 app:analyze/app:test 및 저장소 verify/strict/경계 검증을 실행하고 실제 exit와 기존 재사용 증거/환경 제한을 구분한다.
- [x] 5.2 별도 Windows Release/build·소스/의존/전체파일 manifest·native startup, 기존 목업/294파일·runtime/Release 보존과 사용 안내를 완성하고 관리 인수를 기록한다.

## 현재 완료 근거

- 1.1/1.3: `app-tests-final`의 pool 최대8/제거 후 슬롯복구·구독 분리 및 기존 native20세션/부모 선종료 자식 정리 PASS, `spawn-close-final` 실제 지연 spawn 중 close/dispose 소유 PID 종료 PASS. full 전체 exit는 아래 통합 인수와 별도로 구분한다.
- 2.2: `app-tests-final` terminal_workspace의 최종read/compile/사본저장 중 편집·QA 전환·양식/크기/root 보호·undo 회귀 PASS. `focused-7` writer와 composition mode ABA 경계를 함께 확인했다.
- 1.2: `focused-7` provider help/출력한도/timeout과 guide 준비, `native-2` Codex TUI 시작·PowerShell/cmd 실제 파일 receipt. Claude missing이며 로그인/모델/skill discovery 성공을 주장하지 않는다.
- 2.1: `focused-7` writer ABA·살아 있는 양도·closing/cleanup barrier·QA 소속 및 mode ABA 회귀.
- 3.1–3.2: `dock-4` controller/scroll/clipboard/키보드/글자배율, `native-2` 실제 pointer resize·확대 후 높이복원·두 PID·1440/1024/800 DPR1.5/8캡처. 관리 시각·증거 인수 PASS.
- 4.2: `authoring-1` 결정성/sourceMap/오류/sidecar, `focused-7` 폼 입력 변경/저장 실패, `native-2` 실제 template 저장·두 블록 compile. Dart compiler fallback 삭제.
- 4.3: `native-2` template PASS 및 composition PASS/FAIL/cancel 네 run·sourceMap·PNG. `artifacts/multi-terminal/native/run-b2dc5845/verification.json`; 관리 독립 `coordination/multi-terminal-implementation-20261112/native-verification.json`.
- 5.1: `analyze-acceptance`/`verify-final` exit0. 전체 `app-tests-final` 77 PASS/3 FAIL/1 skip exit1을 보존하고, fixture 정정 후 `recovery-1` 및 `spawn-close-final` 집중 복구로 고유 81 PASS/1 조건부 skip. 단일 전체 명령의 exit0로 바꾸어 보고하지 않는다. 제품 source 동결 468파일 drift0. 상세 `docs/validation-multi-terminal-workbench.md`.
- 5.2: `build-release` exit0, `artifacts/releases/desktop-multi-terminal-alpha9/`의 Release20파일·앱78/SDK209/vendor172/config14/source-freeze468 manifest와 `launch.json`. 관리 독립 `coordination/multi-terminal-implementation-20261112/release-verification.json` PASS, 기존294+18파일 drift0. 사용 안내 `docs/multi-terminal-quickstart.md`. 실제 모델/Claude 미인수 한계를 유지한다.
