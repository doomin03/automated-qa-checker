# Design

## Context

Registry/Suite는 immutable version과 개인 pin을 제공하고 RunWork는 실제 run_id의 업무다. assignment는 실행 전 별도 엔티티로 추가한다. qa_manager가 active 프로젝트 사용자에게 고정version을 배정하며 공용 목록을 개인 할당목록으로 바꾸지 않는다.

## Decisions

### D1. Data and API

assignments(id,project_id,target_kind,version_id,sha256,assignee_id,created_by,due_at,note,state,revision,created_at,updated_at), assignment_history 및 assignment_receipts를 migration한다. target_kind registry/suite, target version/hash는 생성 후 불변이다. 바꾸려면 기존 assignment 회수 후 새로 만든다. dueAt은 nullable RFC3339 UTC instant이며 화면은 사용자 timezone을 별도 표시한다. note/rejection reason은 최대2000자다.

GET `/projects/:p/assignments?scope=mine|project&cursor&limit`와 GET `/:id`, POST 생성, PATCH `/:id`(dueAt/note/assigneeId,revision), POST `/:id/transitions`, POST `/:id/receipt`, PUT `/:id/run-link`를 추가한다. limit1..100, stable cursor, 다른project/담당자는 조회불가다. mine은 본인만, project목록은 qa_manager 이상이다. create는 idempotency-key, mutation은 revision 필수. 상세에 target exact pin/lifecycle/runtime metadata와 업무 history boundedpage를 반환하되 secret이나 실행설정 경로는 반환하지 않는다.

### D2. Work state independent of result

state는 assigned/in_progress/in_review/completed/rejected/revoked다. 담당자는 assigned/rejected→in_progress, in_progress→in_review를 요청할 수 있다. qa_manager는 in_review→completed 또는 rejected(reason필수), 활성 업무→revoked(reason필수)를 요청한다. 검수자는 담당자와 달라야 한다. completed/revoked는 terminal이며 재실행/새업무는 새 assignment다. 재배정은 manager, completed/revoked에서는 거부, 새 담당으로 assigned+revision 증가하며 기존 receipt/run link를 history로 보존하고 현재 완료 증거로 재사용하지 않는다.

업무 completed는 테스트 passed를 뜻하지 않는다. 실패/미실행을 검토해 업무를 끝낼 수 있으나 manager는 명시 결과 근거/사유를 확인하고 state 전이는 Engine outcome을 변경하지 않는다. 기존 RunWork 상태·알림 payload는 재정의하지 않는다.

### D3. Receipt and actual run links

receipt는 담당자의 명시 수신 확인이며 target version/hash, receivedAt, optional localReceiptId(opaque bounded)를 저장한다. 로컬경로·XML·token을 전송하지 않는다. 브라우저 파일 다운로드만으로 실제 Desktop 저장 확인을 자동 생성하지 않는다. receipt 생성은 run/queue/lease를 만들지 않는다.

run-link는 해당 project의 실제 저장 Run을 조회해 target QA versionId/hash와 owner가 현재 assignee인지 확인한다. Suite는 실제 Suite execution과 case Run 목록의 고정 pin을 연결하는 별도 variant로 받고 단일 case 성공을 Suite 완료로 취급하지 않는다. 불일치/미실행 가짜 ID/수신 전에 합성한 ID를 거부한다. 완료를 위해 run-link를 필수로 만들지는 않으며 unavailable/no-run은 명시 표시한다. link를 변경해도 원본 Run은 불변이다.

### D4. Authority, lifecycle and races

모든 mutation transaction에서 active membership, 담당자/검수자 및 target lifecycle을 재검사한다. 폐기된 target에는 새 assignment/receipt/run-link를 금지하고 기존 history는 읽기 보존한다. withdraw 후 기존 업무는 manager가 이유를 확인해 revoke하거나 검토 종료할 수 있다. 비활성 담당자가 남은 업무는 orphaned-assignee로 표시하고 manager 재배정을 요구하며 서버가 임의 새사용자를 선택하지 않는다.

runtime 불일치는 assignment나 과거 history를 지우지 않는다. 수신/실행/게시 호환성은 기존 고정 pin과 context로 별도 표시한다. API 성공을 실제 기기 실행 가능 또는 cleanup 완료로 해석하지 않는다. 모든 idempotency replay도 현재권한을 검사한다.

### D5. Consumer handoff

웹의 사용자 inbox/manager 배정·검수는 후속 route change에서 구현한다. Desktop D03은 기존 server receive/local receipt 흐름에 연결하는 별도 담당이며 이 change에서 앱을 수정하지 않는다. SDK 계약 완료 후 identity/revision/lifecycle 경계를 인계한다.

## Validation

실제 HTTP/SQLite에서 생성/중복·mine/projectscope·비활성/다른프로젝트·self-review·revision/reassign ABA·dueAt·withdraw·재시작·run-link owner/version 검증·자동run0을 확인한다. 업무 반려/완료 전후 Engine result bytes/SHA와 기존 RunWork가 불변이어야 한다. 외부 메시지/단말/Flutter 실행은 포함하지 않는다.
