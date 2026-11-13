# 프로젝트 사용자 영속 관리

`qa-persistent-project-administration`은 A07의 서버 API와 저장 기반을 제공한다. A07 웹 관리 화면은 아직 구현하지 않았으며, 현재 웹에서 사용자 생성·권한 편집이 가능하다는 의미가 아니다. Engine 실행 계약과 판정, 기존 게시 원본은 변경하지 않는다.

## 저장 모드와 전환

`QA_IDENTITY_STORAGE`를 생략하면 `provisioned`다. 이 모드는 기존처럼 시작할 때 환경 identity의 활성 상태와 membership을 적용하며 관리 mutation은 409 `IDENTITY_STORAGE_NOT_MANAGED`로 거부한다. 관리 status 조회의 `mutationSupported`는 false다.

`managed`는 명시적으로 선택한다. 운영 DB를 변경하기 전에 서버를 중지하고 SQLite DB와 관련 파일을 일관된 백업으로 보관해야 한다. 빈 DB에는 유효한 identity seed를 한 번 넣는다. 사용자가 이미 있는 DB에서는 새 seed 전체를 무시하고 기존 사용자·활성·membership을 보존한다. 따라서 seed에 새 관리자만 추가해서 기존 DB를 managed로 전환하거나 복구할 수 없다. 전환 전 실제 DB에 active `system_admin` membership이 있어야 하며 없으면 진단과 함께 시작을 거부한다.

전환 이후 seed는 사용자·role·표시명·credential을 갱신하지 않는다. singleton mode에는 revision이 없다. 모드는 한 방향으로만 전환되며 API 수정 대상이 아니기 때문이다. 사용자와 membership에는 각각 revision을 두고, membership을 제거해도 revision tombstone을 남겨 오래된 수정의 재사용을 거부한다.

이번 migration 10은 운영에 배포하지 않은 개발 변경이다. 검증 중 기존 provisioned의 물리 사용자 삭제와 호환되도록 신규 sidecar의 user FK를 cascade로 수정했다. 관리 API는 물리 사용자 삭제를 제공하지 않는다. 수정 전 임시 DB를 운영에 재사용하지 않으며 이미 배포된 migration을 수정한 것으로 취급하지 않는다.

managed DB를 provisioned로 다시 열면 시작을 거부한다. 되돌리기는 환경 변수만 바꾸는 작업이 아니다. 전환 전 백업 복구에는 전환 이후 변경의 손실 판단과 별도 운영 승인이 필요하다. managed 운영 중 새 `system_admin`을 HTTP나 seed 재적용으로 추가하는 기능은 제공하지 않는다. 기존 관리자의 인증 접근을 복구할 때는 기존 사용자 ID를 유지한 신뢰 가능한 IdP binding 복구 절차를 사용한다. DB 자체의 관리자 정보가 손실된 경우에는 서버를 중지하고 승인·감사 가능한 백업 복구 또는 별도 검토된 오프라인 복구 절차가 필요하다. 이 저장소에는 이를 우회하는 승격 endpoint나 자동 복구 스크립트가 없다.

## 조회와 변경

모든 경로는 `/api/v1/projects/:projectId/administration` 아래에 있다.

| 경로 | 동작 | 최소 권한 |
| --- | --- | --- |
| GET `/` | 저장 모드·mutation 지원 여부 | qa_manager |
| GET `/users` | 해당 프로젝트의 활성·비활성 회원, nullable 표시명, 두 revision | qa_manager |
| POST `/users` | 새 사용자와 최초 membership 원자 생성 | system_admin |
| PATCH `/users/:userId` | 표시명·전역 활성 상태 변경 | 대상의 모든 membership 프로젝트에서 system_admin |
| GET `/members/:userId` | 해당 프로젝트의 현재 또는 제거된 membership revision | qa_manager |
| PUT `/members/:userId` | 알려진 사용자 추가 또는 role 변경 | 추가는 system_admin, 하위 role 변경은 qa_manager |
| DELETE `/members/:userId` | 프로젝트 회원 해제, tombstone 보존 | system_admin 또는 하위 대상의 qa_manager |

directory는 limit 1..100과 불투명 cursor를 사용한다. 다른 프로젝트의 사용자 목록이나 credential·token hash·IdP subject는 반환하지 않는다. 기존 active-only `/members`와 context DTO는 그대로다.

PATCH의 표시명 설정은 `displayName` 문자열, 비우기는 `clearDisplayName:true`를 사용한다. 두 필드 동시 지정과 `displayName:null`은 거부한다. `clearDisplayName:false`만 보내는 요청은 변경이 없으므로 거부한다. `active`만 변경하면 기존 표시명은 유지된다. 생성과 응답의 표시명은 required nullable이며 TS/Dart 직렬화에서 명시 null을 보존한다.

qa_manager는 자기 자신·동급·상위 회원을 변경하거나 qa_manager 이상을 부여할 수 없다. system_admin도 자신을 변경하거나 새 system_admin을 부여할 수 없다. 마지막 활성 관리자 보호, 현재 권한, revision, audit은 SQLite `BEGIN IMMEDIATE` 트랜잭션 안에서 검사한다. 생성에는 idempotency-key가 필요하고, replay도 현재 권한을 다시 검사한다.

전역 비활성화는 같은 DB의 web/desktop 세션과 미사용 desktop code를 폐기한다. 재활성화는 과거 세션을 복원하지 않으므로 다시 로그인해야 한다. membership 변경은 이미 발급된 세션의 다음 요청부터 적용한다. 과거 게시 버전과 Run 판정은 바꾸지 않는다. 이전 review를 수행한 회원의 권한이 철회되면 새 publish는 기존 서버의 reviewer 권한 검사에 따라 거부된다.

## 새 사용자의 로그인

사용자 생성은 로그인 credential 발급이나 초대가 아니다. API는 token/password를 반환하지 않으며 외부 IdP subject binding을 만들지 않는다. 운영자는 기존 신뢰 경계에서 해당 사용자 ID의 binding을 별도로 준비해야 한다. 로컬 테스트용 identity와 실제 외부 IdP 인수는 구분한다. 관리 UI 후속 구현은 이 준비 상태와 provisioned 모드의 미지원 상태를 설명해야 한다.

## 검증 근거

`apps/server/test/administration.test.mjs`는 실제 SQLite와 HTTP로 mode adoption/downgrade, scoped paging, hierarchy, stale/ABA revision, idempotency 재권한 검사, 다중 프로젝트 변경, 동일 DB의 세션 폐기, 재시작을 검증한다. `fixtures/administration-alpha6-run/provenance.json`에 연결된 기존 실제 Chromium 실행의 원본 bytes를 새 임시 서버에 게시·수신한 뒤 관리 변경과 재시작 전후 DB rows/events/GET 응답 및 hash를 비교한다. 이는 새 브라우저 실행이나 PNG 인수가 아니며 해당 실행에는 PNG artifact가 없다.

실제 배포의 모드 변경, 운영 DB 복구, 외부 IdP 로그인, A07 웹 화면은 이 서버 인수에 포함하지 않는다.
