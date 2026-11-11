# 제품 기획과 단계별 인수 기준

2026-11-11 상태 정합. 초기 계획의 P2 “엔진/블록 미구현”, P3/P4 “미구현”은 scaffolding 당시 기록이었다. 아래 표는 현재 코드·실제 인수·남은 범위를 구분한다. 과거 alpha.5 인수를 현재 alpha.8 인수로 바꾸지 않는다. [통합 기획 검토](../../design/mockups/product-planning/index.html)의 관계도·25개 화면·원본 요구 대응표를 함께 본다. 새 웹 화면 분리는 설계 제안이며 현재 실제 `/qa/blueprints`, `/qa/shared` route 구현과 구별한다.

## 목적과 사용자

QA 담당자가 공통 TestCase/Suite를 내려받아 Flow를 편집하고, 동일 정의를 Desktop·CLI·Agent에서 실행해 증거와 주간 회귀를 공유한다.
사용자 웹은 공용/사용자 시나리오 XML 전달과 진행 확인을, Flutter Desktop은 블록/Flow 또는 XML 테스트 개발·실행을 맡는다. 모노레포 기반은 [이관 OpenSpec](../../openspec/changes/refactor-server-web-app-monorepo/proposal.md)에서 먼저 정합한다. health/OpenAPI/SDK bootstrap은 P3 인증/Registry와 구분하며 로컬 P2에는 서버가 필요하지 않다.
qa_editor는 정의를 작성하고 qa_tester는 허용 환경의 요청·예약·pin·업무 변경을 한다. qa_manager는 독립 검수·게시·감사·복구를 관리한다. system_admin도 프로젝트 membership 경계를 따른다. viewer는 허용 결과와 비교를 조회한다. 조직·팀·역할 CRUD, 개인 QA 할당 inbox, 전체 Agent/기기 재고 UI는 목표이며 현재 구현으로 간주하지 않는다.
역할은 Checker 서버가 조직/프로젝트 범위에서 검사하며 엔진은 업무 역할을 알지 않는다.

## 핵심 사용 흐름

1. 로그인 후 프로젝트와 고정된 Suite 버전을 선택한다.
2. 현재 제목·XML·고정 버전을 조회하거나 편집한다. 원본 TC의 번호/목적/사전조건/단계·expected/priority/tags/platform/Flow 전체 설명 폼은 후속 계약·인수 범위다.
3. Flow builder에서 노드·분기·selector·timeout/retry를 편집하고 오류를 확인한다.
4. engine capability에 맞는 target을 선택해 실행하고 node event/로그/스크린샷을 확인한다.
5. 서버에 시간대와 함께 주간 예약을 등록한다. Desktop 종료 여부와 실행은 독립이다.
6. 실제 snapshot·target·Engine runtime·profile/reference hash·환경 근거가 맞는 실행을 비교한다. 불일치나 환경 증거 부재는 비교 불가다. 원본의 브랜치/앱 빌드 정책을 현재 강제 검증 구현으로 간주하지 않는다.
7. 관리자가 업무 검토 상태를 갱신하고, 실행 판정과 독립적으로 알림을 보낸다.

## 단계와 완료 증거

| 단계 | 범위 | 인수 증거 | 현재 상태 |
| --- | --- | --- | --- |
| P0 | 원본 이관, 경계·OpenSpec·계약 | [이관 명세](../../openspec/changes/refactor-server-web-app-monorepo/design.md), [verify](../validation.md) | 기반·이관 검증. 후속 계약도 Engine→고정 artifact→Checker 순서 |
| P1 engine | 공개 schema/validate/plan/run/cancel, Playwright, 독립 package/CLI | [공개 계약·설치·실행 근거](../../design/mockups/product-planning/evidence/engine-planning-evidence.md) | Chromium 실제 PASS/FAIL/증거·독립 설치 인수. 로컬 tgz preview이며 원격 npm 운영 공개 아님 |
| P2 checker | MVVM/Provider, 프로젝트/QA·홈·수신, 파일 블록 조합·직접 XML, CLI·결과 | [홈 인수](../validation-project-home.md), [studio 인수](../validation-xml-block-studio.md) | Windows 실제 수신/검증/실행/취소/PNG·저장복원. TC 전체 메타데이터 폼·Desktop 전체 Suite UI는 미완료 |
| P3 checker | 불변 QA/Suite·독립 검수/게시·pin/diff, RBAC, local OIDC, 업무·비교 | [조직 업무](../architecture/organization-auth-workflow.md), [검증](../validation.md) | 서버·웹 구현/인수. 실 Slack 계정, 조직 CRUD·개인 inbox·반려/폐기 API는 미완료 |
| P4 양쪽 | scheduler·occurrence·lease, 독립 Agent ordered Suite, durable 보고·복구 | [서버/Agent 인수](../validation.md), [Engine 감사](../../design/mockups/product-planning/evidence/engine-planning-evidence.md) | 기본 alpha6 실제 교차 인수. 전체 fleet UI·외부 Slack 알림 미완료(local-test만) |
| P5 engine | Appium Android/iOS protocol·capability·cleanup fixture | [지원 경계](../../design/mockups/product-planning/evidence/engine-planning-evidence.md) | 실기기/에뮬레이터 환경 인수 미완료. TV 미지원. 기기·OS·driver·정리 증거 필요 |
| P6 | AI 후보·CLI/PTY·명시 적용/undo, XML round-trip·authoring 반복 | [AI](../validation-desktop-ai.md), [터미널](../validation-terminal-blueprint.md) | AI 자동 편집 반영 인수 일부 미완료. recorder·일반 whitebox·범용 코드 export 미구현; XML 저장과 구분 |

P0를 끝냈다고 P1 제품이 실행된다는 뜻은 아니다. 실제 실행 기능이 없는데 성공 결과를 반환하는 placeholder를 만들지 않는다.

현재 Desktop은 내 프로젝트 → QA 선택/서버 수신 → 새 로컬 사본 → 파일 블록/직접 XML → 검증 → 명시 실행 → 결과/원인 → 저장·홈으로 이어진다. 서버 연결 없이 로컬 작업을 할 수 있다. Suite는 고정 버전의 case 하나를 받으며 Desktop 전체 일괄실행이 아니다.

원본 `CHECKER_CODEX_PROMPT.md:13`의 TC 번호/목적/사전조건/단계·expected/priority/tags/platform/reusable Flow는 XML·제목·버전만으로 전체 완료라 할 수 없다. A02/W03/D06과 후속 계약·인수로 추적한다. 기준 이미지·시각/layout/UX는 [디자인/UX](../architecture/design-ux.md)의 profile/reference/hash·환경 조건을 따르며 자동 기준 승격이나 임의 화면 이해를 뜻하지 않는다. 원본 MD 8개→기능/화면 ID→근거→미완료/후속 인수는 통합 목업 **결정과 근거**의 대응표에 있다.

## 우선순위와 제외 범위

초기 마일스톤 순서는 서버/GUI 없는 CLI 브라우저 슬라이스 → Flutter 편집/실행 → 서버 승인/예약이었다. 현재 인수는 위 표를 따른다. 앞으로도 단계별 실제 증거를 요구하며 모바일/TV 미지원 범위를 꾸미지 않는다. 코드 생성은 선택 export 목표이며 기본 실행은 interpreter다.

## 공통 인수 기준

- Engine terminal outcome은 passed/failed/blocked/infra_error/cancelled다. assertion_failed/unsupported는 오류·사유 수준과 구분한다. 검증 실패는 미실행이며 취소 요청 중은 terminal이 아니다.
- 테스트 outcome과 업무 progress, schedule occurrence, unrun을 각각 관리한다.
- immutable snapshot, artifact hash, engine/schema version으로 재현성을 기록한다.
- secret은 참조만 저장하며 공개 CLI의 JSON/JSONL과 diagnostics 옵션 계약을 따른다. stderr가 필요한 소비자는 명시 옵션으로 요청한다.
- 해당 단계의 format/lint/typecheck/unit/contract/build/E2E를 실제 구현 후 CI에 추가한다. 현재 검사는 제품 테스트를 대체하지 않는다.

Desktop alpha.8과 기본 서버/Agent alpha.6은 별도 runtime이다. 원문 수신·로컬 실행과 결과 게시 호환은 다르며 기본 서버는 alpha.8 결과 게시를 거부한다. 로컬 판정은 유지한다. 이번 기획 목업 검증은 기존 실제 제품 인수와 별도이고 새 기능/배포/권한 계약은 별도 OpenSpec을 거친다.

