# Product-planning과 실제 서버 관계

기준은 main `3e73cd1f14b0aab658748e9c9b5c1be4a87794ad`의 `design/mockups/product-planning` index/data/prototypes/requirements/evidence와 `qa-product-planning-backend-context`다. 목업 체크 통과는 실제 서버 인수가 아니며 이번 실제 인수는 별도 validation 문서에 기록한다.

| 기획 화면 | 실제 관계와 API | 이번 범위 |
| --- | --- | --- |
| D01 프로젝트, D02 QA 목록 | 로컬 workspace와 서버 프로젝트는 별개 식별자. `getIdentity`, `listProjects`, 새 `getProjectContext` | 서버 역할과 runtime을 앱이 명시적으로 선택한 프로젝트에서 조회 |
| D03 공용 수신, W02–W04 | Registry versions/pins/detail/diff, Suite versions/detail/pin, 새 `listSuitePins` | 사용자별 Suite 고정을 다시 열고 순서 있는 case를 개별 수신. 수신 자체는 실행 아님 |
| D04–D06 편집/검증/실행 | 로컬 XML/Flow/Engine CLI, 공유 시 createSharedRun/events/result/artifacts | 로컬 alpha.8 실행과 alpha.6 서버 공유 호환을 분리. DSL 변경 없음 |
| D07 결과, D08 AI 도구·터미널 | 로컬 결과/AI 도구·터미널과 선택적 서버 shared run | 서버 context는 연결·공유 상태에 사용. 로컬 경로/비밀은 API 미노출 |
| W01 조직/프로젝트 | auth start/session/logout, identity/projects | 인증/프로젝트 범위 기존 정책 유지 |
| W05–W06 실행 목록/상세 | shared runs, pollRunEvents, downloadRunArtifact | 판정·evidence·업무 상태 별개 |
| W07 파일 전달 | XML 파일 수신 및 Registry source 조회 | 원본을 전달하며 서버 실행을 합성하지 않음 |
| W08 실행 요청 | createExecution, list/getExecution, cancelExecution | 접수/lease/종료는 별도 단계. 취소 요청은 종료 확정 아님 |
| A01–A02 초안/검토/게시 | Registry와 Suite draft/review/publish | author와 독립 reviewer, immutable version/hash 유지 |
| A03 업무/회귀 | get/updateRunWork, compare/selectBaseline, 새 listProjectMembers | active 프로젝트 회원 조회만 추가. 현재 Desktop에는 배정 편집 UI 없음 |
| A04 예약 | create/list/enableSchedule, listOccurrences | 실행 성공과 occurrence skipped/queued/reason 구분 |
| A05 실행 운영 | execution/cancel/recovery | recovered를 passed 또는 cleanup confirmed로 바꾸지 않음 |
| A06 감사/알림 | listProjectAudit, notification enqueue/status | 실제 Slack 계정 연결은 이번 범위 아님 |
| A07–A08 관리 CRUD/Agent 관리, 개인 QA inbox | 후속 기획 | 새 CRUD/배정/Agent inventory를 만들지 않음 |

## 추가 조회 계약

모든 경로는 `/api/v1` 아래다. 기존 bearer 또는 session 인증을 그대로 사용한다.

`GET projects/{projectId}/context` (`getProjectContext`)는 `ProjectContextResponse`를 반환한다. `projectId`, `role`, `allowedActions`와 중첩 `engine`의 `engineVersion`, `contractVersion`, `contractSha256`, nullable `archiveSha256`이다. runtime/contract hash는 서버 시작 시 검증한 설치의 값이다. archive hash는 설치 manifest pin metadata이며 현재 archive bytes를 다시 검사했다는 뜻이 아니다. GET은 CLI를 시작하지 않는다.

| 최소 역할 | 추가 allowedActions |
| --- | --- |
| viewer | readPublished |
| qa_tester | pinVersions, publishRuns, requestExecutions, manageSchedules, updateWork |
| qa_editor | createDrafts |
| qa_manager | reviewPublish, viewAudit, listMembers |
| system_admin | manager와 동일 |

이는 위 capability의 **진입권한 힌트**다. 모든 API의 완전한 권한 목록이나 요청 성공 보증이 아니다. 실제 mutation이 현재 membership, 객체 소유권, 독립 검토자, revision, 정확한 runtime과 version/hash를 최종 검증한다. 자기 draft 검토는 manager라도 거부한다.

`GET projects/{projectId}/suites/pins` (`listSuitePins`)는 기존 `PinPage`를 반환한다. 각 item은 `packageId/versionId/sha256`이다. 현재 사용자와 프로젝트에 한정하며 viewer도 자기 고정을 읽을 수 있다. 쓰기는 기존 tester 권한을 유지한다. limit 1..100(기본 50), canonical base64url rowid cursor를 사용한다. 구버전 pin을 삭제/승격하지 않는다. `getSuite`의 version/Engine/contract와 context를 비교한다. immutable version과 FK로 정상적인 원본 삭제는 금지된다. paging은 snapshot이 아니므로 도중 pin 갱신은 현재 값으로 관측된다.

`GET projects/{projectId}/members` (`listProjectMembers`)는 manager 이상에게 활성 프로젝트 회원의 `userId`, `role`, `displayName:null`만 제공한다. 현재 저장소에 이름 필드가 없어 null이며 새 DB column은 없다. `ProjectMemberPage`의 limit/cursor는 같은 형식이고 users.rowid 순이다. 타 프로젝트 회원 및 token hash를 노출하지 않는다. 조회 이후 권한이 달라져도 업무 수정에서 membership과 revision을 다시 확인한다.

## 여섯 상태 축과 runtime 경계

Engine outcome, execution/lease 상태, evidence 상태, 업무 todo/in_progress/done, 예약 occurrence 상태/사유, Desktop 전송 상태를 서로 대체하지 않는다. work done은 passed가 아니며, 요청 접수는 실행 완료가 아니다. Suite stopOnFailure 뒤 미실행 case는 unrun으로 남고 결과를 합성하지 않는다.

기본 서버/Agent는 alpha.6, 새 Desktop 로컬 Engine은 alpha.8이다. 버전/contract/bundle hash 불일치를 조회로 설명할 수 있지만 이 변경은 runtime을 승격하거나 공유 차단을 해제하지 않는다. 공용 source 수신·로컬 편집·검증/실행 가능과 서버 공유 가능을 구분한다. 서버 주도 실행은 기존 alpha.6 lane으로 유지한다.

서버/계약 담당자가 HTTP 계약과 SDK를 확정한 뒤 Flutter 담당자가 D01–D08에서 소비한다. 생성 파일을 수동 수정하지 않으며 `pnpm run contract:generate`와 `contract:check`로 재현한다.
