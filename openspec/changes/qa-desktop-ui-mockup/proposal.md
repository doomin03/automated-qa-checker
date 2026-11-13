## Why

기능 구현된 Desktop의 작성·검증·명시 실행·결과·공유 흐름을 사용자 관점에서 검토할 독립 목업이 필요하다. 사용자는 이번에 디자인 검토 파일 제작을 요청했고 제품 Flutter 이식은 요청하지 않았다.

## What Changes

- 밝은 neutral 배경과 파란 포인트 한 색의 HTML/CSS/JS 데스크톱 목업을 제공한다.
- 시나리오 목록, Flow/XML 편집, 검증, 실행 확인, 단계별 진행·결과, 공유 초안의 상호작용을 mock data로 연결한다.
- PASS/FAIL/환경 오류/미실행을 텍스트로 구분하고 QA outcome과 업무·공유 상태를 분리한다.
- 실제 브라우저 캡처, 상호작용 인수 기록 및 짧은 한국어 UX 설계를 같은 폴더에 남긴다.

## Capabilities

### New Capabilities
- `qa-desktop-review-mockup`: 실행하지 않는 검토용 Desktop UX 목업과 상태 인수.

### Modified Capabilities
없음. 제품 실행 및 HTTP 계약을 변경하지 않는다.

## Impact

소유 경로는 `design/mockups/desktop/**`와 이 OpenSpec change뿐이다. dependencies 없음. counterpart는 Checker Desktop 기능이며 contractVersion은 변경 없음(Engine alpha.6 표현 참고). dependsOn: qa-flow-editor, qa-user-web-desktop-handoff, qa-shared-suites. 외부 게시·Figma·이미지 생성·새 라이브러리·Flutter 스타일 이식·commit/push는 범위 밖이다.
