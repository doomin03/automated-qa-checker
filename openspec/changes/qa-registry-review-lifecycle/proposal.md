# Proposal

## Why

A01/A02는 초안 생성·독립 승인·게시만 지원한다. 잘못된 초안 수정/반려 및 게시물 폐기를 수행할 계약이 없으며 immutable version을 직접 수정하면 기존 pin·receipt·예약·결과의 원본이 깨진다.

## What Changes

- Registry/Suite 초안에 별도 revision·moderation 정보를 추가하고 수정/반려/재제출을 제공한다. 내용 수정은 기존 승인을 무효화한다.
- 게시 XML·Suite row를 변경하지 않는 별도 lifecycle 기록으로 신규 이용을 중지한다. 과거 원문·pin·증거 조회를 보존한다.
- 신규 pin/배정/실행·예약 및 claim 직전 lifecycle을 확인한다. 실행 중 lease와 결과를 무음 취소하거나 성공으로 변경하지 않는다.
- 기존 응답 enum을 확장해 구 소비자를 깨뜨리지 않고 별도 lifecycle/moderation endpoint와 생성 SDK를 제공한다.

## Capabilities

### New Capabilities

- `registry-review-lifecycle`: 수정·반려·재검수 및 불변 게시물 이용 중지를 지원한다.

### Modified Capabilities

없음. 기존 published bytes와 엔진 실행 의미는 보존하고 새 이용권위 검사를 추가한다.

## Impact

dependsOn: `qa-auth-workflow`, `qa-shared-suites`, `qa-agent-protocol`. counterpart: `qa-assignment-inbox`, `qa-web-project-workspaces`. contractVersion: `/api/v1` additive; Engine 공개계약/기본 pin 변경 없음. 서버 Registry/Suite/Scheduler/Agent source와 tests, DTO/OpenAPI/생성 SDK, docs만 이 change에서 다룬다. Flutter·Engine·배포 artifact는 편집하지 않는다. strict+관리검토 후 적용한다.
