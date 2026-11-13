# Proposal

## Why

Desktop는 검증된 alpha.10을 소비하지만 기본 서버·Agent demo는 alpha.6에 고정되어 현재 Desktop 실행의 게시를 거부한다. 이는 올바른 exact runtime 경계이나 사용자 웹 전달·진행 조회와 Desktop 실행 결과 공유를 연결하지 못한다. 같은 실행 패키지로 새 통합 lane을 제공하고 기존 이력은 보존한다.

## What Changes

- 서버 소유 canonical alpha.10 runtime manifest와 설치 준비 명령을 추가한다. 기존 `.local/engine` 및 legacy 앱 alpha.6 assets/계약/fixtures는 보존한다.
- 새 서버/Agent demo 기본 경로와 새 identity/state를 같은 alpha.10 package에 연결한다. 운영 환경 변수나 기존 Agent 등록을 자동 갱신하지 않는다.
- 실제 Chromium 결과·PNG를 서버에 게시하고 조회·검증한다. 실제 Agent의 Suite 순차 실행, 예약 발생, 취소와 정리 상태를 통합 인수한다.
- 과거 alpha.6 Run/버전/Agent/job/lease 조회 보존과 신규 ingestion/claim의 pin 불일치 거부를 검증한다.

## Capabilities

### New Capabilities

- `server-agent-runtime-alignment`: 서버·Agent·Desktop의 검증된 동일 runtime lane과 역사 자료 보존.

### Modified Capabilities

기존 HTTP/Agent protocol과 Engine schema는 수정하지 않는다. 실행 요청·결과·업무·lease·예약·전송/증거 상태의 의미를 유지한다.

## Impact

소유: apps/server scripts/tests 및 packages/contract/runtime 새 manifest, 관련 서버 운영 문서. 앱 담당자는 desktop assets/vendor/portable/Flutter를 별도로 소유하며 이번 change가 수정하지 않는다. counterpart: qa-desktop-portable-runtime의 이미 검증된 동일 hash runtime payload(1882파일); 최종 portable Release는 이 통합 인수 이후이므로 선행 의존이 아니다. dependsOn: qa-persistent-project-administration, Engine exact alpha.10 candidate 관리 인수 `coordination/remaining-implementation-20261112/engine-candidate-review.json`. HTTP v1/Agent0.1.0-draft.1, execution0.3.0-draft.2, authoring0.1.0-draft.1.

확정 archive SHA256 `0476445261b2596954167f335968d8bbb0a513867c930553604ba9b2b1c780e3`, execution bundle SHA256 `b99337961c1477549d9dd52b65f6ec888d47679f4735d3025435ee06881f93c1`. 소스 재포장 없이 이 archive를 소비한다. 실제 모바일 기기·외부 production 서비스·원격 배포는 범위 밖이다.
