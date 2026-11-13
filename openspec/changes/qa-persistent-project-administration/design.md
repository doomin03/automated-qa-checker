# Design

## Context

PlatformRepository는 users(id/token_hash/active), projects, memberships를 보유한다. start 때 users.active=0 및 memberships 삭제 후 환경 identity를 다시 쓴다. AuthRepository.lookup/exchange와 PlatformService.authorize는 매 요청 active/membership을 확인한다. system_admin은 전역 무제한 관리자가 아니라 project membership의 최고 역할이다. 이 의미를 유지한다.

## Goals / Non-Goals

목표는 현재 프로젝트의 사용자·membership 관리, 재시작 보존, 즉각 권한 철회, 감사와 generated 계약이다. 조직/프로젝트 생성·팀의 권한상속·외부 Slack 초대·로그인 자동 가입·토큰 다운로드·현재 배포 환경의 모드 변경은 제외한다. 후속 업무 inbox가 필요로 하는 활성 사용자 관리 기반을 제공한다.

## Decisions

### D1. Explicit managed mode and compatibility

PlatformConfig에 identityStorage `provisioned | managed`를 추가한다. 환경 변수 QA_IDENTITY_STORAGE가 없으면 provisioned이며 기존 직접 config fixture도 기본 provisioned다. 값 오류는 startup 거부다.

새 migration은 singleton identity administration metadata(mode)와 user/membership별 관리 revision·nullable displayName을 별도 sidecar 테이블로 추가한다. 기존 DB를 managed로 처음 여는 경우 기존 사용자·membership 상태 전체를 보존하고 새 seed의 추가·수정·삭제를 적용하지 않는다. 빈 DB에만 유효 seed를 한 번 적용하고 관리 모드를 기록한다. 적어도 한 명의 active system_admin membership이 있어야 managed 초기화가 가능하다. 기존 테이블의 INSERT/조회 signature를 바꾸지 않는다.

managed 기록 이후 시작에서는 사용자/role/활성/표시명을 seed로 덮어쓰지 않는다. 기존 active local token hash 역시 자동 교체하지 않는다. OIDC subject binding/allowlist는 기존 환경 신뢰 경계를 유지하며 로그인은 새 사용자를 자동 생성하지 않는다. 운영자가 별도 binding을 준비해야 새 OIDC 사용자가 로그인할 수 있다는 상태를 UI에 표시한다. 관리 응답에는 token/hash/subject/설정 원문을 넣지 않는다.

managed DB를 provisioned로 여는 요청은 startup fail-closed다. 묵시적 downgrade/환경 reconcile endpoint는 제공하지 않는다. provisioned DB의 기존 seed 재조정 및 테스트용 토큰 갱신은 그대로다. 실제 배포를 managed로 전환하는 행위는 구현 검증과 별개다.

### D2. Project authority

새 endpoint prefix는 `/api/v1/projects/:projectId/administration`이다. 모든 조회/mutation은 active 프로젝트 membership을 서버에서 재검사하며 managed가 아니면 명시409 `IDENTITY_STORAGE_NOT_MANAGED`로 mutation을 거부한다.

- directory GET: qa_manager 이상, 해당 프로젝트 회원만. inactive 회원을 포함한 관리 목록이며 기존 active-only `/members`를 변경하지 않는다. limit1..100, 안정 cursor, id/displayName/active/role/userRevision/membershipRevision만 반환한다.
- user 생성: system_admin, 새로운 ID + nullable displayName + 최초 role(viewer..qa_manager), active 기본true. project membership과 원자 생성한다. idempotency-key 필수. 기존 전역 ID 충돌은 generic409로 거부하며 다른 프로젝트 회원 정보를 반환하지 않는다. OIDC 로그인 binding이나 실제 token은 발급하지 않는다.
- 기존 user membership 추가: system_admin만. 알려진 ID가 존재해야 하며 다른 프로젝트 정보를 반환하지 않는다. 최고 부여 role은 qa_manager이고 system_admin 역할 신규 부여는 기존 trusted provisioning 경계다.
- role 변경/제거: qa_manager는 자신과 동급/상위 대상에 대해 거부하고 viewer/qa_tester/qa_editor 사이만 관리한다. system_admin은 기존 system_admin을 새로 만들거나 자기 역할을 바꿀 수 없다. 현재 역할과 요청 역할 모두 검사한다.
- global user active/displayName 변경: system_admin이 해당 user의 모든 membership 프로젝트에서 system_admin이어야 한다. 프로젝트 하나만 가진 관리자가 다른 프로젝트 사용자 계정을 전역 비활성화하지 못한다. 자신 변경과 마지막 active system_admin 또는 마지막 active qa_manager 이상 제거는 거부한다. 모든 영향 프로젝트에 audit을 남긴다.

hard user delete는 없다. 회원 해제와 global deactivate는 별개다. 과거 drafts/versions/runs/업무의 사용자 참조를 보존한다. 조회는 알려진 프로젝트 scope 밖의 사용자 존재 여부를 상세 에러로 누출하지 않는다.

### D3. Mutation model

새 관리 route: GET namespace root(저장 모드/mutationSupported); GET `users`; POST `users`; PATCH `users/:userId`(displayName/active/userRevision); PUT `members/:userId`(role, membershipRevision=최초0 또는 삭제 후 tombstone 값); DELETE `members/:userId`(revision query); GET `members/:userId`(해당 프로젝트의 현재/제거된 membership revision). 마지막 GET은 기존 프로젝트 이력이 있을 때만 제공해 전역 사용자 lookup으로 사용하지 않는다. 기존 HTTP route는 그대로다. 입력 unknown field/길이/enum/revision을 DTO로 거부한다. idempotency create의 응답에는 비밀정보가 없고 replay 전 transaction 안에서 현재 권한을 검사한다.

SQLite BEGIN IMMEDIATE 안에서 권한·현재revision·마지막관리자 조건을 재검사하고 row 변경+revision증가+audit을 원자화한다. stale revision409. 삭제의 과거 revision 재사용/ABA를 막기 위해 membership 관리 tombstone revision을 보존하며 재추가는 이전revision보다 증가한다. membership row를 제거해도 별도 revision 이력을 유지한다.

mode metadata는 단방향 전환만 기록하고 API로 수정하지 않으므로 별도 revision을 갖지 않는다. 기존 provisioned의 trusted 물리 user 삭제와 호환되도록 새 user sidecar FK는 ON DELETE CASCADE다. 관리 HTTP는 user hard delete를 제공하지 않으며 membership 제거는 user를 삭제하지 않아 tombstone을 유지한다.

활성/권한 변경은 기존 세션을 통해 다음 요청부터 적용된다. global deactivate 시 auth_sessions/desktop_codes를 함께 폐기하며 다시 활성화해도 과거 세션을 복구하지 않는다. 이미 시작된 Engine 실행 판정은 변경하지 않고 새 권한 요청/보고 정책은 기존 ownership 검사에 따른다. 감사에는 actor/project/action/target/revision만 넣고 credential은 넣지 않는다.

### D4. SDK and UI boundary

신규 PATCH는 optional nullable의 Dart 직렬화 누락을 피하려고 `displayName?:string`과 `clearDisplayName?:boolean`을 분리한다. 두 필드를 동시에 지정하거나 displayName:null을 보내면 400이다. clearDisplayName:true만 비우기를 뜻하며 false만 있고 다른 변경이 없으면 no-change 오류다. active-only 변경은 표시명을 보존한다. 생성/조회 응답의 required nullable displayName은 유지한다.

기존 GET members/context 응답과 nullable displayName 의미는 보존한다. 새 DTO의 nullable 필드는 실제 직렬화와 양 SDK로 검사한다. OpenAPI→generated SDK 순서이며 생성 파일 수동 수정 금지. 이 단계는 A07 API 기반이며 웹 route change가 별도 소비한다. 사용자가 없는 기능을 쓸 수 있는 것처럼 기존 context.allowedActions에 임의 문자열을 먼저 추가하지 않는다.

## Risks / Trade-offs

managed opt-in을 생략한 기존 개발 환경에서는 관리 기능이 비활성이다. 이는 기존 provisioning 호환을 위한 명시 경계다. 신규 사용자 로그인은 OIDC binding 또는 trusted 로컬 credential provisioning이 필요하며 API가 인증 비밀을 만들어 반환하지 않는다. 다중 프로젝트 사용자 전역 수정은 엄격한 권한 때문에 거부될 수 있고 프로젝트 회원 해제를 대신 사용할 수 있다.

## Validation

실제 SQLite migration/restart, 기존 provisioned seed 변화 유지, managed seed 변동 무시/강등 거부, inactive→active 과거세션 거부, 동시revision/ABA/last-admin, project 정보누출/role escalation, idempotency replay 권한철회, audit·원본 artifact/Engine pin 불변을 실제 HTTP로 검사한다. 외부 IdP/운영 DB 수정 없이 임시 로컬 fixture만 쓴다. generated 계약 compatibility/drift 및 전체 서버 회귀를 통과한 후 웹 소비를 허용한다.
