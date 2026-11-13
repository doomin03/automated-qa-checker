# Tasks

관리 승인 후 구현 중이며 실제 인수가 끝난 단위만 완료 표시한다. 공용 Provider/Desktop/XML block은 별도 세션 Checker 소유로 확인됐다. 소유 파일과 부분 검증을 동결 인계하며 전체 UI/Release 인수는 해당 팀에서 이어간다. 기존 Release는 보존한다.

## 1. Windows terminal 기반

- [x] 1.1 xterm2 5.4.0 exact pin과 flutter_pty2 3.0.0 archive SHA/MIT vendor 및 승인된 Windows 표준핸들 1줄 fix를 전수 원본 diff로 확인하고, 실패했던 두 호스트의 isolated Windows spike에서 한글·공백 경로/인수, 실제 PTY, resize, 입력/출력, native DLL 빌드 및 license/dependency 목록을 검증한다.
- [ ] 1.2 소유 terminal Service/Repository/VM 및 Provider 정리를 구현하고 spawn 중 취소, root 선종료+child/pipe 잔존, close/done, scope 해제, 반복 20세션과 bounded 출력/접힌 dock을 실제 process fixture로 검증하여 수명/한도를 문서화한다.
- [ ] 1.3 설치 Codex interactive 진단·명시 시작·QA/session 고정·프로젝트/선택 문맥 전달을 연결하고 실제 로그인/승인 화면·한글 IME/붙여넣기·Ctrl+C·종료를 Windows에서 검증한다. Claude 미설치와 cleanup_unknown 경계를 안내한다.

## 2. 외부 문서 동기화

- [ ] 2.1 XML/JSON active format과 watcher→bounded bytes→immutable snapshot→공개 plan 경로를 구현하고 두 형식의 실제 자동 그래프 반영, partial write/atomic rename/삭제/잠금/oversize/path escape 및 정상 회복을 검증한다.
- [ ] 2.2 QA/session/document/settings/file hash guard, GUI dirty와 두 형식 충돌, 원자적 명시 교체/사본/undo를 구현하고 ABA·늦은 compile·수동 편집 이후 undo·노드 선택만 변경한 compile 수용을 회귀로 검증한다. 충돌 해결 사용법을 문서화한다.
- [ ] 2.3 RunVM 결과 보존과 독립 compile queue를 연결하고 terminal alive 상태에서도 명시 run이 가능하며 실행 중 변경 대기·종료 후 stale 거부·원 QA/snapshot PNG 귀속·자동 run 0을 실제 Engine fixture로 검증한다.

## 3. Blueprint 작업 공간

- [ ] 3.1 기본 Flow/어두운 grid/컴팩트 툴바/우측 속성/하단 resize terminal 및 보조 XML/JSON을 구현하고 1440×900·1024×768에서 dock 접힘/펼침 비중첩을 widget/native 캡처로 검증한다.
- [ ] 3.2 pan/zoom/fit·드래그·핀/곡선 edge·branch true/false·start/end 제약·기본 속성 폼을 연결하고 줌 좌표, 연결 gesture와 노드 drag 충돌, terminal focus Delete/Ctrl+C 격리를 회귀로 검증한다.
- [ ] 3.3 QA별 versioned layout sidecar를 구현하고 기존 metadata seed/원문·workspace v1 보존·좌표 이동 hash 불변·재열기 복원을 검증한다. 기존 회귀를 재사용하여 10/100/1000노드 접근/선택/fit 측정값과 실행 snapshot 상태 분리를 기록한다.

## 4. 실제 사용자 경로와 별도 배포

- [ ] 4.1 isolated QA 폴더에서 실제 Codex terminal→XML 및 JSON 편집→자동 GUI 반영→노드/속성 확인→명시 실행/PASS·FAIL·PNG 경로를 Windows에서 검증하고 전체 canvas 및 선택 속성+terminal 열린 캡처로 관리 시각 검토를 받는다. fixture/실제 CLI 검증을 구분한다.
- [ ] 4.2 analyze/관련 전체 app 회귀·저장소 필수 검증을 수행하고 별도 desktop-terminal-blueprint-alpha8 Release 전체 파일/native dependency manifest 및 실행 smoke를 기록한다. 기존 Release/사용자 실행 PID/workspace·Engine/서버 pin·목업의 보존을 확인한다.
- [ ] 4.3 시작/종료·CLI 승인·파일 자동 반영/충돌·명시 실행·현재 제약과 재현 가능한 demo 절차를 문서화하고 새 OpenSpec strict/완료 증거·실제 명령과 미완료를 최종 인계한다.

## 2026-11-11 부분 인수

- 1.1: `patched-test.log`와 `patched-windows.log` PASS. vendor checker는 172파일을 확인했다. archive/MIT/diff는 `docs/third-party/flutter-pty2-3.0.0.json`, 의존성은 `apps/app/pubspec.lock`에 있다.
- 1.2 부분: `owned-native-final.log` 2 tests PASS. 20세션, 1MiB 출력, 부모 선종료 후 자식 종료, Unicode/quoted args/resize를 확인했다. 전체 UI 수명 인수는 남았다.
- 2.2/3.2/3.3 부분: `boundary-final-3.log` 3 tests PASS. 최종 read 뒤 문서/QA/Flow revision, 사본 저장 중 새 편집, 초기 layout 병합/undo 보존, 0.5줌 pointer 좌표, branch 핀/start-end 방향을 확인했다.
- `ui-2.log`는 Material/ListTile assertion 실패다. 소유 위젯 수정 후 widget PASS이며 native 전체는 미재실행이다. 시각 배치 수용과 제품 인수를 구분한다.
- 실제 AI 파일 편집/두 형식 자동 반영/실행, 1024 전체 UI, 새 Release는 미완료다. 상세 기록은 `docs/validation-terminal-blueprint.md`, 소유 파일/로그 SHA는 `artifacts/terminal-native-spike/partial-acceptance.json`이다.

