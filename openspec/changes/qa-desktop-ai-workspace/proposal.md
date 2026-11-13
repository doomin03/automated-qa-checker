# Proposal

## Why

현재 Flutter는 XML/Flow 편집·실행·증거 확인을 제공하지만 프로젝트/QA 영속 목록, 프로젝트별 지침, 로컬 AI CLI 작성은 없다. 사용자가 다음 날 실제 앱으로 프로젝트를 열고 AI가 만든 QA를 검토·실행할 수 있도록 목업의 업무 흐름을 제품에 연결한다.

## What Changes

- 프로젝트/QA 목록과 문서·프롬프트의 로컬 영속 저장, 프로젝트 → QA → 도킹 작업 공간을 추가한다.
- 기존 Flow/XML·실행 snapshot·PNG 결과를 재사용하고 선택 노드 문맥을 AI 작성에 전달한다.
- 설치된 AI CLI의 명시 경로·진단·진행·취소를 제공한다. 기존 CLI 인증을 사용하고 앱은 API 키를 저장하지 않는다.
- 전체/선택/앞/뒤 편집 요청을 전체 후보 XML로 받아 공개 Engine 검증, 변경 미리보기, 명시 적용·되돌리기·오래된 응답 차단을 제공한다.
- 새 Desktop만 고정 alpha.8을 소비한다. 서버/Agent pin·공유 alpha.6 설치·이전 Windows Release·HTML 목업은 보존한다.
- 실제 Windows Release와 재현 가능한 로컬 테스트 안내를 만든다. AI 생성은 QA 자동 실행 권한이 아니다.

## Capabilities

### New Capabilities

- `desktop-project-workspace`: 로컬 프로젝트/QA 저장과 도킹 편집·실행 작업 공간.
- `desktop-ai-authoring`: 로컬 CLI 기반 정의 생성과 검증된 변경의 사용자 승인.

### Modified Capabilities

없음. 현재 openspec/specs 정본은 비어 있으며 이전 change의 완료 증거는 수정하지 않는다.

## Impact

apps/app의 app composition/workbench와 새 project_workspace/ai_authoring 기능, 앱 전용 runtime 설치·빌드 도구, 테스트와 실행 안내에 한정한다. HTTP/Agent/Engine 실행 DSL은 변경하지 않는다. counterpart는 Engine의 검증된 alpha.8 공개 패키지이며 새 Engine 구현 의존성은 없다. dependsOn: qa-desktop-mvvm-boundaries, qa-engine-refactor-compatibility, qa-user-web-desktop-handoff. 실행 contractVersion은 0.3.0-draft.2, 기존 서버는 alpha.6/0.3.0-draft.1이다. Claude 미설치/인증 실패는 지원되지 않는 실제 상태로 표시하며 fixture 성공을 실제 AI 성공으로 보고하지 않는다.
