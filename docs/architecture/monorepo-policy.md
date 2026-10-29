# Checker 모노레포 정책

2026-10-28 정리, 2026-10-29 원본 지침 대조. 이 문서는 원본 MD의 책임 경계와 이전 작업에서 채택한 구현 규칙을 정리한다. 원본을 대체하는 새 구조 지시가 아니다.

- 원본 고정 원칙: `automated-qa-engine`은 독립 저장소이며 `automated-qa-checker`는 Flutter 사용자 Desktop·관리자 앱·공통 백엔드의 모노레포다. 기존 구조를 보존하고 참조에서 실제 확인한 관례를 우선한다.
- 이전 작업의 채택: `apps/app`, `apps/web`, `apps/server` 경로와 React/Nest 목표, pnpm/Turbo는 [저장소 조사](repository-audit.md)에 기록된 선택이다. 원본 MD가 특정 폴더명·패키지 관리자·관리자/서버 프레임워크를 강제한 것은 아니다.
- 구현 상태: 웹 관찰과 엔진 공개 계약 소비, Flutter MVVM/Provider 초안 편집 shell이 실행 가능하다. Flutter의 엔진 연결·블록 편집 및 Nest/OpenAPI/생성 SDK는 후속이다. 앱별 빌드·배포·비밀 설정은 분리한다.

원본 위치는 `C:/Users/Domin/Downloads/automated_qa_codex_instructions/automated_qa_codex_instructions`이며 `CODEX_MASTER_PROMPT.md`, `CHECKER_CODEX_PROMPT.md`, `CONTRACTS_AND_EXAMPLES.md`, `PHASES_AND_ACCEPTANCE.md`, `WORKTREE_OPENSPEC_GUIDE.md`를 기준으로 대조했다. 원본의 API 경로·예제 payload는 제안이므로 실제 소비 계약으로 자동 확정하지 않는다. 저장소 담당과 다음 인계는 [관리 인계](manager-handoff.md)에 기록한다.

2026-10-29 최신 사용자 역할: 웹은 공용 시나리오·XML 전달·진행 확인을 위한 사용자 앱이며 Desktop은 블록/Flow 또는 XML 테스트 개발·실행 앱이다. 관리자 업무는 권한별 후속 기능이다. 전체 기반 기준은 [원본 모노레포 이관본](../../openspec/changes/refactor-server-web-app-monorepo/proposal.md)과 [출처·적용표](../../openspec/changes/refactor-server-web-app-monorepo/integration.md)이며 이 문서의 검증된 JS 부분이 세 앱 인수를 대체하지 않는다.

## 구조와 현재 구현

```text
QA/
├─ automated-qa-engine/         독립 실행 엔진 저장소
└─ automated-qa-checker/        제품 모노레포
   ├─ apps/
   │  ├─ web/                  React 사용자 공용 QA·XML 전달·진행 화면
   │  ├─ app/                  Flutter MVVM/Provider 초안 편집 shell
   │  └─ server/               공통 Nest API (설계)
   ├─ packages/
   │  ├─ contract/             엔진 공개 계약 소비 (구현), 서버 OpenAPI (예정)
   │  ├─ api-client/           생성 TypeScript HTTP SDK (예정)
   │  ├─ api_client_dart/      생성 Dart HTTP SDK (예정)
   │  └─ typescript-config/    공통 compiler 설정 (예정)
   ├─ scripts/                 저장소·계약·의존 경계 검사
   └─ openspec/                변경별 설계·요구사항·인수 작업
```

현재 Node workspace는 root, web, contract다. Flutter는 기능별 MVVM/Provider shell과 별도 pubspec.lock을 사용하고 서버는 경계 README만 있다. shell 성공은 세 앱 통합 완료가 아니다. [Flutter 작업](../../openspec/changes/qa-flow-editor/tasks.md)과 [서버 작업](../../openspec/changes/qa-platform-services/tasks.md)에서 구현·인수를 추적한다.

## 참조 프로젝트와의 관계

`C:/workspace/scratch-3d-worktrees`는 여러 Git worktree와 계획 문서를 담은 관리 디렉터리다. 모노레포 자체의 root가 아니다.
2026-10-28 읽기 전용 확인: `monorepo-setup`, branch `feature/root-engine-monorepo`, HEAD `2e515c0df05fd592ec18e9e7388bb34eb3e904c5`, clean.
그 checkout의 실제 구현은 npm workspace의 `engine/` + `apps/web/`이며 Flutter·Nest·pnpm/Turbo 전체 구성은 `refactor-server-web-app-monorepo`의 목표 설계다.
QA는 앱 경계와 검증 방식은 참고하되 기존 pnpm/Turbo 선택과 엔진 별도 저장소 결정을 유지한다. 원격 최신 상태를 확인한 결과는 아니다.

## 의존 방향

| 소비자 | 허용 경계 | 금지 경계 |
| --- | --- | --- |
| web | contract의 공개 export, 향후 api-client로 HTTP | server/app 내부 source, Node builtin |
| Flutter app | 향후 api_client_dart로 HTTP, 고정 engine CLI bridge | 다른 앱 source, 임의 shell 명령 |
| server | 자체 DTO/controller/service, 서버용 공통 package | 자기 API의 생성 client, UI 내부 source |
| 공통 package | 다른 공통 package의 명시된 공개 export | apps 의존, 순환 의존 |
| engine | 독립 release와 공개 schema/event/result | Checker 내부 source에 대한 의존 |

내부 Node package 참조는 `workspace:*`를 사용하고 공개 `exports`를 명시한다. 직접 상대 경로로 다른 package source를 읽거나 `file:`/`link:` 의존성을 커밋하지 않는다. 새 공통 package는 역할과 공개 API가 있을 때만 추가한다.
웹 FSD는 app → pages → widgets → features → entities → shared 방향을 따른다. 하위 레이어가 상위 레이어를 import하지 않는다.

`check:boundaries`는 package manifest의 앱 의존·경로 의존·누락된 workspace·순환 의존, `src` 아래 JS/TS의 import/export/require/import type 및 FSD 역방향을 검사한다. 동적 계산 import와 미등록 alias는 거부한다. 현재 공개 export는 정확한 subpath key로 선언한다. wildcard export나 alias를 도입하면 검사기도 함께 확장한다.
이 검사는 Dart analyzer, 전체 FSD slice 규칙, 실행 중 파일 접근, 앱별 인수 검사를 대신하지 않는다. Dart 경계 검증은 실제 앱·SDK 생성 시 추가한다.

## 패키지 관리자와 명령

- JavaScript: Node 24.18.0 / pnpm 10.34.8 / Turbo 2.11.10, root `pnpm-lock.yaml` 하나. OpenSpec 1.14.2, 경계 AST 파서 TypeScript 6.0.3 고정.
- pnpm에는 `apps/server`, `apps/web`, `packages/contract`, `packages/api-client`, `packages/typescript-config`만 등록한다. package.json이 없는 경로는 아직 실행 package가 아니다.
- Dart: `apps/app`과 `packages/api_client_dart`는 같은 Git 저장소에 두되 pnpm에는 등록하지 않는다. 앱 생성 시 Flutter SDK 정확한 버전과 앱 pubspec.lock을 고정한다. Flutter 명령은 앱 디렉터리에서 실행하며 JS 개발에 Flutter를 요구하지 않는다.
- `dev`: 구현된 JS package의 dev task 실행. 현재 웹만 시작한다. 개발 프로세스는 persistent이며 cache하지 않는다.
- `build`: 구현된 JS package의 build task 실행. 선행 package build 후 소비자를 build하고 dist를 산출물로 관리한다. 현재 웹 build만 존재한다.
- `dev:web`, `build:web`: 웹만 실행·빌드한다.
- `verify`: foundation → 의존 경계/회귀 검사 → package 검사 → OpenSpec strict → JS build → 실제 Chromium UI 검사. Flutter/서버 인수를 포함했다고 표시하지 않는다.

루트 명령은 `npx --yes pnpm@10.34.8 run <명령>`으로 실행한다. [Turbo task 설정](https://turborepo.dev/docs/crafting-your-repository/configuring-tasks)과 [pnpm workspace 규칙](https://pnpm.io/workspaces)을 따른다.

## 계약과 AI 정책

서버 구현 시 DTO/controller → OpenAPI → TypeScript/Dart SDK 순서로 생성한다. 생성 코드는 수동 수정하지 않고 서버가 생성 SDK를 역참조하지 않는다. 아직 생성기나 서버 OpenAPI를 구현한 상태는 아니다.
엔진 실행 schema는 엔진이 소유한다. Checker는 version/hash가 고정된 공개 artifact만 가져온다. HTTP 계약과 엔진 실행 계약을 혼합하지 않는다.
AI CLI는 선언형 QA를 생성하는 입력 공급자다. GUI는 검사·변경 확인·실행 요청·진행 표시를 담당한다. 가져오기만으로 실행하지 않고, 기록이 없는 노드를 성공으로 표시하지 않는다. 구체적인 현재 동작과 후속 작업은 [AI·GUI 정책](../ai-blueprint-policy.md)을 따른다.

## 설정과 검증 책임

앱별 환경 설정을 사용한다. 웹/Flutter에 넣는 API 주소 등은 공개 설정이며 서버 비밀값을 클라이언트에 전달하지 않는다. secret은 환경이나 secretRef로 주입하고 저장소·artifact·로그에 원문을 남기지 않는다.
새 앱을 활성화할 때 실제 실행 진입점, 고정 toolchain/lockfile, 실패를 전달하는 명령, 앱별 테스트·빌드 CI를 함께 추가한다. 구현되지 않은 명령에 성공 placeholder를 넣지 않는다. 현재 GitHub Actions는 JS 검증만 설정되어 있으며 원격 실행 여부는 별도로 기록한다.
worktree는 병렬 작업 방식이지 제품 구조가 아니다. 사용자에게 명시적 병렬 작업 요청이 있을 때만 별도 worktree를 검토한다.

## 기존 정책 위치

| 문서 | 내용 |
| --- | --- |
| [시스템 설계](system-design.md) | 사용자 웹·Desktop 역할, 엔진 분리, 개발 순서 |
| [플랫폼 설계](platform-design.md) | API 오류 형식, 권한, Registry, 일정·Agent 정책 초안 |
| [AI·GUI 정책](../ai-blueprint-policy.md) | 공급자 중립 입력, 실행과 가져오기 분리, 진행 신뢰성 |
| [로드맵](../planning/roadmap.md) | P0~P6 범위와 인수 순서 |
| [개발 안내](../development.md) | 현재 실행 가능한 명령 |
| [검증 기록](../validation.md) | 실제 실행 증거와 미구현 범위 |

이 문서들은 프로젝트 내부 설계·개발 정책이다. 서버나 Flutter까지 배포 가능한 제품으로 검증되었다는 인증을 의미하지 않는다.
