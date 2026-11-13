# automated-qa-checker

[2026-11-13 재개 컨텍스트](docs/handoff/context-20261113.md)에 현재 역할·구조·alpha10 pin·portable 배포·정확한 검증 결과·미완료와 다음 순서를 보존했습니다. Git에 포함되지 않는 로컬 산출물과 다른 PC 준비 조건도 먼저 확인하세요.

[전체 제품 기획·화면설계](design/mockups/product-planning/index.html)에서 Engine·Desktop·사용자 웹·관리 업무의 관계도, 사용자 여정, 25개 화면설계와 조작 목업, 원본 요구 대응표를 함께 검토합니다. 예시 목업과 실제 제품 인수는 구분하며 [사용 방법·검증](design/mockups/product-planning/README.md)을 따릅니다.

현재 Windows source는 프로젝트 목록 → 서버 게시 QA/Suite 수신 → 로컬 QA → XML/블록 작업실·복수 AI 터미널을 연결하며 검증된 Engine alpha.10을 소비합니다. [프로젝트·받은 QA 홈 안내](docs/project-home.md)와 [파일 블록 편집 안내](docs/xml-block-studio.md)를 참고하세요. 이전 `desktop-project-home-alpha8` Release와 [그 시점 검증·캡처](docs/validation-project-home.md)는 역사 자료로 보존하며 현재 source의 최종 배포 파일과 구분합니다. Portable 조립·경로 이동 인수와 실제 다른 PC 실물 인수도 구분합니다.

현재 Portable 실행 절차와 최종 배포 경로는 [Portable 시작 안내](docs/portable-desktop-quickstart.md)를 따릅니다.

새 Desktop은 서버 없이 로컬 작성·실행할 수 있습니다. 서버 공유는 [alpha.10 서버 연결 안내](docs/server-runtime-alpha10.md)를 따릅니다. 새 서버/Agent lane은 같은 alpha.10을 별도 설치하며 기존 alpha.6 환경을 자동 변경하지 않습니다.

공유 실행은 [현재 서버 연결 안내](docs/server-runtime-alpha10.md)의 고정 Engine 설치 → 로컬 identity 생성 → 서버4319 → 사용자 웹4318 → Windows 앱 → XML 공유·명시 실행·결과 순서입니다. bootstrap은 CLI/manifest/인증 환경 설정을 명시적으로 요구합니다. Agent demo4320은 이 기본 API 주소와 별개입니다. [기존 로컬 데모](docs/local-demo.md)와 과거 [검증 기록](docs/validation.md)은 보존합니다.

이전 Windows 앱은 `artifacts/releases/alpha6-mvvm/Release/automated_qa_desktop.exe`와 `artifacts/releases/desktop-ai-alpha8/Release/automated_qa_desktop.exe`로 보존합니다. 같은 Release 폴더의 DLL/data를 함께 유지하세요. 기존 AI 작성 경로는 [앱 시작 안내](docs/desktop-ai-quickstart.md)를 따릅니다. 이전 `alpha6` 폴더도 보존했습니다.

[Desktop Blueprint 목업](design/mockups/desktop/blueprint-workspace/index.html)은 프로젝트 → QA 목록 → 노드 작업 공간과 AI 변경 제안 검토를 보여줍니다. [화면 캡처·검토 안내](design/mockups/desktop/README.md)에서 새 시안과 보존한 이전 시안을 확인할 수 있습니다. AI 연결·실행은 예시 데이터 시연이며, HTML은 여전히 별도 시연입니다. 실제 Flutter에는 프로젝트/QA 저장과 Codex 후보 생성·검토·명시 적용을 별도로 구현했습니다.

Flutter 테스트 개발·실행 앱, React 사용자 공용 시나리오·진행 웹, 공통 Nest 서버의 pnpm/Turbo 모노레포다. 관리 기능은 권한별 업무로 구분한다. XML·블록 편집과 alpha.10 실행, Registry·Suite 공유, 웹 진행·증거, 조직 인증·업무·비교, 영속 서버 및 독립 Agent·예약을 구현했다. [현재 runtime 통합 인수](docs/validation-server-runtime-alpha10.md)와 [A07 서버 인수](docs/validation-project-administration.md)를 따른다. A07 관리 웹 화면은 아직 별도 구현 대상이다.

사용자가 전달한 모노레포 OpenSpec은 [이관 proposal](openspec/changes/refactor-server-web-app-monorepo/proposal.md), [설계](openspec/changes/refactor-server-web-app-monorepo/design.md), [원본 대응·소유권](openspec/changes/refactor-server-web-app-monorepo/integration.md)에 있다. 원본을 보존해 QA에 맞게 이관하고 검증된 명세에 따라 구현한다. [모노레포 정책](docs/architecture/monorepo-policy.md)은 현재 구현된 부분과 목표를 구분한다.

기능 우선의 첫 **Blueprint 관찰 화면**을 apps/web에 구현했다. AI CLI가 만든 JSON 문서의 검사/편집/내보내기, node/edge 보기, 실제 엔진 JSONL event 재생과 파일 따라가기를 제공한다.

## 실행

Node24.18.0 기준이다. 설치·identity·서버·웹·Flutter 설정 명령은 [기능 데모 안내](docs/local-demo.md)의 순서대로 실행한다. 기본 주소는 사용자 웹 `http://127.0.0.1:4318`, API `http://127.0.0.1:4319`다. 웹의 **실제 실패 기록 예제** 또는 Engine가 저장한 blueprint.json/events.jsonl로 서버 없는 관찰도 가능하다.

## 검증

설치를 마친 후 `pnpm verify`는 JS/서버/브라우저, `pnpm verify:all`은 계약·생성 SDK·Flutter·Windows build/실행까지 검증한다. 최초 준비와 전체 재현 절차는 같은 [기능 데모 안내](docs/local-demo.md)를 따른다. 실제 외부 Slack 계정과 모바일 기기 인수는 로컬 fixture 테스트와 구분한다.

Checker는 엔진 source를 복사하지 않는다. 현재 서버 runtime의 정확 버전/SHA-256은 `packages/contract/runtime/engine-runtime.json`, Desktop은 `apps/app/engine-runtime-pin.json`에 고정한다. 기존 `packages/contract/engine-runtime.json`은 alpha.6 역사 lane이다. 설치와 입력은 [현재 서버 안내](docs/server-runtime-alpha10.md)를 따른다.
웹은 사용자 Blueprint XML 내보내기, 공용 Registry·Suite 게시, 서버 진행·증거·업무 조회를 제공한다. Flutter는 원문/블록/반복 편집과 명시 Engine 실행을 제공한다. Nest는 health/OpenAPI/TS·Dart SDK, 영속 Registry와 진행/결과, OIDC 세션·RBAC, 업무/비교 및 예약·Agent API를 구현했다. 새 서버/Agent와 Desktop은 alpha.10으로 결과를 공유하며 기존 alpha.6 서버에 대한 불일치 거부는 유지한다. 실제 Slack 계정·모바일 기기 인수는 별도이며 가져오기·pin·검증만으로 테스트를 실행하지 않는다.

목표 흐름은 웹에서 공용/사용자 Blueprint를 XML로 전달하고, Flutter에서 블록/Flow 또는 XML을 작성·검증·명시 실행하며 진행을 웹에서 확인하는 것이다. 첫 파일 전달은 [XML handoff change](openspec/changes/qa-user-web-desktop-handoff/proposal.md), 서버 전달·진행 자동 수신은 [플랫폼 change](openspec/changes/qa-platform-services/proposal.md)에서 추적한다.

[모노레포 정책](docs/architecture/monorepo-policy.md) · [AI와 GUI 정책](docs/ai-blueprint-policy.md) · [개발 안내](docs/development.md) · [검증 결과](docs/validation.md) · [설계](docs/architecture/system-design.md) · [기획](docs/planning/roadmap.md)

이번 추가 구현의 시작 기준은 main/3e73cd1이며 기존 working tree 변경을 보존했다. 담당 에이전트가 commit/push/새 worktree를 만들지 않았다.

