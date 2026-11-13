# Proposal

## Why

공용 QA 목록과 개인 pin은 업무 배정함이 아니다. 기존 RunWork는 실행 이후 담당자 상태만 저장하므로 실행 전 고정 QA/Suite를 누가 받아 수행할지 관리할 수 없다. 원본 Suite assignment와 개인 inbox를 실제 계약으로 추가한다.

## What Changes

- 프로젝트 고정 QA/Suite version/hash를 대상으로 하는 assignment와 개인 inbox를 추가한다.
- manager 배정·회수·재배정, 담당자 수신/진행/검토요청, 독립 업무검수의 반려/완료를 revision과 감사로 보존한다.
- 기존 원본 수신과 optional 실제 Run 링크를 연결하지만 Engine Run/lease를 합성하거나 outcome을 변경하지 않는다.
- lifecycle·활성 membership·runtime 불일치를 확인하고 additive OpenAPI/양 SDK를 제공한다.

## Capabilities

### New Capabilities

- `personal-assignment-inbox`: 고정 게시물의 사전 배정·수신·업무 검토를 실제 실행 판정과 분리한다.

### Modified Capabilities

없음. 기존 RunWork todo/in_progress/done은 변경하지 않는다.

## Impact

dependsOn: `qa-registry-review-lifecycle`, `qa-product-planning-backend-context`; 활성 사용자 관리는 `qa-persistent-project-administration`과 연계하지만 기존 provisioning 사용자도 배정 가능하다. counterpart: `qa-web-project-workspaces`, 후속 Desktop inbox 소비. contractVersion `/api/v1` additive, Engine schema/pin 변경 없음. 서버·DTO·generated SDK·서버tests/docs 범위이며 Flutter 제품 변경은 별도 담당 인계 후다.
