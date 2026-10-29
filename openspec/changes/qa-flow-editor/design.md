# Design

## Context

[저장소 조사](../../../docs/architecture/repository-audit.md)에 따라 빈 저장소의 기본 경계를 구성한다. 상세 목표는 [시스템 설계](../../../docs/architecture/system-design.md)와 [로드맵](../../../docs/planning/roadmap.md)을 따른다.

## Goals / Non-Goals

apps/app에 TC/Flow CRUD, nodes/edges editor, undo/redo, engine CLI bridge와 run view를 구현한다. P0는 경로·소비 manifest·명세만 준비하며 로그인/registry/예약은 후속 change다.

## Decisions

참조의 apps/app 및 data/domain/presentation 구조를 따른다. pnpm은 Dart package를 소유하지 않는다. 앱에서 driver를 호출하지 않고 고정 engine CLI를 argument array로 실행한다.

Flutter 구현은 사용자 추가 요청에 따라 feature-first MVVM + provider다. 원본 data는 repositories/services, domain은 immutable models, presentation은 views/view_models로 매핑한다. MultiProvider composition root와 ChangeNotifierProvider의 수명·상태 관찰 규칙은 상위 모노레포 D6을 따른다. ViewModel은 UI/IO 객체를 직접 소유하지 않는다.

상위 구조·toolchain/shell 기준은 refactor-server-web-app-monorepo, XML 첫 편집·전달 단위는 qa-user-web-desktop-handoff다. 같은 앱 생성/bridge를 중복 구현하지 않고 인수 증거를 연결한다. 블록→선언형 내부모델→XML과 직접 XML 모두 Engine parse/validate/compile-plan 경로를 소비한다. 실제 adapter는 현재 Playwright이며 Appium은 Engine 후속이다. XML 편집기만 있으면 full drag/drop·undo/redo tasks는 계속 미완료다. 서버 없이 로컬 테스트 개발이 가능해야 한다.

- integrationId: automated-qa-foundation
- contractVersion: 0.1.0-draft.1
- dependsOn: engine qa-flow-schema-core + qa-playwright-runner의 실제 테스트와 고정 release
- counterpartRepoChange: automated-qa-engine/openspec/changes/qa-flow-schema-core; automated-qa-engine/openspec/changes/qa-playwright-runner
- phase: P2

## Risks / Trade-offs

현재 로컬 Flutter SDK 초기화만 확인했으며 앱 생성·Windows build 인수는 없다. 원격 참조 최신성 미확인과 engine local-preview 상태를 정식 배포 완료로 간주하지 않는다. 실제 실행 인수 없이 mock/문서 검증만으로 tasks를 닫지 않는다.

## Migration Plan

기존 소스가 없으므로 대체 migration은 없다. 계약 fixture → 구현 → 실패 경로 → 실제 E2E → 릴리스 소비 순서로 진행한다. 사용자 worktree와 원격 Git은 변경하지 않는다.

## Open Questions

후속 단계에서 SDK/framework/driver의 정확한 버전을 실행 검증으로 결정한다. 현재 기능 명령과 제안 명령은 README에서 구분한다.

