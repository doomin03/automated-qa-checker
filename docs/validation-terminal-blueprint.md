# Interactive terminal / Blueprint 부분 검증

2026-11-11 Checker main / `4f97e920a399d4a5434ab1ecbe44c4d879d397a4` 및 기존 dirty 작업 기준이다. `qa-desktop-interactive-terminal`은 구현 중이며 전체 인수나 새 배포 완료가 아니다.

## 통과한 검증

- `xterm2 5.4.0`, `flutter_pty2 3.0.0` vendor 원본과 MIT를 보존했다. Windows `STARTF_USESTDHANDLES` 한 줄만 변경했다. `node scripts/check-terminal-vendor.mjs`는 원본 171파일과 provenance 1파일을 대조해 PASS했다. archive/파일별 SHA는 `docs/third-party/flutter-pty2-3.0.0.json`, 의존성은 `apps/app/pubspec.lock`에 있다.
- 원본 실패는 `artifacts/terminal-native-spike/first-failure.txt`, `gui-failure.txt`에 남겼다. 수정 후 `patched-test.log`, `patched-windows.log`는 PASS다.
- `node scripts/flutter.mjs test test/pty_native_test.dart --concurrency=1`: `owned-native-final.log`, 2 tests PASS. Unicode/공백/quote 인수, 실제 TTY, resize, 입력, 20세션, 1MiB 출력 drain, 부모가 먼저 종료한 자식의 Job 종료를 확인했다. 실제 한글 IME UI 인수는 별도다.
- `node scripts/flutter.mjs test test/terminal_workspace_test.dart --concurrency=1`: `boundary-final-3.log`, 3 tests PASS. 파일 자동 반영/invalid 보존/충돌/교체/hash/root 보호, 최종 비동기 read 뒤 문서·QA·Flow revision 확인, 사본 저장 중 새 편집 보존, 초기 layout read 중 이동 좌표와 기존 좌표 병합 및 초기 undo 차단을 포함한다. 노드 선택만으로 Flow revision은 바뀌지 않는다.
- 실제 pointer gesture로 0.5 zoom에서 화면 20px에 해당하는 local 40px 이동을 검증했다. branch true/false 핀과 start/end 방향 제약, 선택 속성 Material도 확인했다. 핀 연결 전체 gesture/terminal focus 키 격리/1024 인수는 남았다.
- 소유 6파일 targeted Dart analyzer는 `owned-analysis.log`에서 모두 No issues found, exit 0이다. 해당 change strict, vendor checker, 소유 diff-check도 PASS다. 전체 analyze/verify/Windows build를 재실행한 것은 아니다.

## 실패와 제한

`ui-2.log`는 ListTile이 ColoredBox 아래에서 Material을 찾지 못한 assertion으로 실패했다. Blueprint 속성 패널에 Material을 추가한 뒤 widget은 통과했지만 Windows native 전체 재실행은 보류했다. 관리자가 `artifacts/windows-terminal/run-1ea00e4d`의 배치를 수용한 것은 전체 데이터·실행 인수와 다르다.

`boundary-canvas.log`에는 테스트 코드 삽입 오류와 동시 변경 중 외부 `xml_block_studio.dart` 컴파일 오류가 함께 있었다. `boundary-canvas-2.log`는 fixture 문서 초기화, `boundary-final.log`와 `boundary-final-2.log`는 두 번째 widget의 catalog 초기화 미완료로 실패했다. 최종 fixture는 공개 계약을 명시적으로 주입하고 public addNode를 호출한다. 단독 `gesture-probe-2` PASS를 전체 성공으로 대체하지 않았다.

2026-11-11T01:29:58Z 공용 Provider/Desktop 화면의 다른 세션 변경을 확인했고 `shared-source-observation.json`에 hash를 기록했다. 이후 별도 세션 Checker가 공용 DesktopView/AppProviders/XML block 소유자임을 확인했다. 최종 통합과 Release는 해당 팀이 진행한다. 우리 소유 파일과 부분 검증을 동결 인계한다.

`xml_block_workbench_view_model.dart`는 소유 확인 전 폴더 format 과정에서 형식 변경이 발생했다. 정확한 이전 bytes가 없어 임의 복원하지 않았다. 이후 format은 소유 파일 목록으로 제한했다. 파일 삭제나 복원은 하지 않았다.

실제 Codex terminal 시작/TUI 표시까지 확인했지만 파일 편집 완주는 미완료다. 저장소 밖 전용 QA session의 정확한 경로만 신뢰하는 정상 CLI 화면은 관리 승인 범위다. 저장소/홈 전체 신뢰나 설정 직접 편집은 허용하지 않는다. Claude 미설치, 실제 IME, XML/JSON 두 형식의 실제 AI 편집→GUI→명시 run/PASS·FAIL·PNG, 1024 전체 화면, 새 Release는 남아 있다.

기존 desktop-ai-alpha8 Release, Engine alpha8 설치, 기본 서버/Agent alpha6 pin을 승격하지 않았다. 정리 미확증은 cleanup_unknown으로 남고 재시작을 차단하며 정상 종료로 합성하지 않는다.

위 로그는 모두 `artifacts/terminal-native-spike/` 아래에 있다. 소유 14파일 SHA, 최종 로그 SHA, tasks 1/12 완료 상태는 `partial-acceptance.json`에 기록했다.
