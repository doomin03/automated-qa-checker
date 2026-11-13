# Design

## D1. 고정 입력과 역할

Suite는 Checker 업무 DTO다. draft는 packageId/title/stopOnFailure와 ordered cases[{caseId,versionId,sha256}]를 가진다. caseId는 고유하며 case 개수1..32, 모두 동일 프로젝트 published Blueprint여야 한다. 공개 Engine의 현재 runtime/contract 호환 pin과 달라진 버전은 자동 승격하지 않고 거부한다. 각 case XML은 Registry의 불변 bytes에서 가져온다.

## D2. 검수·발행

qa_editor는 초안을 만들고 qa_manager는 작성자와 다른 계정으로 검수한다. 발행 transaction에서 검수자 활성 membership과 case hash/호환성을 다시 확인한다. packageId+version 중복은409, 동일 idempotency key+같은 payload 재시도는 같은 발행본을 반환한다. 발행 후 SQL trigger가 변경·삭제를 막는다. Suite hash는 package/version/title/ordered case refs/content hash/stopOnFailure의 canonical JSON SHA256이며 Engine Blueprint snapshot hash와 별개다. pin은 tester 이상, exact hash와 함께 저장한다.

## D3. 실행 요청 경계

SuiteService.resolvePublished(user,projectId,suiteVersionId,sha256?)는 읽기 권한과 hash·호환성을 확인하고 `{suitePolicy:{stopOnFailure,publishedVersionId,publishedSha256},cases:[{caseId,versionId,sha256,xml}]}`을 반환한다. Agent enqueue 담당이 case별 공개 CLI plan 및 target/resource 권한을 검증하고 queue에 고정한다. 원문 XML·flow를 UI/서버가 해석해 실행하지 않는다. stopOnFailure와 unrun 후속 case는 Agent 계약을 따른다. 사용자 웹은 고정 Suite 선택 후 명시 실행 요청을 보낸다.

## D4. 인수와 소유

SQLite migration6/transaction, audit, 목록 cursor는 현재 플랫폼 방식을 따른다. 실제 HTTP 권한·cross-project·case 중복·hash·runtime mismatch·독립 검수·발행 동시성·restart·immutable trigger를 검증한다. 생성 SDK 및 실제 사용자 웹 인수는 별도 task다. scheduler와 Agent worker 구현은 qa-agent-protocol 담당에게 유지하며 Suite task로 중복 완료하지 않는다.
