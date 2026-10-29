# 원본 이관과 공동 적용

## 출처와 보존

1차 기준은 사용자 원본 MD가 지정한 `scratch-3d feature`의 로컬 remote-tracking `origin/feature`, SHA `325ca653fe213eb02b1b1e6e4fd7edc147f71721`이다. `C:/workspace/scratch-3d`에서 `git show origin/feature:openspec/changes/refactor-server-web-app-monorepo/...`로 아래 10파일을 읽었다. 원격 최신 여부는 확인되지 않았다.

보완 비교는 `C:/workspace/scratch-3d-worktrees/monorepo-setup`, branch `feature/root-engine-monorepo`, SHA `2e515c0df05fd592ec18e9e7388bb34eb3e904c5`다. 후속 원본은 root-engine-workspace의 npm engine/web 실제 구현 주석과 engine 경로 이동을 추가했다. 이 checkout을 원본 origin/feature와 같은 SHA라고 취급하지 않는다. scratch3d 현재 checkout `feature/server-web-app-openspec`/`3ead9aa8...`도 별개다.

원본은 읽기 전용으로 보존한다. 이번 '이관'은 Checker 안에 QA에 맞춘 명세를 작성하는 뜻이며 원본 파일 삭제·이동·소스 복제·cherry-pick을 하지 않는다. 아래 source 상대경로는 모두 `openspec/changes/refactor-server-web-app-monorepo/` 기준이다.

| 원본 파일 | QA 이관 파일 | 처리 |
| --- | --- | --- |
| .openspec.yaml | .openspec.yaml | spec-driven 유지, QA 생성일 별도; 원본 생성일 2026-10-17 |
| proposal.md | proposal.md | 세 앱/SDK/CI 목적 유지, 게임 삭제·QA 사용자 역할 반영 |
| design.md | design.md D1~D7 | 7결정 보존·QA 변환, 아래 상세 표 |
| tasks.md | tasks.md 1~7 | 원본 task 번호별 대응, 미검증 체크 이관 금지 |
| integration.md | integration.md | 게임 병행 change 대신 독립 Engine와 QA changes 소유권 |
| specs/monorepo-workspace/spec.md | specs/monorepo-workspace/spec.md | 세 앱/도구/실행/build 유지, 독립 Engine 경계 추가 |
| specs/shared-api-contract/spec.md | specs/shared-api-contract/spec.md | HTTP 전체 인수 유지, service 이름 QA로 변경 |
| specs/web-game-runtime/spec.md | specs/qa-user-web-app/spec.md | FSD 유지; 게임·물리 대신 사용자 XML·관찰 lifecycle |
| specs/flutter-app-shell/spec.md | specs/flutter-app-shell/spec.md | SDK/API/health 유지; Android 인수→Windows Desktop, 로컬 개발/CLI 추가 |
| specs/architecture-verification/spec.md | specs/architecture-verification/spec.md | drift/compat/실제 API/배포/인수 유지, Windows/QA 경로로 변경 |

## 설계와 task 대응

| 원본 항목 | QA 반영 | 제외·차이와 이유 |
| --- | --- | --- |
| D1, tasks1.1~1.3/2.1~2.5 | 동일 경로/명령/버전/경계, 현 pnpm 기반 보존 | 원본 packages/engine 및 후속 root engine 모두 제외: QA engine 별도repo 고정 |
| D2, task1.4/5.1~5.6 | code-first OpenAPI3.0.3, typescript-fetch/dart-dio, generator spike/drift | 엔진 execution schema는 OpenAPI로 재정의하지 않음 |
| D3, tasks4.1~4.6 | health/getHealth/validation/error/requestId/offline exporter/test fixture 전체 | service scratch-3d→automated-qa-checker, API client값은 web/app 유지 |
| D4, tasks2.4/5.2/5.5/6.6/7.3 | root 명령·순환 없는 생성·실패 전파·비캐시 dev | Android build→Windows Desktop build. 현재 JS verify와 미래 verify:all 구분 |
| D5, tasks3.1~3.6 | FSD·공개 API·route/cleanup·오래된 응답 취소·responsive 관찰 | Three.js/Rapier/WASD/canvas/world/RAF/scene/factory/script 전부 제외. 실제 실행은 독립엔진 |
| D6, tasks6.1~6.6 | app/core/features, local Dart SDK, API origin, health/retry, 실제 Desktop 인수 | mobile/emulator→Desktop. 블록/XML 개발·명시CLI는 사용자 최신 요구 추가 |
| D7, tasks7.1~7.6 | 실제 양 SDK 호출, baseline compatibility, CI/배포/재현·증거 | 게임 deep link→QA route, 자동 commit 요구 없음 |

원본 web-game-runtime의 '기존 엔진 소유권 준수/중복 core 금지' 원칙은 독립 QA engine 소비로 유지한다. GPU/물리 cleanup 자체는 QA 요구가 아니므로 인수에서 제외하고 UI 구독·파일 읽기·timer cleanup으로 대체했다. 원본 mobile-only 첫 인수는 QA 원본 Desktop 요구에 맞춰 의도적으로 바꿨다.

## 명세 소유권과 의존 관계

| Change | 소유·이번 이관과 관계 |
| --- | --- |
| refactor-server-web-app-monorepo | 세 앱 기반·HTTP health·OpenAPI/SDK·도구·통합 품질 기준. 이번 이관본이 이 범위의 상위 명세 |
| [qa-monorepo-policy](../qa-monorepo-policy/proposal.md) | 이미 검증한 JS 경계/root dev/build 정책 부분. 상위 전체 모노레포 완료의 근거는 아님 |
| [qa-flow-editor](../qa-flow-editor/proposal.md) | Flutter 전체 TC/Flow/블록 builder, undo/redo/device/cancel/실행 인수. shell/toolchain은 상위 기반 결과 재사용 |
| [qa-user-web-desktop-handoff](../qa-user-web-desktop-handoff/proposal.md) | 임의 Blueprint→XML 전달, Desktop XML 편집·검증·실행의 첫 제품 단위. 전체 builder 및 HTTP 기반 인수 대체 불가 |
| [qa-ai-blueprint](../qa-ai-blueprint/proposal.md) | 현재 JSON 문서·이벤트 모델 및 웹 관찰 근거. 웹 관리자 전용 해석은 최신 사용자 요구로 정정 |
| [qa-platform-services](../qa-platform-services/proposal.md) | P3 OIDC/RBAC/Registry, P4 scheduling/Agent/reporting. 상위 HTTP foundation을 소비하며 역할별 관리자 업무 유지 |
| Engine qa-flow-schema-core / qa-playwright-runner / qa-user-web-desktop-handoff | 실행 schema/XML/compile/interpreter/adapter/CLI 공개 artifact 원본. Checker가 내부 코드를 수정하지 않음 |

의존 순서: 상위 명세 검토 → 기반 도구/경계 → (로컬 Flutter+검증된 engine 계약) 및 (server health→OpenAPI→TS/Dart SDK) → 각각의 실제 인수 → P3/P4 제품 확장. 공용 README/config/계약 pin은 Checker 담당 한 명이 수정하고 관리 에이전트가 Engine handoff와 대조한다.

## 기존 QA 설계에서 보강한 인수 기준

- 현재 XML/관찰 UI 성공만으로 세 앱 통합 완료를 판정하지 않는다.
- 실제 server health의 optional/required nullable 및 invalid/repeated query, error requestId를 검증한다.
- DB/listener 없는 exporter와 generator/JAR checksum·옵션 고정, 동일입력 deterministic 결과를 검증한다.
- drift는 수동수정/누락/신규/삭제 모두 감지하고 working tree를 수정하지 않는다.
- 양 SDK의 동일 서버 transport 통합 및 이전 수용 baseline compatibility를 검증한다.
- Flutter Windows 실제 artifact·앱 호출과 full CI 실패 전파, production deep link/API/asset 오류를 검증한다.
- Desktop 로컬 XML 편집/CLI는 서버가 없어도 가능하며 전체 블록 builder 인수와 구분한다.

## 현재 중단 지점

2026-10-29 사용자 요청으로 문서 우선 정합 단계다. 제품 구현 재개는 관리 검토 후 별도 할당한다. 웹 XML serializer와 내보내기 UI 수정 2파일은 미검증으로 보존하고 새 제품 코드를 추가하지 않는다. Flutter SDK는 QA .tools에 3.47.5(tag `6a19cca56475dbfba1478ee68d7bd0c2ef891da1`)/Dart3.13.4 초기화만 확인했고 apps/app은 생성되지 않았다. Windows build/analyze/widget 인수는 수행하지 않았다. 기존 tasks의 완료 표시는 과거 실제 검증 범위만 유지한다.
