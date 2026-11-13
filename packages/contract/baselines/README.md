# HTTP 호환성 기준

`reviewed-local.json`은 2026-10-31 Suite/Scheduler/Auth/Agent를 포함한 실제 offline exporter bytes를 복사한 새 로컬 검토 기준이다. source와 SHA-256, 관리 수용 여부는 metadata에 기록한다. 최초 health hash의 원문을 찾지 못해 추정 복원하지 않았다. 최초 health/원격 branch 기준과 동일하다고 주장하지 않는다.

`pnpm contract:compatibility`는 accepted metadata와 보존된 bytes hash를 먼저 확인한다. 최초 원격 branch에는 이 baseline이 없었으므로 현재 checkout의 검증된 snapshot을 bootstrap 기준으로 관리 수용한다. 이후 기준을 갱신하려면 별도 리뷰가 필요하다. 자동으로 현재 계약을 baseline에 덮어쓰지 않는다.

명시 비교는 `node scripts/check-api-compatibility.mjs --baseline <file>` 또는 `--base-ref <git-ref>`로 실행한다. base-ref는 해당 ref의 `packages/contract/openapi.json`을 읽으며 없으면 실패한다. 누락 기준을 현재 파일로 대체하지 않는다. 삭제/type/required/nullable/operationId/enum 및 optional 추가 호환성 회귀는 `tests/api-compatibility.test.mjs`에 있다.
