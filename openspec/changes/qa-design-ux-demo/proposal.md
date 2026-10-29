# Proposal

## Why

현재 Checker는 초안 파일 편집과 웹 이벤트 관찰만 제공하여 디자인 기준과 배포 웹의 차이, 반복되는 기본 UX 동작을 사용자가 검수할 수 없다. 로컬 PNG·명시 수치를 기준으로 기본 Blueprint를 바인딩하고 실제 엔진 증거를 확인하는 기능 중심 데모가 필요하다.

## What Changes

- Flutter에서 로컬 export PNG와 명시 수치 JSON, selector 매핑, 테스트 URL/profile을 입력한다. 이미지에서 없는 수치나 뒤로 가기 기대 결과를 추정하지 않는다.
- 기본 UX Blueprint 팩을 선택하고 필수 입력을 매핑하여 XML을 작성·검증·계획·명시 실행·취소한다. Engine가 정본 계약과 측정·비교·실행을 소유한다.
- baseline/actual/diff 경로, 측정값, 실패 단계와 비교 불가/미지원 상태를 간단한 입력·버튼·텍스트 결과로 표시한다. 기준 변경을 자동 수용하지 않는다.
- feature-first MVVM/Provider와 기존 CLI bridge/Run 화면 작업을 재사용한다. CLI 독립 데모와 Flutter 사용자 실행 경로의 인수는 구분한다.
- 디자인 작업, 복잡한 비교 UI, Figma 직접 API, 서버 동기화, Appium 및 실제 OS 키보드 검사는 후속이다.

## Capabilities

### New Capabilities

- qa-design-ux-workbench: 로컬 디자인 기준·UX 프리셋을 대상 웹에 연결하고 실제 실행 증거를 검토하는 Desktop 작업 흐름.

### Modified Capabilities

없음. 기준 specs는 아직 없으며 진행 중 changes와의 공유 작업은 design의 소유권 표로 연결한다.

## Impact

- integrationId: qa-design-ux-demo
- counterpartRepoChange: automated-qa-engine/openspec/changes/qa-design-ux-demo
- contractVersion: 신규 디자인/UX 계약은 draft이며 차기 공개 version/hash는 pending. 현재 Checker pin은 engine 0.1.0-alpha.1 / contract 0.1.0-draft.1이다. Engine alpha.2 배포 증거와 이 신규 기능의 구현·호환성을 동일시하지 않는다.
- dependsOn: Engine counterpart의 계약·구현·고정 release, qa-user-web-desktop-handoff의 XML/CLI, qa-flow-editor의 capability/Run 표시, refactor-server-web-app-monorepo의 Flutter shell.
- affectedAreas: apps/app의 MVVM feature와 공개 계약 소비 경계. Engine 소스 복사·비교 알고리즘 중복 구현·새 서버는 포함하지 않는다.
- acceptanceCriteria: 실제 웹 PASS/의도적 FAIL, 잘못된 매핑·비교 불가·미지원·취소·불완전 결과를 검증하고 Flutter 입력→실행→결과 경로 및 Windows build를 별도 입증한다. CLI 성공만으로 Flutter 인수를 완료하지 않는다.

이번 할당은 명세 작성·strict 검증까지다. 제품 구현은 관리 검토 후 apply로 진행하며 모든 새 구현 tasks는 미완료로 남긴다.
