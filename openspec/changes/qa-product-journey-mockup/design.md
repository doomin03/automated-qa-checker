# Design

## Context

Checker main/4f97e920a399d4a5434ab1ecbe44c4d879d397a4와 기존 dirty tree를 기준으로 조사했다. 기존 `design/mockups/desktop/blueprint-workspace`는 프로젝트→QA→도킹 편집과 API 키 시연 폼을 제공한다. 최신 `qa-desktop-ai-workspace`는 로컬 CLI 인증·키 미저장·후보 검증·명시 적용 방식을 정의하며 tasks는 아직 미완료다. 이번 자료는 이를 제품 구현 완료로 해석하지 않는다. 원본 8개 MD와 최신 사용자 역할 정의, `system-design.md`, 원본 모노레포 이관 `integration.md`를 근거로 한다.

## Goals / Non-Goals

Goals: 사용자가 기획과 시각적 디자인을 함께 검토하고 웹→Desktop→결과 흐름을 클릭해 확인한다. 상태 의미와 실제 제품 인수 경계를 유지한다.

Non-Goals: 실제 API/AI/Engine 호출, 장치 연결, 자동 실행, 자격증명 입력, 영속 저장, 원격 게시, 기존 제품/목업의 덮어쓰기.

## Decisions

### D1. 독립 로컬 산출물

`design/mockups/product-flow-review/index.html`, CSS, JS, 기획 문서, 스크린샷, 검증 자료를 별도로 둔다. 외부 라이브러리/폰트/네트워크 요청 없이 file URL 및 localhost로 열린다. 기존 목업 파일 hash 목록을 변경 전 기록하고 마지막에 보존 여부를 확인한다. 사용자 입력은 textContent 또는 escaping으로 표시한다.

### D2. 정보 구조와 디자인

상단 검토 탭은 사용자 웹 / Desktop / 기획 보기다. 사용자 웹은 공용 시나리오 목록과 상세·버전·진행을, Desktop은 프로젝트→QA→도킹 Flow/XML·선택 속성·AI 검토·하단 결과를 사용한다. 차콜 배경, 단색 파랑 강조, 얇은 경계선, 명확한 한글 타이포, 최소 아이콘을 유지한다. 1440×900은 전체 작업 공간, 1024×768은 패널 접기 및 패널별 스크롤을 제공한다. 장식용 hero나 그라데이션을 넣지 않는다.

### D3. 공유되는 예시 업무 상태

웹의 게시 버전 선택과 Desktop 전달은 예시 문서/출처를 선택하며 runCount를 증가시키지 않는다. Desktop 원문 수정/AI 적용·undo는 검증을 무효화한다. 선택 변경은 AI 후보만 stale로 만들고 문서 검증은 유지한다. 검증 후 별도의 실행 버튼을 눌러야 시뮬레이션이 시작된다. 검증 오류는 실행 전 상태이며 run 결과를 만들지 않는다. 실행 snapshot과 현재 문서를 구분하고 실행 중에는 편집을 잠근다. 결과는 PASS/FAIL/환경 오류/취소/미실행을 구분한다. 취소 요청 상태와 terminal cancelled를 구분하며 후속 미실행을 성공으로 취급하지 않는다. 웹의 실행 요청은 요청 접수 상태이며 실제 실행 성공과 구별한다. 서버 예약·권한은 기획 범위로 안내한다.

### D4. AI와 계약 경계

AI 패널은 Codex CLI 진단/인증 상태 예시와 전체/선택/앞/뒤 범위, 요청→후보 비교→명시 적용/취소→undo를 제공한다. 실제 키 입력 폼은 만들지 않는다. 자유 요청은 고정 예시 후보임을 알리고 자동 실행하지 않는다. 후보의 문서/선택 revision이 바뀌면 적용을 거부한다. 목업 XML/그래프는 UI 설명 모델이며 실행 schema를 새로 정의하거나 전체 Engine validator라고 표시하지 않는다. 서버 alpha.6과 Desktop 계획 alpha.8 간 호환성은 기획상 재검증 경계로 표시한다.

### D5. 검증과 인수

기존 설치 Playwright로 핵심 클릭 여정·상태 경계·stale/undo/cancel·두 해상도 geometry·페이지 오류·외부 요청을 검사한다. 대표 웹/프로젝트/편집/AI/결과/기획 화면을 캡처해 관리자가 시각 검토한다. OpenSpec strict와 git diff check를 수행한다. 성공은 목업 인수이며 실제 제품 실행 인수가 아니다.

## Risks / Trade-offs

UI가 연결된 듯 보여 실제 제품으로 오인될 수 있으므로 항상 목업·예시 데이터를 표시한다. 기존 목업과 로컬 AI 방식 차이는 기획 근거표에서 설명한다. 모바일은 제품 대상이 아니며 이번 최소 인수 해상도는 1024×768이다.
