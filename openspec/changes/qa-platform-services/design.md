# Design

## Context

[저장소 조사](../../../docs/architecture/repository-audit.md)에 따라 빈 저장소의 기본 경계를 구성한다. 상세 목표는 [시스템 설계](../../../docs/architecture/system-design.md)와 [로드맵](../../../docs/planning/roadmap.md)을 따른다.

## Goals / Non-Goals

apps/server의 단일 API, apps/web 사용자 공용 시나리오·진행 및 역할별 관리자 업무, OIDC/RBAC, immutable registry, scheduler/Agent lease/reporting을 단계별로 구현한다. 웹을 관리자 전용으로 한정하지 않는다. P0에는 상세 설계만 작성하고 서비스 scaffolding은 하지 않는다.

## Decisions

### 2026-10-31 관리 승인된 첫 서버 제품 단위

Nest health/OpenAPI/생성 SDK 기반 다음으로 SQLite 영속 Repository와 migration을 사용한다. `node:sqlite`의 transaction 및 unique constraint로 publish/version, idempotency key, run/attempt/sequence를 원자 처리한다. SQLite는 로컬 기능 데모 선택이며 다중 호스트 운영 DB 인수를 뜻하지 않는다.

인증 모드는 명시 local/test 구성에서만 정해진 사용자·프로젝트 membership으로 실행한다. production 환경에서 이 모드를 선택하면 startup을 거부한다. 사용자 header만으로 임의 권한을 생성하지 않고 서버에 등록한 활성 identity와 역할을 확인한다. 삭제/비활성 사용자와 다른 프로젝트 접근을 거부한다. 실제 Slack OIDC/JWKS/state/nonce/session 검증과 외부 계정 인수는 task2.2로 별도 추적한다.

Registry는 draft→review→published 순서이고 published XML bytes/version/hash 및 dependency pin은 불변이다. 동일 publish key+payload 재시도는 같은 응답, 다른 payload는409, 동시 같은 버전 publish는 하나만 성공한다. Desktop은 권한 있는 목록에서 version을 선택하고 내려받은 bytes hash를 확인한 뒤 초안으로 적용한다. 수신·선택·검증만으로 실행하지 않는다.

목록은 opaque cursor pagination(기본50/최대100), 변경과 접근거부는 audit를 남긴다. published dependency manifest와 사용자의 pin을 분리하고 내려받은 고정 snapshot은 오프라인에서도 유지한다. upgrade는 이전/새 version/hash와 변경 diff를 확인하는 명시 동작이며 자동 덮어쓰지 않는다. 실행 문법은 고정 공개 Engine CLI/schema로 검증하고 서버에 새 DSL을 정의하지 않는다. 로컬 identity 사용 상태를 API/제품 화면에 표시한다.

자동 진행의 첫 transport는 인증 HTTP cursor polling이다. 서버 run ID와 Engine run ID/attempt/snapshot을 고정하고 batch append의 각 sequence를 검증한다. 같은 sequence+같은 payload는 멱등, 다른 payload/gap/terminal 후 append는409다. 웹은 마지막 확인 cursor 이후 재조회하고 문서/run 교체 또는 unmount 때 요청을 취소한다. 업무 progress와 engine outcome, 외부 수신 상태와 증거 검증완료를 각각 저장·표시한다.

Artifact는 클라이언트 filesystem 경로를 받지 않고 bytes 업로드를 받는다. 서버가 크기·hash·프로젝트/run 권한을 검사하고 자신의 저장소에 임시 파일 flush→원자 rename 후 메타데이터를 기록한다. result의 artifact와 bytes가 일치하기 전 검증완료로 확정하지 않는다. 불완전 업로드·누락·재시작 복구를 검증한다. Registry/run/event 데이터는 재시작 후 유지되어야 한다.

구현 순서는 schema/DTO→offline OpenAPI/양 SDK→Repository/권한/API→Desktop 수신/기존 CLI 게시→웹 polling이다. alpha.4 디자인/UX·Appium 소비를 우선하며 서버 하위 담당이 배정되면 server/contracts/SDK 내부 소유만 맡기고 root lock/scripts와 Flutter/웹은 Checker owner가 유지한다.

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

