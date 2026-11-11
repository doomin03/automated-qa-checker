# Design

## Context

동기와 범위는 proposal.md를 따른다. 기준은 main/4f97e920a399d4a5434ab1ecbe44c4d879d397a4 및 기존 dirty 구현이다. `apps/app/lib/features/ai_authoring/services/ai_cli_service.dart`는 비대화 `codex exec`의 pipe/JSONL 후보 생성이며 PTY가 아니다. `app/workbench/views/desktop_workspace_view.dart`는 XML 기본 화면과 AI 폼을 조합한다. 기존 Flow VM은 `flow.metadata.presentation.positions`를 읽고 쓰며 단순 연결선을 표시한다. Provider composition root/Workbench coordinator 및 immutable Engine 실행 snapshot은 재사용한다.

현재 pubspec에는 provider/crypto/HTTP SDK만 있고 terminal/PTY 의존성이 없다. Flutter 3.47.5/Dart 3.13.4 및 Windows C++ 빌드 도구가 기존 Release에서 확인됐다. 이는 새 native 패키지의 정상 동작 증거는 아니다. 현재 Desktop runtime alpha.8/contract 0.3.0-draft.2, 기본 서버/Agent alpha.6을 유지한다.

## Goals / Non-Goals

**Goals:** 실제 interactive CLI와 실제 블록 조작을 한 QA 작업 공간에서 연결한다. 파일 변경이 GUI에 자동 반영되면서 문서 원문, 미저장 편집, 실행 snapshot의 소유권을 보존한다. Windows 프로세스/PTY 종료와 Flutter 수명을 검증한다.

**Non-Goals:** 범용 터미널 에뮬레이터 자체 개발, 새 AI API/키 저장, 임의 Flow shell action, 자동 QA 실행, Engine DSL 변경, Claude 설치/인수 완료, 서버 버전 승격. 기존 목업은 참고이며 수정하지 않는다.

## Decisions

### D1. 검토된 renderer/PTY 패키지와 좁은 소유 인터페이스

`xterm2 5.4.0` exact pin과 `flutter_pty2 3.0.0` 원본 archive를 보존한 vendor를 채택했다. 두 호스트에서 원본 Windows 표준 핸들 상속 실패를 재현했고, 관리 승인된 STARTF_USESTDHANDLES 한 줄 보완 후 native spike가 통과했다. 전수 diff/SHA는 아래 증거와 `docs/third-party/flutter-pty2-3.0.0.json`에 고정한다. renderer는 ANSI/UTF-8/CJK/IME·선택·스크롤·입력을 담당하고 terminal service는 spawn/read/write/resize/close 및 작업 identity만 담당한다. View가 process/file IO를 호출하지 않는다. controller/focus는 View 수명, 세션/상태/프로세스는 Provider 수명이다. 도킹 접기는 process를 종료하지 않는다.

원본 flutter_pty 0.4.2에는 Windows 문자열 변환/quoting과 종료 경계 문제가 독립 소스 감사에서 발견되어 제외한다. flutter_pty2 3.0.0 archive에는 UTF16 변환·인수 quoting, suspended spawn→JobObject 배정→resume, 분리 read/write/wait/close worker, bounded queue가 있다. Windows는 여전히 experimental이므로 문서의 기능 소개를 실제 보장으로 취급하지 않는다. spike 실패 시 원인과 최소 ConPTY bridge 대안을 관리 검토하며 권한 우회/무관 패키지 수정을 하지 않는다.

조사 출처(2026-11-10): [xterm2 5.4.0](https://pub.dev/packages/xterm2/versions/5.4.0), [flutter_pty2 3.0.0](https://pub.dev/packages/flutter_pty2/versions/3.0.0), [ConPTY session](https://learn.microsoft.com/en-us/windows/console/creating-a-pseudoconsole-session). 정확 archive SHA 및 감사 경로는 아래 조사 증거에 기록한다. 새 라이브러리의 transitive dependency/license/native DLL 목록은 spike에서 lockfile과 Release manifest로 확인한다.

### D2. 명시적으로 시작한 QA 전용 interactive CLI

설치 경로와 지원 옵션을 진단하고, 사용자가 시작을 누를 때만 `codex`를 subcommand 없이 정확한 인수 배열로 실행한다. 우선 인수 인자는 `--no-daemon --no-alt-screen -C <sessionDir> -s workspace-write -a on-request`이다. shell 문자열 조립/전역 설정 변경/자동 권한 우회 없이 기존 CLI 인증을 사용하고 신뢰·로그인·승인 프롬프트를 terminal에 표시한다. 기존 exec의 read-only/disable-tool 설정은 파일 수정용 interactive 모드에 재사용하지 않는다. cwd와 CLI sandbox는 OS 전체 격리 보증이 아니며 CLI가 사용자가 승인한 도구를 수행할 수 있음을 시작 설정에서 설명한다. 앱은 출력의 코드/명령을 별도로 실행하지 않는다.

초기 단위는 앱당 하나의 활성 세션이다. sessionDir는 사용자 workspace 아래 QA별 고유 세션이며 projectId/qaId/sessionId에 고정한다. 다른 QA를 열 때 기존 terminal을 조용히 재바인딩하지 않고 종료 또는 이전 QA로 돌아가기를 선택한다. `scenario.xml` 또는 `scenario.json`, 공개 `aqa schema/template`와 프로젝트 지침/QA 요청/선택 node 및 인접 edge 문맥 파일을 만든다. 선택 문맥 갱신은 파일 또는 사용자 명시 paste 액션이며 명령을 자동 제출하지 않는다. workspace DB/다른 QA 정본을 terminal 작업 파일로 직접 제공하지 않는다. 비밀키와 원문 terminal 로그를 자동 영속/telemetry 전송하지 않는다. Claude는 미설치 진단까지만 하며 지원 완료로 표시하지 않는다.

### D3. 종료·출력·입력의 별도 수명

PTY output은 접힌 화면/스크롤 정지와 무관하게 drain한다. UTF8 incremental decode, 유한 scrollback(기본 10,000줄), bounded native 입력 queue와 붙여넣기 크기 제한을 둔다. 초과는 명시 거부하며 잘린 명령을 자동 입력하지 않는다. OSC52 clipboard, zmodem 파일 전송, 출력 URL 자동 열기를 활성화하지 않는다. 선택 복사/붙여넣기는 사용자 액션이다. 크기 변경은 셀 단위 rows/columns를 실제 PTY에 전달한다.

Ctrl+C는 PTY 입력 `0x03`이며 취소 확정/Windows POSIX signal로 간주하지 않는다. 종료 버튼과 scope dispose는 새 입력/시작을 차단하고 owned 세션의 `close()`를 await한다. root child의 `processExit`와 출력 EOF를 포함한 `done`은 별개다. root가 먼저 종료했을 때 `kill()`만 호출하면 Job 자식 정리가 빠질 수 있으므로 최종 close 경로를 항상 사용한다. 유한 종료 예산(기본 10초와 drain 2초) 뒤 미확증이면 `cleanup_unknown`과 후속 시작 차단을 표시한다. 다른 사용자 CLI/프로세스를 이름으로 종료하지 않는다. 초기 spawn await 중 취소도 session epoch로 막는다.

### D4. 파일은 입력, 검증된 snapshot은 GUI의 투영 근거

파일 watcher는 힌트다. parent directory watcher+debounce와 변경 감지 보완/수동 새로고침을 사용하며 byte hash를 기준으로 처리한다. regular UTF8 파일/최대 1MiB/세션 root containment를 검사하고 symlink/junction 바깥 참조를 수용하지 않는다. 안정된 두 번의 읽기를 거친 bytes를 고유 `snapshot.xml` 또는 `snapshot.json`으로 저장한다. 확장자를 유지하고 공개 `aqa plan ... --diagnostics stderr`를 호출한다. compile은 비실행이며 기존 RunVM.validate가 지우는 결과 영역을 건드리지 않는 별도 서비스/단일 최신 요청 queue로 수행한다.

완료 후 sessionId/QA id/문서 revision/설정 revision 및 현재 파일 bytes hash를 재대조한다. 단순 노드 선택 변경은 compile을 무효화하지 않는다. 선택 문맥 ticket은 선택 대상에 대한 사용자 명령에만 적용한다. GUI가 마지막 동기화 이후 수정되지 않았으면 원문을 편집기에 자동 반영하고 plan의 전체 Blueprint로 Flow를 갱신한다. workspace 저장 전에는 변경 상태를 표시하며 파일 변경마다 승인 폼을 띄우지 않는다. projection은 원문의 알 수 없는 필드를 버려 재작성하는 근거가 아니다. 지원하지 않는 편집 기능은 명시적 읽기 전용으로 두고 전체 원문을 보존한다.

부분 쓰기·문법 오류·파일 삭제/잠금·크기 초과는 이전 유효 그래프와 진단을 함께 보여준다. 그 그래프가 현재 파일의 정상 상태인 것처럼 표시하거나 실행을 허용하지 않는다. 후속 유효 파일로 자동 회복한다. XML/JSON은 하나의 활성 원본 형식을 선택하며 format 변환은 공개 import/export+동일 plan hash로 확인한다. 두 파일 동시 변경은 시각/확장자 우선순위로 해결하지 않고 충돌로 둔다.

### D5. GUI dirty, 자동 동기화와 실행 경계

GUI XML/Flow의 미반영 수정과 외부 파일 변경이 겹치면 base/GUI/file을 보존하고 자동 적용을 멈춘다. 사용자에게 파일 수용, GUI 유지 후 명시적 파일 교체, 각각 사본 보존을 제공한다. 교체 직전 hash/revision을 다시 검사하고 기존 atomic 저장 경로를 사용한다. Engine `--out`은 exclusive create이므로 기존 scenario 파일 덮어쓰기 수단으로 사용하지 않는다. 변경 후 undo는 적용 직후 revision에서만 가능하고 이후 수동 편집이 있으면 덮어쓰지 않는다.

실행 중 화면은 실행 시작 snapshot에 고정하고 외부 변경은 대기 표시한다. 실행 종료 후에도 revision/hash가 일치할 때만 대기 변경을 적용한다. 앱의 실행 기능은 항상 명시 버튼과 불변 snapshot을 사용하며 live terminal 파일을 직접 run하거나 파일 변경으로 자동 run하지 않는다. AI용 프로젝트 지침에도 정의 편집만 요청한다. 실제 interactive CLI에서 사용자가 직접 실행한 명령까지 앱이 통제하거나 결과를 수집한다고 보증하지 않는다. terminal session이 살아 있다는 상태와 QA Engine busy는 분리하여 terminal이 열려 있어도 앱 검증/명시 실행이 가능하다. 과거 결과와 PNG는 원 QA/runId/snapshot 소속을 유지한다.

### D6. 실제 Blueprint 캔버스와 실행 의미 분리

기존 `design/mockups/desktop/blueprint-workspace/screenshots/03-workspace.png`의 컴팩트 툴바·중앙 grid·타입 header/핀·우측 속성을 최소 시각 참고로 사용한다. Flutter 실제 구현은 중앙 canvas, 접는 프로젝트 탐색, 우측 속성, 하단 resize/collapse terminal을 배치한다. 1440×900/1024×768에서 viewport 밖 페이지 스크롤이나 dock 중첩 없이 패널 내부를 스크롤한다. JSON 입력줄/팔레트는 canvas를 잠식하지 않는다.

pan/zoom/fit, 노드 drag, input/output pin 드래그 연결, 곡선 edge 및 true/false branch 라벨을 제공한다. 노드 ID/참조/연결 변경의 렌더링 불변식을 검사하고 Engine compile이 최종 실행 권위다. 일반 액션 속성은 기본 폼으로 편집하고 JSON은 보조이다. 실행 색/상태는 run snapshot과 일치할 때만 적용한다.

좌표는 앱 presentation 상태다. 기존 공개 metadata.presentation.positions 입력은 비파괴적으로 읽어 seed할 수 있으나 이번 새 layout 저장은 QA별 versioned presentation sidecar로 분리한다. 기존 workspace v1 strict unknown-field 정책과 원문 metadata를 변형하지 않는다. 노드 이동은 원문/execution hash를 바꾸지 않으며 새 node/삭제 node만 좌표를 갱신한다. 이 선택은 기존 metadata 사용을 금지하는 의미가 아니라 터미널 외부 수정과 layout 이동의 불필요한 충돌을 줄이기 위한 것이다. 의미 변경에 대한 undo/revision과 layout undo/revision을 구분한다.

10/100/1000 노드의 build/pan/selection/fit을 계측한다. gesture마다 XML parsing/전체 JSON 복제를 반복하지 않고 geometry/state 캐시를 분리한다. 기존 1000-node debug 비용을 release 60fps 보장으로 확대하지 않으며 가상화 전면 재작성은 측정 후 별도 검토한다.

## Risks / Trade-offs

- Windows experimental native 패키지 → 실제 한글/공백 경로·인수·자식 종료·resize·반복 세션·handle 검증 전 제품 통합 완료 금지.
- 동시 쓰기/파일 교체 → 이벤트를 저장 완료로 간주하지 않고 immutable bytes/compile/hash/revision 재검사, 충돌 사본 보존.
- CLI가 만드는 자식/승인 도구 → Job 소유 종료 실제 검사, 정상 CLI 승인 화면 유지, 분리된 프로세스 종료를 무조건 보증하지 않음.
- 자동 GUI 반영 → 유효 무충돌 경로만 자동화하고 저장/실행을 구분; 오류 상태에서 이전 그래프가 최신처럼 보이지 않게 함.
- renderer escape sequence/출력 폭주 → 제한된 부가 기능, bounded buffers와 drain 분리; 터미널 로그에 자격증명 노출을 추가하지 않음.

## Migration Plan

1. strict와 관리 검토 후 exact-pin dependency/native spike를 수행한다. 여기까지 제품 사용성 완료로 표시하지 않는다.
2. 단일 세션/파일 compile/충돌 보호를 기능별 MVVM으로 연결하고 실제 Blueprint canvas를 적용한다.
3. 격리 QA 폴더에서 실제 Codex TUI→XML/JSON 수정→자동 그래프→명시 실행/PNG를 Windows에서 인수한다. fixture 테스트와 실제 CLI 인수를 구분한다.
4. 별도 `desktop-terminal-blueprint-alpha8` 전체 Release/manifest/시작 안내를 만든다. 현재 `desktop-ai-alpha8`와 실행 중 PID 17580 및 사용자 workspace를 종료/변경하지 않는다. 서버/Agent/고정 Engine/목업도 보존한다. rollback은 기존 Release 실행으로 가능해야 한다.

## Research Evidence

독립 감사 원본: `C:/workspace/QA/coordination/artifacts/desktop-terminal-20261110/source-review.md`. 같은 폴더에 pub metadata, 다운로드 archive와 추출 원본이 있다. pub API 값과 다운로드 bytes SHA256을 대조했다.

- flutter_pty2 3.0.0 archive SHA256: `9802f793109fe7241cc172780571d501e50db6b247624a6b7c4df889bb9cbfe6`.
- xterm2 5.4.0 archive SHA256: `da8f15c6ecd0a0e06ca11f8d9fe55d6f1e686823ff084ad82fccf9a5fd1f8c00`.
- PTY 조사 파일: `src/windows/pty_windows_spawn.c`, `pty_windows_commandline.c`, `pty_windows_environment.c`, `pty_windows_session.c`; `lib/src/internal/ffi_driver.dart`, `ffi_session.dart`, `native_library.dart`; `lib/src/pty_spawn_options.dart`, `hook/build.dart`.
- renderer 조사 파일: `lib/src/terminal_view.dart`, `lib/src/ui/custom_text_edit.dart`.

archive hash는 pubspec.lock 및 vendor 원본 검증과 native spike의 입력 기준이다. 아래 실제 설치/실패 관측은 설계 당시 조사와 구분한다.

관리 예외 승인: `apps/app/vendor/flutter_pty2`는 정확 3.0.0 archive의 원본과 MIT를 보존하는 path dependency이며 Windows spawn에 `STARTF_USESTDHANDLES` 한 줄만 수정한다. 별도 provenance와 원본 대비 전수 SHA/diff를 기록한다. pub cache는 수정하지 않는다. upstream 수정 버전이 같은 native 회귀를 통과하면 vendor 제거/정확 hosted pin으로 복귀를 검토한다. 현재 rollback은 이 vendor와 해당 dependency를 제거하고 기존 Release를 사용하는 것이며 미검증 hosted 3.0.0으로 자동 fallback하지 않는다.

### Native spike observation (2026-11-10)

exact pin 설치와 MSVC DLL build/load는 성공했으나 Flutter tester와 Windows GUI integration 두 호스트에서 Node stdin이 TTY가 아니고 출력이 PTY에 연결되지 않는 실패를 재현했다. `artifacts/terminal-native-spike/first-failure.txt`, `gui-failure.txt`는 원본 tool output에서 추출한 실패 기록이다. upstream source의 STARTUPINFO가 zero인 상태에서 `STARTF_USESTDHANDLES`를 설정하지 않아 redirected 부모 표준핸들이 자식에 복제되는 현상과 일치한다. [Microsoft Terminal discussion 15814](https://github.com/microsoft/terminal/discussions/15814), [GetStdHandle attach/detach](https://learn.microsoft.com/en-us/windows/console/getstdhandle)를 근거로 NULL 표준핸들과 해당 flag를 명시하는 최소 수정이 후보이다. pub cache/상위 원본은 변경하지 않으며 관리 승인 후 정확 archive 기반 vendor+patch/provenance로 검사한다. 현 단계에서 native 지원 완료로 표시하지 않는다.
