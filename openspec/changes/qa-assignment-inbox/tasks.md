# Tasks

## 1. Contract

- [ ] 1.1 고정대상·업무상태·권한·receipt/run-link 및 lifecycle 의존을 관리 검토받고 strict를 통과한다.
- [ ] 1.2 assignment/history/receipt migration과 DTO/controller를 구현하고 boundedpaging·nullable dueAt·idempotency를 검증한다.

## 2. Workflow

- [ ] 2.1 배정/재배정/회수·담당자진행/검토요청·독립반려/완료와 revision/active/lifecycle 검사를 구현한다.
- [ ] 2.2 receipt·실제 Run/Suite link를 구현하고 다른project/owner/version·가짜ID·자동run0·원본결과 불변을 실제 HTTP로 인수한다.
- [ ] 2.3 재시작·중복·자기검수·권한철회·폐기·stale 담당자 요청을 회귀한다.

## 3. Consumer

- [ ] 3.1 OpenAPI/TS/Dart SDK 생성·drift/compatibility 후 웹·Desktop 담당에게 계약을 인계한다.
- [ ] 3.2 필수 서버 회귀/strict와 업무 상태≠실행 판정 안내·실제 명령/결과를 문서화한다.
