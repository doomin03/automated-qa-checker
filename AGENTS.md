# Automated QA checker

- 먼저 README.md, docs/architecture/repository-audit.md, docs/architecture/system-design.md와 작업 대상 OpenSpec change를 읽는다.
- 앱 배치·의존·toolchain 정책은 docs/architecture/monorepo-policy.md를 따른다. 새 package 또는 import 경계를 추가할 때 check:boundaries와 공개 exports를 함께 검토한다.
- 문서는 한국어로 작성한다. OpenSpec 구조 제목과 SHALL/MUST는 영어로 유지한다.
- 웹은 사용자 공용 테스트 시나리오·XML 전달·진행 앱이고 Flutter Desktop은 블록/Flow 또는 XML으로 개별 테스트를 개발·실행하는 앱이다. 관리자 업무는 역할별 기능으로 구분한다.
- Flutter는 feature-first MVVM과 package:provider를 사용한다. app의 MultiProvider에서 Service/Repository/ViewModel을 조립하고 View는 IO를 직접 호출하지 않는다.
- 웹 XML·공유·진행, Flutter XML/Flow/반복 편집과 프로젝트/QA 저장·Codex 후보 생성, Nest 인증/Registry/업무/Suite/Agent/예약·생성 SDK를 구현했다. 새 Desktop 전용 Engine은 alpha.8, 서버/Agent·기존 Release는 alpha.6이다. 실제 인수는 docs/validation-desktop-ai.md 및 docs/validation.md와 tasks를 따른다. 실제 Slack 계정과 모바일 기기는 로컬 fixture 검증과 구분한다.
- Engine는 실행 스키마와 interpreter/adapter/CLI를, Checker는 사용자 웹·Flutter·관리자 권한업무·서버·업무 상태를 소유한다.
- 원본 모노레포 OpenSpec 이관본 openspec/changes/refactor-server-web-app-monorepo와 integration.md를 먼저 읽는다. 사용자 구현 승인과 관리 할당에 따라 명세를 먼저 정합한 뒤 구현한다.
- engine source 복제, submodule, 커밋된 로컬 경로 의존성을 추가하지 않는다. packages/contract는 Checker HTTP 계약을 소유하며 engine 실행 스키마를 다시 정의하지 않는다.
- scratch-3d는 읽기 전용 참조다. origin/feature의 설계와 실제 구현을 구분하고 인증 실패를 추측으로 메우지 않는다.
- 현재 pnpm lockfile과 고정된 OpenSpec 1.14.2를 사용한다. 전역 Codex 설정이나 사용자 자격증명을 변경하지 않는다.
- 계약 변경은 engine 명세 → engine 구현 및 contract test → release 고정 → checker 연동 순서다.
- 실제 검증한 tasks만 [x] 처리한다. P1/P2 구현 전 change를 archive하거나 openspec/specs에 구현 완료 기준으로 복사하지 않는다.
- 실행 결과와 업무 진행 상태를 분리하고 unsupported/infra_error/unrun을 성공으로 처리하지 않는다.
- shell 실행을 Flow 기본 액션으로 허용하지 않는다. secretRef만 커밋하고 artifact/log에는 실제 비밀값을 남기지 않는다.
- 사용자 수정 보존. reset --hard, clean -fd, force push 금지. 원격 push/merge는 별도 요청이 있어야 한다.
- worktree는 명시적 병행 작업 시에만 검토하며 유효한 HEAD가 필요하다. 이번 설정은 기존 checkout에서 수행한다.
- 검증: pnpm run verify. 계약 hash/이벤트 모델/OpenSpec/build/실제 browser UI 검사를 포함한다. Flutter 검사/build는 app:* 명령과 별도 실제 인수로 확인한다.

