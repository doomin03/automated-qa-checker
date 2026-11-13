# Proposal

## Why

사용자는 2026-11-11 프로젝트 메인 목록과 관리자가 게시한 QA를 받는 진입 흐름이 새 디자인에서 빠졌다고 지적했다. 실제 제품의 로컬 목록은 남아 있지만 서버 수신은 문서를 연 뒤 고급 기능 안에서만 찾을 수 있고, 수신 XML은 현재 초안에 적용되어 독립 로컬 QA 및 영속 출처와 연결되지 않는다. 목업은 편집기부터 시작한다. 편집기의 완성도가 전체 사용자 여정을 대체할 수 없다.

## What Changes

- 실제 Flutter와 목업의 시작 화면에 로컬 프로젝트, 프로젝트별 QA, 서버에서 받을 수 있는 게시 QA/ Suite, 이미 가져온 로컬 사본을 노출한다.
- 서버 연결·권한 있는 프로젝트 선택·목록 탐색·고정 버전 확인·명시 수신을 기존 API로 연결한다. 게시 목록을 개인에게 배정된 업무라고 표시하지 않는다.
- 선택한 로컬 프로젝트에 새 QA를 만들고 원본 XML과 버전 출처를 보존한다. 기존 편집 문서를 덮어쓰거나 자동 실행하지 않는다.
- 홈과 문서 작업실의 왕복, 미저장 보호, 오프라인 로컬 사본, 재수신 선택과 오류/빈 상태를 제공한다.
- 실제 기본 alpha.6 서버 API에서 받은 XML을 Desktop alpha.8에서 검증·실행하고, 이전 Release를 보존한 별도 Windows 산출물을 제공한다.

## Capabilities

### New Capabilities

- `desktop-project-home`: 프로젝트 및 QA 목록과 작업실의 완전한 진입·복귀 여정.
- `desktop-received-qa`: 게시 QA/Suite 조회·명시 수신·로컬 사본/출처 보존.

### Modified Capabilities

없음. 기준 specs가 비어 있으며 이전 change의 역사적 인수 기록은 보존한다.

## Impact

- owner: Checker `apps/app`, `design/mockups/xml-block-studio`, 해당 테스트·문서·새 Release.
- dependsOn: qa-desktop-xml-block-studio, qa-platform-services, qa-user-web-desktop-handoff, qa-organization-login, 기존 Suite 공개 API.
- counterpartRepoChange: 없음. Engine 공개 계약과 설치 파일은 읽기만 한다.
- contractVersion: Desktop `0.3.0-draft.2` / runtime `0.1.0-alpha.8`, 기본 서버/Agent `0.1.0-alpha.6` 유지. 기존 생성 HTTP SDK/API 재사용.
- acceptanceCriteria: 실제 로컬 협업 서버의 독립 검수·게시→Windows 목록/수신→새 로컬 QA→alpha.8 검증·PASS 및 재시작 출처 복원 증거. 목업/fixture와 실제 원격 운영 서비스 인수는 구분한다.
- 단계: 2026-11-11 관리 검토·strict 승인 후 제품 apply를 진행했다. 실제 Windows/API 인수 및 대상 Flutter 회귀는 통과했고 별도 Release와 최종 관리 gate를 기록한다. 기존 Release 덮어쓰기, 원격 게시·commit/push는 하지 않는다.
