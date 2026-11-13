# Proposal

## Why

기존 Desktop Blueprint 목업은 편집 공간을 자세히 보여주지만 사용자 웹에서 공용 시나리오를 선택하고 Desktop으로 전달한 뒤 결과를 확인하는 제품 전체 흐름과 최신 로컬 AI CLI 방식을 함께 검토하기 어렵다. 현재 요구사항과 원본 사용자 여정을 바탕으로 화면 기획과 클릭 가능한 통합 목업을 만든다.

## What Changes

- 기획 보기에서 사용자·앱 역할, 핵심 여정, 화면별 인수와 후속 예약·권한 범위를 설명한다.
- 사용자 웹의 공용 시나리오/고정 버전/XML 전달/실행 요청/진행 조회를 Desktop 프로젝트/QA/Blueprint/XML/AI 검토/명시 실행/결과 화면과 연결한다.
- 기존 차콜 Desktop 도킹·컴팩트 밀도·최소 아이콘 방향을 유지하고 로컬 CLI 설정·키 미저장 정책을 반영한다.
- 모든 화면에 예시 데이터 목업임을 표시하고 검증/AI 적용/가져오기와 실제 실행의 상태 경계를 시연한다.
- 기존 목업 및 제품 소스를 보존하면서 새 경로에 HTML, 기획, 캡처, 로컬 검증 증거를 작성한다.

## Capabilities

### New Capabilities

- `qa-product-journey-review`: 웹과 Desktop의 핵심 QA 여정 및 화면 기획을 검토하는 로컬 대화형 목업.

### Modified Capabilities

없음. 기존 제품 기능과 실행 계약을 변경하지 않는다.

## Impact

소유 경로는 `design/mockups/product-flow-review/**`와 이 change다. counterpartRepoChange는 Engine의 qa-user-web-desktop-handoff 및 공개 실행 계약(읽기 전용 참고), contractVersion은 기존 서버 alpha.6/0.3.0-draft.1 및 Desktop 계획 alpha.8/0.3.0-draft.2를 변경하지 않는다. dependsOn: qa-desktop-blueprint-workspace, qa-desktop-ai-workspace, qa-user-web-desktop-handoff, qa-platform-services. acceptanceCriteria는 delta spec과 tasks에 기록한다. 실제 Flutter/웹/서버/AI/Engine 실행, 원격 게시, 의존성 추가, pin 변경은 범위 밖이다.
