# XML 파일 블록 작업실 목업

[전체 기획·화면설계](../product-planning/index.html)는 Engine·사용자 웹·관리 업무와 이 Desktop을 연결하는 새 검토 진입점이다. 같은 작업실을 격리된 검토 세션으로 열어 기존 브라우저 저장 문서를 덮지 않는다.

[index.html](index.html)을 브라우저에서 연다. 기본 시작은 프로젝트 홈이며 `내 프로젝트 / 서버에서 받기 / 가져온 QA`에서 문서를 선택한 뒤 XML 작업실로 들어간다. 이전 product-flow-review 및 이 폴더의 이전 검증·캡처는 보존한다. 실제 앱의 전체 흐름은 [프로젝트·받은 QA 안내](../../../docs/project-home.md)를 따른다.

## 화면과 조작

- **2026-11-13 하단 클릭 영역 리팩터링:** 패널 탭과 세션 도구를 분리하고 선택 탭·세션 테두리, 세션 수, 새 세션 강조 버튼과 공급자 카드를 적용했다. 접힌 도크는 44px이며 버튼은 최소 32px이다. 패널/세션 탭에서 좌우 방향키·Home/End로 이동한다. [1440 화면](screenshots/dock-design/dock-1440.png) · [800 화면](screenshots/dock-design/dock-800.png) · [도구 선택](screenshots/dock-design/providers-800.png). 목업 확인은 `index.html?planning=1&screen=D08`로 열면 된다.

- **VS Code 스타일 후속 반영:** 사용자 피드백에 따라 하단은 #1e1e1e 배경, 파란 선택 밑줄과 평평한 세션 탭으로 변경했다. 우측 도구는 추가·분할·확대·접기 아이콘으로 표시하며 툴팁과 접근성 이름을 제공한다. 공급자 선택도 둥근 카드 대신 간결한 메뉴 행으로 바꿨다. HTML은 입력 기록만 남기는 목업이며, 실제 Flutter 앱은 `TerminalService`의 `Pty.spawn`과 `TerminalView`로 네이티브 터미널 프로세스에 연결한다. 이번에 앱 프로세스 실행을 새로 인수한 것은 아니다.

- **실제 앱 적용:** 후속 사용자 요청으로 `TerminalDock`에도 배경·선택선·세션 탭·아이콘 도구를 적용했다. 실제 앱은 기존 준비 진단과 PTY를 사용하며 접기와 종료를 구분한다. [앱 검증과 환경 제한](../../../docs/validation-terminal-dock-design.md)을 따른다.

- **2026-11-12 다중 터미널 목업:** 작업실 아래 `터미널` 탭에서 시작한다. [D08 바로 열기](../product-planning/index.html#prototype/D08), [화면 기획과 현재 지원](../../../docs/planning/multi-terminal-workbench.md). Claude/Codex/PowerShell/명령 프롬프트의 세션 추가·이름·전환·분할·접기·확대·종료 상태를 조작한다. 실제 프로세스는 실행하지 않는다.
- 세션 메뉴의 `자동 반영 작성자로 지정`과 `작성 흐름 예시`에서 후보 준비 → 검증 결과 전달을 검토한다. 한 QA에 작성자는 하나이며 충돌/권한 양도/계약 변경/실행 중이면 draft를 보존한다. 세션은 페이지를 새로고침하기 전까지만 유지하며 기존 프로세스 복구를 주장하지 않는다.

- 프로젝트/QA 생성·검색·선택 상세, 서버 연결 예시·게시 목록·Suite case 선택·대상 프로젝트로 새 QA 수신을 제공한다. 같은 버전의 기존 사본 열기와 새 사본 받기를 구분한다.
- 홈 복귀 때 저장/버리기/취소를 제공한다. 사본과 원본 버전·직접 XML 편집은 브라우저 localStorage에 저장하고 새로고침 뒤 홈에서 다시 연다. 실제 서버 요청과 로그인은 수행하지 않는다.

- 중립 회색 메뉴·문서 툴바·탭, XML 라이브러리, 캔버스, 속성/구조/이력, 출력과 문서 상태를 제공한다.
- 파일 클릭/드래그로 블록 배치, 제목 드래그로 이동, 출력 핀→입력 핀으로 연결한다. 빈 공간 이동, 확대/축소, 전체 보기, 삭제/되돌리기도 동작한다.
- 작은 화면에서는 라이브러리 버튼으로 전체 파일 목록을 연다.
- 블록 내부 XML은 읽기 전용이다. 직접 XML은 명시적으로 전환하여 별도 내용을 편집한다. 탭 이동 및 브라우저 저장/새로고침에서도 편집 상태를 보존한다.
- 저장은 이 브라우저의 리뷰 상태에 한정된다. 실행은 비활성 상태이며 이유를 표시한다.

## 경계와 기획

HTML은 디자인·로컬 조작 검토용이다. Engine 컴파일/검증/실행, 실제 프로젝트 파일, PTY는 Windows 앱 구현과 구분한다. 연결 점검은 단순 외부 그래프 점검이며 Engine 검증 통과를 뜻하지 않는다. 기본 세 파일은 공개 alpha.6 XML fixture의 동일 원문을 화면 구성용으로 공유한다. 실제 앱 인수 fixture는 각 원문의 id/name을 구분하고 alpha.8 공개 CLI로 검증한다.

화면 내 `화면 기획 / 구현 범위`에서 목적·입력·행동·결과·예외를 읽을 수 있다. 실제 조합은 단일 start/end, 동일 target, 순차 외부 연결을 지원한다. 내부 branch는 보존한다. references/testCase/authoring 반복 등 조합 미지원 문서는 직접 XML 경로를 사용한다. 전체 조합은 한 실행 세션이다.

## 검증

`node design/mockups/xml-block-studio/verify-dock-design.mjs`는 기존 터미널 43·홈 14·편집기 16·portal 94검사를 별도 출력 경로에서 재실행하고, 키보드/접힘/입력 보존/메뉴/1440·1024·800px 배치 25검사를 추가 확인한다. 총 192개 PASS. [디자인 결과](verification-dock-design.json) · [회귀 결과](verification-dock-design-regressions.json). 이번 캡처는 `screenshots/dock-design`에 보존한다. OpenSpec strict와 `git diff --check`도 통과했다.

이번 PC의 저장소 전체 `pnpm run verify`는 foundation 단계에서 기존 문서 `docs/validation-multi-terminal-planning.md`가 참조하는 Git 제외 과거 로그 `artifacts/multi-terminal-planning/repository-verify-initial.log` 누락으로 중단됐다. 과거 증거 파일을 생성해 통과 처리하지 않았으며 전체 verify 성공으로 보고하지 않는다. Node 24.18.0/pnpm 10.34.8은 명령 단위로 사용했다. Flutter 적용·실제 PTY 실행·Release 빌드는 이번 목업 인수에 포함하지 않는다.

새 도크 검증은 `node design/mockups/xml-block-studio/verify-terminal.mjs`의 [전용 결과](verification-terminal.json)와 [최종 도크/XML 캡처](screenshots/multi-terminal)에 있다. 기존 홈·편집기·portal 회귀는 `node design/mockups/xml-block-studio/verify-terminal-regressions.mjs`로 실행해 이전 결과를 덮지 않고 새 경로에 기록한다. 실제 CLI/Engine/OS IME 실행 검사가 아니다.

현재 결과와 교차검토는 [다중 터미널 검증 기록](../../../docs/validation-multi-terminal-planning.md)을 따른다. `terminal-first-1440.png`는 구현 중간본이며 최종 검토에는 `screenshots/multi-terminal`의 화면을 사용한다.

`node design/mockups/xml-block-studio/verify-home.mjs`는 [홈 14검사](verification-home.json), `node design/mockups/xml-block-studio/verify.mjs`는 [편집기 16검사](verification-editor.json)를 기록한다. 새 캡처는 [홈](screenshots/home)과 [편집기 회귀](screenshots/editor-regression)에 있다. 루트 verification.json과 screenshots 바로 아래 PNG는 홈 복구 이전 이력이다. 이 검사는 제품 실행 인수를 대체하지 않는다.
