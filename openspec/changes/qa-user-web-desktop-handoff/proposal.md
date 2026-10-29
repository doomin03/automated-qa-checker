# Proposal

## Why

사용자 웹을 관리자 전용으로 좁힌 기존 설명은 최신 제품 요구와 다르다. 공용 테스트 시나리오 XML을 웹에서 전달하고 Flutter Desktop에서 개별 테스트를 개발·실행하며 실제 진행을 확인하는 흐름이 필요하다.

## What Changes

- 웹을 사용자 공용 시나리오·진행 앱, Flutter를 로컬 테스트 개발·실행 앱으로 명확히 한다. 관리자 기능은 역할에 따른 후속 기능이다.
- 웹에서 편집·검증한 임의 Blueprint를 엔진이 소유한 qa.blueprint/v1 XML 형식으로 내보내고 파일 전달로 Desktop에 연결한다. 웹 XML 가져오기는 후속이며 기존 JSON 편집은 유지한다.
- Flutter Desktop 최소 앱에서 XML/JSON 열기·편집·저장, 엔진 검증, 사용자 명시 실행, JSONL 진행 및 결과 표시를 구현한다.
- 서버 동기화·직접 네트워크 전송·자동 실행은 이번 첫 파일 전달 단위에 포함하지 않는다. 전체 drag/drop P2 인수는 별도 유지한다.

## Capabilities

### New Capabilities

- qa-user-web-desktop-handoff: 사용자 웹 시나리오 파일과 로컬 Desktop 테스트 실행의 연결.

### Modified Capabilities

없음. 기준 specs는 아직 없으며 관련 진행 중 change의 역할 설명도 최신 사용자 요구에 맞춘다.

## Impact

- integrationId: qa-user-web-desktop-handoff
- contractVersion: 0.1.0-draft.1 (qa.blueprint/v1). 현재 소비 engine은 0.1.0-alpha.1, 목표 0.1.0-alpha.2는 아직 미발행이며 Engine 담당 검증 후 고정한다.
- dependsOn: refactor-server-web-app-monorepo의 기반·역할 명세, qa-ai-blueprint, qa-flow-editor P0, engine qa-user-web-desktop-handoff
- counterpartRepoChange: automated-qa-engine/openspec/changes/qa-user-web-desktop-handoff
- acceptanceCriteria: 웹 생성 XML→engine import round trip·잘못된 입력 거부, Flutter analyze/test, engine CLI 실제 PASS/FAIL 연동, Windows build 성공과 실제 앱 실행 증거를 확인한다. 환경 제약/실패는 기록하고 해당 task를 미완료 유지한다. 가져오기만으로 실행하지 않는다.

현재는 사용자 지시에 따른 모노레포 OpenSpec 이관·정합을 먼저 수행하며 제품 구현 재개는 관리 검토 후 할당한다. 파일 전달은 첫 slice이며 공용 XML의 서버 전달과 진행 자동 수신 전체 목표를 대체하지 않는다. 후속 서버 기능은 qa-platform-services에서 추적한다.
