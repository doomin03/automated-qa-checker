# Tasks

## 1. Contract

- [ ] 1.1 moderation/lifecycle·claim 시점 정책·legacy origin 복원 설계를 관리 검토받고 strict를 통과한다.
- [ ] 1.2 별도 revision/lifecycle/history migration과 기존 자료·immutable trigger 보존 회귀를 구현한다.

## 2. Review and eligibility

- [ ] 2.1 Registry/Suite 수정·반려·재제출 및 독립검수/publish 최종 revision 확인을 구현하고 지연 plan race를 검증한다.
- [ ] 2.2 폐기 조회/mutation·신규 pin/Suite/queue/예약/claim gate를 구현하고 claimed 실행 보존 및 legacy origin 처리를 검증한다.

## 3. Handoff

- [ ] 3.1 실제 HTTP 권한/revision/idempotency/변조·과거 SHA/pin/result 불변을 검증한다.
- [ ] 3.2 OpenAPI/양 SDK 생성·compatibility/drift를 통과하고 웹/assignment에 계약을 인계한다.
- [ ] 3.3 필수 회귀·strict 결과와 폐기/반려 의미·미완료를 문서화한다.
