# Proposal

## Why

통합 기획의 D01–D08은 실제 구현된 홈·수신·편집·실행 흐름이지만, 고정 폭/높이의 패널과 대화상자는 작은 창·큰 글자에서 같은 작업을 끝낼 수 있음을 보장하지 않는다. 기획 관계도의 원본 버전·로컬 사본·실행 결과·게시 상태를 화면에 일관되게 연결하고 기존 기능의 접근성을 실제 Windows 앱에서 인수한다.

## What Changes

- D01–D08 및 사용자 여정을 기존 코드/검증/이번 보완/후속 목표로 대응한다. 원본 기획과 기존 완료 명세는 보존한다.
- 홈, QA 목록, 서버 수신, XML 파일 블록 작업실, 직접 문서, 결과, AI 도구의 도구 모음·패널·대화상자·스크롤을 실제 가용 크기와 사용자 글자 배율에 맞춘다. ScreenUtil은 추가하지 않는다.
- 좁은 창에서 숨긴 탐색·라이브러리·속성·AI·결과에 명시적 재접근 경로를 제공한다. 터미널과 결과가 열려도 주 편집 영역과 필수 액션을 잃지 않는다.
- 서버의 검증된 프로젝트 context/런타임/권한 및 Suite pin 조회를 생성 SDK로 소비한다. 기본 alpha6 서버와 alpha8 Desktop의 게시 불일치를 로컬 실행 판정과 분리한다.
- 직접 문서의 터미널 편집→전체 Engine plan→충돌 없는 GUI 반영, XML 파일 블록 합성과 실행 sourceMap 경계를 현재 통합 화면에서 인수한다.
- 800×600부터 큰 창, 낮은 높이, text scale 1.25/1.5, 긴 한국어와 실제 Windows 사용자 여정을 검증하고 별도 Release를 만든다.

## Capabilities

### New Capabilities

- `desktop-adaptive-workbench`: 창·글자·내용 크기에 따른 작업 영역과 패널 접근, 스크롤·포커스·상태 보존.
- `desktop-project-execution-context`: D01–D08의 출처·권한·서버 호환성·문서 모드·실행 결과를 연결하는 사용자 흐름.

### Modified Capabilities

없음. 현재 `openspec/specs`에는 동기화된 정본이 없다. 기존 change의 홈/블록/터미널 동작은 유지하며 이번 명세는 통합 사용자 경로와 적응형 인수를 추가한다.

## Impact

- 앱 담당: `apps/app/lib/app/workbench`, 관련 feature View/VM/Repository, 앱 테스트·문서·본 change. MVVM/Provider와 composition root 소유권 유지.
- counterpart: `qa-product-planning-backend-context` 담당이 서버, HTTP 계약, TS/Dart SDK를 단독 소유한다. SDK 검증 후 앱이 소비하며 앱 담당은 서버/계약/생성 코드를 수정하지 않는다.
- dependsOn: `qa-integrated-product-planning`, `qa-desktop-project-received-home`, `qa-desktop-xml-block-studio`, `qa-desktop-interactive-terminal`, `qa-desktop-ai-workspace`의 기존 구현. 부분 인수인 터미널 change 전체를 소급 완료하지 않는다.
- 실행 계약: Desktop runtime `0.1.0-alpha.8`, contract `0.3.0-draft.2`; 기본 서버/Agent runtime `0.1.0-alpha.6`, contract `0.3.0-draft.1` 유지. Engine 제품·패키지·DSL 변경 없음.
- 모바일/TV/recorder, 개인 배정함, 사용자 관리 CRUD, Desktop 전체 Suite 일괄 실행, 실제 Slack/실기기 인수는 이번 범위가 아니다.
