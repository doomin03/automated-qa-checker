# 프로젝트·받은 QA 홈 검증 — 2026-11-11

Checker `main`, HEAD `4f97e920a399d4a5434ab1ecbe44c4d879d397a4`의 기존 미커밋 작업을 보존하고 승인된 `qa-desktop-project-received-home`을 적용했다. Engine 저장소/설치/pin, 이전 Release를 변경하지 않으며 commit/push는 하지 않았다.

## 실제 Windows와 API

명령: `node scripts/flutter.mjs test --no-pub integration_test/project_home_test.dart -d windows --dart-define=QA_REPO=C:/workspace/QA/automated-qa-checker`.

[최종 native 로그](../artifacts/project-home/native-fourth.log): **exit 0, 01:14 +1 All tests passed**. [run-7a4c81ce verification](../artifacts/project-home/native/run-7a4c81ce/verification.json)에 실제 결과·report·version·QA identity와 PNG 치수를 기록했다.

- 기본 `engine-runtime.json`과 `.local/engine`의 alpha.6으로 실제 Nest/SQLite 서버를 격리 시작했다. author의 초안을 별도 reviewer가 검수하고 QA 버전 3개와 Suite를 발행했다.
- Windows에서 서버 프로젝트/게시 버전/Suite를 조회하고 Suite 고정→case 선택→대상 로컬 프로젝트에 신규 QA 수신을 수행했다. 원문 bytes/hash, Suite 출처, 영속 direct mode를 확인했다.
- Desktop의 기존 alpha.8 공개 Engine으로 검증과 실제 브라우저 실행이 **passed**였다. 16개 event와 실제 PNG를 생성했다. 결과 자동 게시는 켜지 않았고 alpha.6 서버를 승격하지 않았다.
- 미저장 홈 복귀의 취소/버리기, 로컬 사본 목록, 새 Provider 시작 뒤 XML/출처/direct mode 복원, workspace v1 형식 보존을 확인했다.
- 앱 오류 검사 `tester.takeException()==null`과 Flutter 최종 exit 0을 함께 요구했다. 자체 JSON status만으로 성공 처리하지 않았다.

최종 캡처: [프로젝트 1440](../artifacts/project-home/native/run-7a4c81ce/01-projects-1440.png), [프로젝트 QA](../artifacts/project-home/native/run-7a4c81ce/02-project-qa.png), [서버 QA 1440](../artifacts/project-home/native/run-7a4c81ce/03-receive-1440.png), [서버 QA 1024](../artifacts/project-home/native/run-7a4c81ce/04-receive-1024.png), [수신 XML 작업실](../artifacts/project-home/native/run-7a4c81ce/05-received-editor.png), [받은 사본 1024](../artifacts/project-home/native/run-7a4c81ce/06-received-copies-1024.png), [받은 사본 1440](../artifacts/project-home/native/run-7a4c81ce/07-received-copies-1440.png).

초회 Material/ListTile assertion은 sidebar를 Material로 수정했다. 두 번째 서버 entry startup timeout은 그대로 보존했고 stdout/stderr/exit 진단을 추가했다. 동일 alpha.6 manifest의 독립 integrity 시작은 1.83초, 기존 bootstrap 명시 호출은 실제 listening을 반환했다. native harness는 서버 재구현 없이 기존 exported bootstrap을 명시 호출한다. Windows entryguard가 원인이라고 확정하지 않는다. 세 번째 긴 프로젝트 dropdown overflow는 isExpanded/ellipsis로 수정했다. 이 실패·중간 캡처는 최종 인수와 구분한다.

## 회귀와 독립 검토

- receipt 6검사: 동일 identity 동시 2writer 중 정확히 하나 성공, 원본 불변, path/hash/크기/일반파일 경계, workspace commit 직전 취소와 고아 미노출, v1 보존, 같은 snapshot의 다른 QA 귀속 차단, 늦은 offline 응답 차단. [로그](../artifacts/project-home/receipt-tests.log).
- 대상 회귀의 기존 workspace/desktop 및 receipt 10검사는 통과했고 새 HomeVM widget fixture의 fakeAsync 대기 때문에 초회를 중단했다. 초기화 방식과 async 디렉터리 호출을 정합한 뒤, 최종 정지 지점이 fakeAsync zone에서 만든 Completer를 runAsync에서 기다리는 부분임을 확인했다. Completer도 runAsync 안에서 생성하여 수정했다. 최종 동일 4파일 **11검사 PASS, exit 0 (00:12)**: [로그](../artifacts/project-home/flutter-targeted-final.log). 수신 중 목적지·탭 변경 차단, 연결 해제 후 늦은 결과 거부, 원본 QA 불변, 다른 프로젝트 새 사본, direct mode/출처 복원도 포함한다.
- Engine 담당이 실제 Dart 반례와 core source를 독립 검토했다. 동일 identity 병행 쓰기 4회에서 각각 정확히 1성공/1거부, late commit bytes 보존, hash/size/경로 거부, 늦은 offline의 타 QA versionFor null을 확인했다. Engine artifact `artifacts/checker-received-home-review-20261111/final-closure-review.json`과 `receipt-review.json`은 읽기 감사이며 native 화면 인수와 구분한다.
- 목업 홈 [14검사](../design/mockups/xml-block-studio/verification-home.json), 기존 편집기 [16검사](../design/mockups/xml-block-studio/verification-editor.json) PASS. 실제 API/Engine 실행이 아니라 로컬 클릭·저장복원·배치 검토다. 이전 목업 캡처/검증 JSON은 역사 자료로 보존했다.

## 최종 점검

`node scripts/flutter.mjs analyze --no-pub`: **No issues found**, [로그](../artifacts/project-home/analyze-final.log). native 인수 후 고급기능→홈 callback에서 dialog context를 await 전에 capture하도록 보완했고 format/brace를 정합했다. 후속 실제 Engine run을 다시 수행했다고 주장하지 않는다. 대상 회귀·analyze·최종 Release 빌드로 이 작은 변경을 확인한다.

검색 입력 표시 후속 수정은 native 인수 이후의 작은 UI 상태 정합이다. 섹션 이동과 같은 메뉴 재클릭 시 query reset revision으로 입력을 초기화하고, 홈 재생성 때는 현재 query를 표시한다. 기존 Home widget에 이 세 경로를 추가하여 [추가 회귀](../artifacts/project-home/home-search-regression.log) 1검사 PASS, [추가 analyze](../artifacts/project-home/analyze-search-final.log) No issues를 확인했다. 기존 실제 API/Engine native 및 저장소 verify는 재실행하지 않고 보존했다.

`node scripts/flutter.mjs build windows --release --no-pub`: exit 0, 55.1초. [최종 빌드 로그](../artifacts/project-home/release-build-search-final.log). 검색 수정 전 candidate와 manifest/launch는 `artifacts/project-home/release-before-search-key`에 보존했다. `record-project-home-release.mjs`와 `smoke-project-home-release.ps1`로 새 경로에만 복사하고 별도 APPDATA의 소유 프로세스에서 Flutter native window를 확인한 뒤 종료했다. 기존 사용자 앱은 종료하지 않았다.

- [새 실행 파일](../artifacts/releases/desktop-project-home-alpha8/Release/automated_qa_desktop.exe)
- [Release manifest](../artifacts/releases/desktop-project-home-alpha8/manifest.json): 19파일, SHA `64342b2580d08a87ddef942837160cd219620e74ad8766e59751b7653c31f975`
- [Source manifest](../artifacts/releases/desktop-project-home-alpha8/source-manifest.json): Dart 72파일, configuration 7파일
- [Native launch](../artifacts/releases/desktop-project-home-alpha8/launch.json): 같은 manifest hash, 격리 APPDATA, Flutter window 확인

관리자가 최종 검색 수정 candidate의 manifest `64342b…f975`를 기준으로 Release 19파일/source 72파일/configuration 7파일/embedded asset 3개/native DLL·launch를 독립 대조해 통과했다. 이전 studio Release 22파일 및 기존 135/201/148/2 보존 기준도 drift 0이다. 관리 artifact `coordination/artifacts/qa-home-release-gate-20261111.json`, `qa-home-release-preservation-20261111.json`에 최종 PASS를 기록했다. 서버/Agent alpha.6, Desktop alpha.8 package SHA `4215662445780eeecd016ad6acf2a7b2c5e16b9a4e62cf8ae88e30ee0452e77f`를 그대로 유지한다.

저장소 `pnpm run verify` **exit 0**: [로그](../artifacts/project-home/repository-verify.log). foundation/boundaries/types/package/OpenSpec/build/실제 browser UI 및 production/dev route 검사를 통과했다. 기존 Corepack shim을 현재 프로세스 PATH에만 추가했으며 시스템 설정은 바꾸지 않았다. OpenSpec strict와 git diff --check도 통과했고 CRLF 안내 외 diff 오류는 없다.
