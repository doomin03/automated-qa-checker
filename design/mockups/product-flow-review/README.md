# QA Studio 제품 흐름 목업

[목업 열기](index.html) · [화면 기획과 요구사항 대응](UX.md) · [검증 결과](verification.json)

현재 요구사항을 **사용자 웹 → Desktop → 결과 확인** 흐름으로 검토하는 로컬 HTML입니다. `index.html`을 Chrome/Edge에서 직접 여세요. 별도 설치나 서버가 필요 없습니다. 모든 데이터·AI·실행·저장 동작은 예시이며, 실제 Flutter/서버/Engine/AI 연결을 구현하거나 실행한 결과가 아닙니다.

## 살펴보는 순서

1. **사용자 웹**에서 로컬 로그인 QA를 열고 게시 버전을 확인합니다. 검색·분류와 다른 시나리오 상세도 검토할 수 있습니다.
2. **Desktop에서 이어서 작성**을 누릅니다. 전달만으로 실행되지 않습니다. 이미 수정한 초안이 있으면 현재 초안을 유지하거나 공용 예시를 새로 받는 선택을 합니다.
3. **Desktop**의 프로젝트 → QA 목록 → 작업 공간을 봅니다. Blueprint 블록을 선택하거나 XML 원문을 수정하고 반영합니다.
4. **CLI 설정 → 진단 시연** 후 전체/선택/앞/뒤 범위의 고정 AI 후보를 검토합니다. 후보 XML 확인, 적용·취소·되돌리기를 시연할 수 있습니다. 문서/선택이 바뀐 후보는 적용하지 않습니다.
5. **검증 → 테스트 실행**을 누릅니다. 기본 결과는 환영 문구 불일치 FAIL이며 후속 단계는 미실행입니다. **실행 설정**에서 PASS/환경 오류를 선택하거나 실행 중 취소합니다.
6. **웹에서 진행 보기**로 단계 판정과 업무 검토 상태를 확인합니다. 웹 상세의 **실행 요청 검토**는 배정 대기 상태만 생성하며 실행하지 않습니다.
7. 상단 **기획 보기**에서 화면 목적·입력·행동·결과·예외와 원본 요구사항 매핑을 검토합니다.

1440×900은 전체 Desktop 7단계와 속성/AI/결과를 함께 보여줍니다. 1024×768에서는 탐색 패널이 기본 접히며 **탐색**, **속성·AI** 버튼으로 공간을 전환합니다. 패널별 스크롤을 사용합니다.

## 대표 화면

| 화면 | 캡처 |
| --- | --- |
| 공용 시나리오 | [01-web-library](screenshots/01-web-library.png) |
| 시나리오 상세/버전 전달 | [02-web-scenario](screenshots/02-web-scenario.png) |
| Desktop 프로젝트/QA | [04-desktop-projects](screenshots/04-desktop-projects.png) · [05-desktop-qa-list](screenshots/05-desktop-qa-list.png) |
| Desktop 작업 공간 | [06-desktop-workspace](screenshots/06-desktop-workspace.png) |
| 로컬 CLI / AI 후보 | [07-cli-settings](screenshots/07-cli-settings.png) · [08-ai-review](screenshots/08-ai-review.png) |
| 검증 오류 / FAIL | [09-validation-error](screenshots/09-validation-error.png) · [12-failed](screenshots/12-failed.png) |
| 환경 오류 / 결과 웹 | [14-environment-error](screenshots/14-environment-error.png) · [15-web-result](screenshots/15-web-result.png) |
| 화면 기획 | [16-planning](screenshots/16-planning.png) |
| 1024 작업 공간 | [17-compact-workspace](screenshots/17-compact-workspace.png) |
| 수정 초안 재전달 | [20-receive-again](screenshots/20-receive-again.png) |

위 `screenshots/`만 최종 검토 캡처입니다. 폴더 루트의 `first-web.png`, `first-desktop.png`, `first-plan.png`는 초기 방향 검토용 중간본이며 최신 화면을 대표하지 않습니다.

## 검증 재현

Checker 루트의 기존 설치 환경에서 실행합니다. 새 의존성을 추가하지 않습니다.

```powershell
node design/mockups/product-flow-review/verify.mjs
corepack pnpm exec openspec validate qa-product-journey-mockup --strict --no-interactive
```

브라우저 핵심 여정/오류/상태 경계, 두 해상도의 패널 겹침·가로 overflow, 가시 한글 인코딩을 검사하고 캡처를 만듭니다. 공개 Engine alpha.6 CLI는 초기 XML과 네 AI 후보에 `validate`/`plan`만 호출합니다. Engine `run`, 실제 AI, 네트워크 API 호출은 없습니다. 과거 `desktop/**` 파일은 [원본 해시](preserved-files.json)로 변경하지 않았음을 대조합니다.

최종 결과: **21개 검사 PASS, 20개 캡처, 공개 CLI validate/plan 10회 PASS, 외부 요청 0, 페이지 오류 0**. OpenSpec strict와 `git diff --check`, JS 구문 검사도 통과했습니다. `git diff --check`의 기존 `apps/app/pubspec.yaml` CRLF 안내는 새 목업 오류가 아닙니다.

초회 자동 검증은 마지막 화면 이동에서 검증 스크립트의 selector가 잘못되어 중단됐고 수정 후 통과했습니다. 관리 시각 검토에서 발견한 작은 화면·재전달·증거 표시는 보완했습니다. 한 번의 Windows PowerShell 파이프 수정에서 추가 한글이 `?`로 바뀐 문제는 UTF-8 `apply_patch`로 복원하고 가시 문자열 인코딩 검사와 최종 캡처로 확인했습니다.

## 범위와 제한

- 브라우저 메모리만 사용합니다. 새로고침/초기화 시 초안·결과가 초기화됩니다. `초안 저장 시연`은 영속 저장이 아닙니다.
- 버전 1.2.0/1.3.0은 선택 UX용 메타데이터 예시로 동일한 공개 로그인 XML을 사용합니다. 실제 게시 이력이라고 간주하지 않습니다.
- XML 편집 helper는 기존 목업의 검증된 부분집합을 복사·보완했습니다. 전체 Engine validator나 새 실행 schema가 아닙니다. 분기/반복/미지원 XML은 원문을 보존하고 편집 제한을 알립니다.
- AI 요청은 자연어를 해석하지 않습니다. 선택 범위의 고정 후보를 미리보기하며 로컬 CLI 진단/인증도 시연입니다. API 키 입력·보관은 없습니다.
- 증거 화면은 별도 예시 UI입니다. 실제 브라우저 캡처로 오인하지 않도록 표시하며 환경 오류/취소/진행 중에는 성공 증거 썸네일을 표시하지 않습니다.
- 신규 프로젝트 입력과 나머지 QA는 해당 화면을 검토하는 범위이며 실제 프로젝트 저장/CRUD 기능은 구현하지 않았습니다. 전체 편집 여정은 로그인 QA에서 제공합니다.
- 서버 예약·역할 권한·실기기·Slack·실제 제품 스타일 적용은 후속 기획입니다. alpha.6 서버/alpha.8 Desktop 계획 간 호환성도 실제 연결 완료로 표시하지 않습니다.
