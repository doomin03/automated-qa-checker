# Checker 시스템 설계

앱별 배치·의존 규칙·실행 정책의 기준은 [모노레포 정책](monorepo-policy.md)이다.

2026-11-10 Desktop 확장: `features/project_workspace`의 파일 저장/프로젝트·QA·지침, `features/ai_authoring`의 설치 Codex 호출/후보, 상위 `app/workbench/DesktopWorkspaceViewModel`의 검증·적용·실행 순서를 추가했다. 새 Desktop 전용 runtime은 alpha.8이고 공용 packages/contract 및 서버/Agent alpha.6과 분리된다. 실행·실제 인수는 [Desktop 시작 안내](../desktop-ai-quickstart.md)를 따른다. 아래 서버 경계는 그대로 유지한다.

## 앱과 저장소 경계

```mermaid
flowchart LR
  D[Flutter Desktop apps/app] -->|직접 XML 또는 조합 XML / 명시 실행| E8[독립 Engine alpha8 CLI]
  E8 -->|events / result / artifact| D
  D -->|게시 버전 조회 / pin / 원본 수신| B[Nest API apps/server]
  W[React 사용자 QA 웹 apps/web] --> B
  W -->|명시 XML 파일 다운로드 후 열기| D
  D -.->|runtime와 원본 version 호환 조건부 공유| B
  B -->|진행 / 검증된 증거 / 업무| W
  B --> R[Registry / RBAC / Reports]
  B --> S[Scheduler + Queue + Lease]
  S --> A[인증된 Agent]
  A -->|고정 문서 / 명시 실행| E6[독립 Engine alpha6 CLI]
  E6 -->|원본 events / result / artifacts| A
  A -->|durable 보고 / ACK| B
  X[다른 프로젝트 / CI] -->|공개 package 또는 CLI| E8
```

사용자 웹·Desktop·관리자 권한업무는 하나의 서버 API를 공유한다. 웹은 공용 테스트·XML 전달·진행 확인, Desktop은 블록/Flow 또는 XML 테스트 개발·실행을 담당한다. GUI/API는 Appium/Playwright를 직접 구현하지 않는다. 파일 전달과 인증된 Registry 수신·진행 polling, 독립 Agent·Suite 순차 실행·예약을 구현하고 실제 서버 통합으로 검증했다.

2026-11-11 정합: 결과 수집·서버 전달의 주체는 Desktop 또는 Agent이며 Engine이 웹/서버에 직접 업무 결과를 게시하지 않는다. 기본 서버/Agent는 alpha.6, Desktop은 alpha.8이다. Desktop alpha.8 결과를 기본 alpha.6 서버에 게시하면 runtime 일치 검사로 거부되며 로컬 판정은 보존한다. 별도 호환 runtime 서버 인수와 기본 pin을 혼합하지 않는다. [통합 기획 검토](../../design/mockups/product-planning/index.html)와 [홈 수신 인수](../validation-project-home.md)를 따른다.

| 경로 | 목표 역할 | 현재 상태 |
| --- | --- | --- |
| apps/server | Nest module/controller/service, config/common, /api/v1 | health/Registry/RBAC/events/evidence/영속SQLite, local OIDC provider·업무·Suite·Agent·예약 통합 검증 |
| apps/web | React 사용자 공용 QA·XML 전달·진행 SPA, 역할별 관리 기능 | JSON/XML, Registry·Suite 검수·pin, 인증된 진행/검증 이미지, 조직 로그인·업무 비교·예약·복구 폼 |
| apps/app | Flutter Desktop 기능별 MVVM/Provider | XML/Flow/반복, CLI validate/plan/run/cancel, 디자인/UX·증거·Registry·조직 로그인; Windows build 검증; pnpm 제외 |
| packages/contract | 서버 OpenAPI 및 외부 engine public contract 소비 경계 | hash 고정 Engine alpha.6 JSON Schema + validator, HTTP OpenAPI/generator 및 Agent 업무 계약 |
| packages/api-client | 같은 OpenAPI로 생성한 TS SDK | 생성 SDK·오류 adapter·웹 연결 |
| packages/api_client_dart | 같은 OpenAPI로 생성한 Dart SDK | 생성 Dart SDK·오류 adapter, pnpm 제외 |
| packages/typescript-config | JS 앱들의 공통 compiler 정책 | 경계 README만 |
| scripts | foundation 검사와 SDK 환경 진단 | 실행 가능 |

이 경로는 scratch-3d feature의 아직 구현 전인 모노레포 설계를 채택한 것이다. [조사 근거](repository-audit.md)를 따른다.
현재 pnpm은 apps/web, apps/server, packages/contract, packages/api-client를 포함한다. apps/web은 실제 build와 browser 인수를 제공한다. Flutter는 별도 SDK의 MVVM/Provider 앱이며 [구조 안내](flutter-mvvm.md)를 따른다. 서버와 엔진 미연결 기능에는 성공 placeholder를 넣지 않는다.

## 의존 방향

- apps/web → 생성 api-client → HTTP. FSD에서 상위 레이어를 하위 레이어가 import하지 않는다.
- apps/app → 생성 api_client_dart + engine CLI bridge. UI graph 좌표와 execution semantics를 분리한다.
- apps/server DTO/controller → OpenAPI export → TS/Dart SDK. 서버가 생성 client를 import하지 않아야 한다.
- engine execution schemas → release artifact → Checker validator/editor. packages/contract가 engine schema의 원본이 되지 않는다.
- app 간 상대 source import, engine 소스 복사, 커밋된 file/link dependency, submodule은 금지한다.

## 제품 화면 설계

웹: 공용/사용자 시나리오 확인·편집 → XML 전달 → 테스트 진행 확인. Desktop: 프로젝트 선택 → TC/Suite 목록 → 블록/Flow builder 또는 XML 전체 편집 → validation/plan → device picker → 명시 실행 → Run 상세. Flow builder는 nodes/edges와 node settings, selector/input/assertion, timeout/retry, context preview, undo/redo, validation errors를 제공하는 목표다.
Run 상세는 단계별 로그/증거/실패 원인/결과 버전/재실행을 표시한다. 실행 대상 확인은 공개 CLI devices 결과로 설치된 Chromium과 정적 Android/iOS 지원·설정 유무를 구분한다. native targets가 비어 있고 connectionVerified=false이면 실제 기기가 연결됐다고 표시하지 않는다. Suite는 Desktop에서 고정 버전의 개별 case를 수신·명시 실행하며 전체 순차 실행은 독립 Agent가 담당한다.
관리 업무의 현재 구현은 표준 QA/Suite 독립 검수·게시, Run 담당/업무, 예약·발생 이력, 실행 운영 복구, 감사와 local-test 알림이다. 예약/요청은 qa_tester도 가능하며 메뉴 위치와 최소 권한은 구분한다. 사용자·팀·역할·프로젝트 CRUD, 개인 QA 할당 inbox, 게시물 폐기/반려, Agent/기기 전체 재고 UI와 외부 Slack 알림은 목표 또는 미완료다. 사전 provisioning을 이 관리 UI의 구현으로 간주하지 않는다.

## 순서

P2는 로컬 Flow 편집→engine CLI→결과만 연결한다. 인증/Registry는 P3, scheduler/Agent/weekly reporting은 P4로 나눈다.
Flutter Desktop 생성/build는 P2 tasks다. 기존 문서의 웹 관리자 전용 설명은 최신 사용자 요구에 따라 사용자 QA 웹으로 정정했다. 실제 CLI 직접 실행과 stdin 취소를 연결했다. 모노레포 상세 기반과 HTTP health/codegen 인수는 [이관 설계](../../openspec/changes/refactor-server-web-app-monorepo/design.md)를 따른다. health bootstrap은 P3 OIDC/Registry 제품 구현과 구분하고 로컬 P2는 서버 없이 가능해야 한다.

