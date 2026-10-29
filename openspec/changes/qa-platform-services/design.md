# Design

## Context

[저장소 조사](../../../docs/architecture/repository-audit.md)에 따라 빈 저장소의 기본 경계를 구성한다. 상세 목표는 [시스템 설계](../../../docs/architecture/system-design.md)와 [로드맵](../../../docs/planning/roadmap.md)을 따른다.

## Goals / Non-Goals

apps/server의 단일 API, apps/web 사용자 공용 시나리오·진행 및 역할별 관리자 업무, OIDC/RBAC, immutable registry, scheduler/Agent lease/reporting을 단계별로 구현한다. 웹을 관리자 전용으로 한정하지 않는다. P0에는 상세 설계만 작성하고 서비스 scaffolding은 하지 않는다.

## Decisions

server DTO/controller→OpenAPI→TS/Dart SDK를 따른다. 실행 schema 원본은 engine에 남긴다. 업무 progress, outcome, occurrence 상태를 분리한다. transaction/unique key/lease fencing으로 중복을 제어한다.

health/OpenAPI/generator 기반은 refactor-server-web-app-monorepo에서 먼저 검증하며 P3 OIDC/Registry 완료를 뜻하지 않는다. 공용 XML의 서버 버전 전달과 진행 자동 수신은 이 change의 제품 목표다. 첫 파일 handoff는 qa-user-web-desktop-handoff에서 검증하지만 자동 수신 완료로 집계하지 않는다. 자동 수신 transport 선택은 API 설계 단계에서 고정하고 인증·run/attempt/sequence·snapshot/gap·재연결을 검증한다.

- integrationId: automated-qa-foundation
- contractVersion: 0.1.0-draft.1
- dependsOn: qa-flow-editor 및 engine release; P3 인증/권한 → P4 원격 실행
- counterpartRepoChange: automated-qa-engine: P4 Agent protocol change는 후속 제안
- phase: P3/P4

## Risks / Trade-offs

Flutter 앱/서버 미구현, 원격 참조 최신성 미확인, engine local-preview 상태를 제품 완료로 간주하지 않는다. 실제 실행 인수 없이 mock/문서 검증만으로 tasks를 닫지 않는다.

## Migration Plan

기존 소스가 없으므로 대체 migration은 없다. 계약 fixture → 구현 → 실패 경로 → 실제 E2E → 릴리스 소비 순서로 진행한다. 사용자 worktree와 원격 Git은 변경하지 않는다.

## Open Questions

후속 단계에서 SDK/framework/driver의 정확한 버전을 실행 검증으로 결정한다. 현재 기능 명령과 제안 명령은 README에서 구분한다.

