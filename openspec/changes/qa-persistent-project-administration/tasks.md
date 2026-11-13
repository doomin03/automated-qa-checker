# Tasks

관리 검토·strict 후 apply 및 실제 인수를 완료했다. 근거는 docs/validation-project-administration.md와 artifacts/administration/이다. A07 웹 화면은 별도 후속 범위다.

## 1. Contract and storage

- [x] 1.1 managed opt-in/default provisioning/기존 DB 전환·downgrade 거부 및 권한 표를 관리 검토받고 strict를 통과한다.
- [x] 1.2 migration·identity mode·user/membership revision/tombstone을 구현하고 기존 provisioned 및 managed 재시작 보존을 실제 SQLite로 검증한다.

## 2. Administration API

- [x] 2.1 project directory와 user/member mutation DTO/controller/service를 구현하고 paging/nullable/unknown field/idempotency를 검증한다.
- [x] 2.2 role escalation·다중프로젝트 global 변경·마지막관리자·자기변경·ABA/stale revision 및 audit 원자성을 실제 HTTP로 검증한다.
- [x] 2.3 비활성화 시 세션/desktop code 폐기와 재활성 이후 재인증, reviewer 권한 철회 및 과거 결과 불변을 검증한다.

## 3. Consumer and acceptance

- [x] 3.1 OpenAPI와 TS/Dart SDK를 고정 generator로 생성하고 drift/compatibility/nullable 응답 소비를 검증하여 웹 담당에게 인계한다.
- [x] 3.2 서버 전체 회귀·repository 필수 검증·strict를 수행하고 명령/결과/기존 dirty 보존 및 외부 IdP 미인수를 문서화한다.
- [x] 3.3 managed 전환과 rollback 제한·사용자 로그인 binding 준비·관리 권한을 운영 안내에 기록하고 A07 웹 후속 change와 연결한다.
