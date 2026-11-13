# Design

## Context

기준 HEAD는 main 3e73cd1f14b0aab658748e9c9b5c1be4a87794ad다. product-planning data/prototypes/requirements/evidence를 실제 48개 API 경로와 대조했다. W01–W08/A01–A06의 게시/조회/실행요청/예약/업무는 이미 존재한다. D03 공용 수신의 서버 호환 안내와 Suite 개인 고정 복원, A03 업무 담당자 선택의 프로젝트 회원 조회가 빠져 있다. Flutter counterpart는 qa-desktop-planning-responsive이며 context와 Suite pins를 소비한다. 회원 조회는 이번 Desktop 소비가 없는 A03 서버 계약이며 새 웹 UI는 만들지 않는다.

## Goals / Non-Goals

목표는 기존 실제 여정에 필요한 읽기 계약 3개를 추가하고 생성 SDK 및 HTTP 인수로 정합하는 것이다. Engine DSL/alpha.6 서버·Agent/alpha.8 Desktop pin, 인증 설정, DB 스키마, 기존 mutation 권한은 바꾸지 않는다. 개인 배정 inbox, 사용자 CRUD, 모바일/TV/recorder, Slack 전송, 웹 UI는 범위 밖이다.

## Decisions

### 프로젝트 컨텍스트

GET /api/v1/projects/{projectId}/context, operationId getProjectContext, ProjectContextResponse {projectId, role, allowedActions, engine}. engine의 ProjectEngineContext는 engineVersion, contractVersion, contractSha256, nullable archiveSha256이다. EngineContractService가 시작 시 이미 확인한 runtime과 contract byte hash를 사용한다. archiveSha256은 manifest.sha256이 유효한 64자리 hash일 때의 설치 pin metadata이며 없으면 null이다. 현재 archive 파일을 다시 검사했다는 보증이 아니다. GET은 Engine process/plan/run을 호출하지 않으며 경로·설정·token을 반환하지 않는다.

allowedActions는 역할 계층에 따라 정렬된 고정 집합이다: viewer readPublished; qa_tester 이상 pinVersions/publishRuns/requestExecutions/manageSchedules/updateWork; qa_editor 이상 createDrafts; qa_manager 이상 reviewPublish/viewAudit/listMembers. system_admin은 manager 집합과 같다. 이는 이 계약이 다루는 진입권한이며 전체 API 권한 목록이나 성공 보증이 아니다. 실제 mutation은 객체 소유권, 독립 검토자, revision, 현재 membership, runtime pin을 다시 검증한다. 인증 실패는 401, 프로젝트 접근 실패는 403이다. 클라이언트는 정확한 runtime/contract/hash를 비교하여 공유 불가를 표시하며 로컬 실행 가능과 분리한다.

### Suite 개인 고정 복원

GET /api/v1/projects/{projectId}/suites/pins, operationId listSuitePins, 기존 PinPage를 재사용한다. viewer 이상 현재 인증 사용자·프로젝트의 suite_pins만 반환한다. PageQuery limit 1..100(기본 50), canonical base64url rowid cursor, rowid 오름차순을 적용한다. pin 갱신은 기존 행 rowid를 유지한다. 페이지는 snapshot이 아니며 조회 사이 사용자가 pin을 바꾸면 현재 값이 보인다. runtime이 바뀌어도 저장된 versionId/sha256을 반환하고 자동 업그레이드/삭제/실행하지 않는다. 기존 immutable version 및 FK가 정상 삭제를 금지한다. 목록에는 pin만 담고 getSuite의 정확한 version/engine/contract와 context를 비교해 불일치를 표시한다. 다른 프로젝트 또는 다른 사용자의 cursor는 offset일 뿐 scope를 변경할 수 없다.

### 업무 담당자 조회

GET /api/v1/projects/{projectId}/members, operationId listProjectMembers, ProjectMemberPage {items:[ProjectMemberResponse {userId, displayName:null, role}],nextCursor}. manager 이상만 접근한다. active users와 프로젝트 memberships를 join하여 users.rowid 순으로 같은 bounded cursor를 적용한다. DB에 이름이 없으므로 null을 명시하고 새 column/CRUD를 추가하지 않는다. 타 프로젝트 회원, inactive 사용자, token hash를 노출하지 않는다. 기존 업무 수정 API의 assignee membership/revision 검사는 그대로 유지한다.

### 상태와 소유권

Engine 판정, execution/lease 상태, evidence 상태, 업무 상태, 예약 occurrence 상태/사유, Desktop 전송 상태의 6축을 합치지 않는다. 요청 접수는 실행 완료가 아니고 work done은 passed가 아니며 recovered는 cleanup confirmed가 아니다. Suite stopOnFailure 이후 미실행 case의 결과를 합성하지 않는다. API 추가가 Engine execution이나 스케줄을 만들지 않는 것을 검증한다.

### 구현과 계약 순서

backend 소유자는 apps/server의 DTO/service/controller, packages/contract 및 TS/Dart 생성 SDK와 관련 tests/docs만 수정한다. Flutter 담당자는 앱만 수정한다. 관리 OpenSpec 검토와 strict PASS 후 구현하고 서버 HTTP 경계 테스트 → OpenAPI 생성 → TS/Dart SDK 검증 → 앱 소비 순서를 지킨다. 기존 main specs inventory가 비어 있어 새 capability 3개로 기록하며 기존 변경을 대체하지 않는다.

## Risks / Trade-offs

- 역할 힌트를 성공 보증으로 오인할 수 있어 DTO와 문서에 최종 mutation 검사 조건을 명시한다.
- archiveSha256은 pin metadata이며 null을 지원한다. runtime 설치 검증 보증으로 확대하지 않는다.
- Suite pins는 paging snapshot을 제공하지 않는다. 기존 고정을 보존하고 version detail에서 정확한 호환을 확인한다.
- 회원 displayName은 null이다. 이름 관리 기능은 후속 범위다.
- alpha.8 Desktop과 기본 alpha.6 서버의 실제 불일치는 유지하며 호환하지 않는 공유를 성공으로 표시하지 않는다.

## Validation

실제 Nest HTTP 테스트로 401/403/role 집합/secret 미노출, active 프로젝트 scope, cursor malformed/limit 경계, 개인 pin 격리·복원·재시작·구버전 보존을 검사한다. 기존 mutation 거부(자기 검토·권한·runtime)와 실행 side effect 없음도 확인한다. 생성 OpenAPI additive compatibility 및 TS/Dart response serialization 검증을 수행한다. 기존 server 전체 회귀와 관련 contract checks를 실행하고 실제 명령/결과/제약을 validation 문서에 남긴다. mock 화면 인수를 실제 API 인수로 세지 않는다.
