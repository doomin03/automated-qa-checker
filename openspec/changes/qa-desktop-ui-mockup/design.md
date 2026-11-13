## Context

Desktop은 사용자가 테스트를 개발·검증·실행하는 앱이다. 서버 연결 없이 로컬 작업이 가능하며 공용 시나리오의 수신·pin과 결과 공유는 별도 행동이다. 이번 파일은 실제 엔진·API에 연결하지 않는다.

## Goals / Non-Goals

Goals: 같은 작업 문맥 안에서 다음 행동을 찾게 하는 정보 위계, 명시 실행 전 검증, 실패 원인과 미실행 단계의 구분, mock 상태 명시. Non-Goals: 제품 기능 추가, 실제 schema validator/DSL 발명, 자유 그래프 드래그 구현, 자동 실행, 원격 저장.

## Decisions

1. 좌측 프로젝트·시나리오 탐색, 중앙 Flow/XML 작업, 우측 선택 단계 속성, 하단 검증/실행 결과를 하나의 작업 공간으로 구성한다. 목록 화면은 최근 시나리오와 결과를 먼저 보여준다.
2. 하나의 파란 포인트만 사용한다. 성공/실패를 추가 색으로 분류하지 않고 PASS·FAIL·환경 오류·미실행 배지와 이유를 함께 표기한다. 장식 아이콘과 그라데이션은 사용하지 않는다.
3. XML 변경은 검증을 무효화한다. 목업 검증은 XML 문법/blueprint 루트 확인만 수행하며 공개 Engine validation을 대체하지 않음을 노출한다. 검증 버튼은 실행하지 않는다. 검증된 현재 초안과 대상을 화면에 표시하고 테스트 실행 클릭 한 번으로 진행을 시작한다. 반복 확인 dialog는 두지 않으며 결과 종류 선택은 접힌 목업 설정으로 분리한다.
4. Flow는 고정 데모 단계를 선택·속성 확인할 수 있다. XML 편집은 입력·데모 복원 가능하다. 자유 블록 추가와 자동 XML→Flow 변환은 이번 목업에 포함하지 않고 UI에 한계를 표시한다.
5. 결과 시뮬레이션은 PASS, ASSERTION_FAILED에 따른 FAIL, 환경 준비 오류, 사용자 취소/미실행을 보여준다. 이전 실행은 immutable snapshot 문맥으로 표시하며 편집으로 결과를 바꾸지 않는다. 공유는 초안 제출 데모이며 검수·게시나 네트워크 연결 성공으로 표기하지 않는다.
6. 고정된 데모 입력만 렌더링하고 사용자 XML은 textContent/textarea로 표시한다. 외부 asset/CDN 없이 file URL로 열 수 있고 keyboard focus, dialog Escape, live status를 제공한다.

## Risks / Trade-offs

목업의 화면 배치·상세 패널은 제안이며 현재 Flutter와 동일하지 않다. 1280px 이상 Desktop이 우선이며 1024px에서는 속성 패널을 아래로 배치한다. 실제 제품 엔진 인수와 이번 브라우저 상호작용 인수는 분리한다.

## Validation

기존 Playwright로 Chromium을 실행해 목록→편집, Flow/XML, 무효 XML 검증 차단, 변경 후 재검증, 명시 실행·중단, 네 결과 상태, 공유 초안 데모를 검사한다. 1440×1000 및 1024×900 레이아웃에서 overflow를 확인하고 screenshots/ 및 verification.json을 생성한다. 공개 Engine alpha.6의 qa-blueprint XML fixture 원문을 수정 없이 사용한다.
