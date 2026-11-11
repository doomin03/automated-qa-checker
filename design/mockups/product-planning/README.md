# 전체 제품 기획·화면설계 검토

[index.html](index.html)을 브라우저에서 열면 된다. 서버나 로그인 없이 관계도 → 사용자 여정 → 화면설계 → 조작 목업 → 결정과 근거를 오간다. 기존 [XML 작업실](../xml-block-studio/index.html) 상단에서도 들어올 수 있다.

## 검토 방법

- 관계도에서 노드를 선택하면 소유·전달물·계약·제한을 읽는다. 로컬 alpha.8과 서버/Agent alpha.6 경로, 독립 package/CLI 경로를 구분한다.
- 화면설계의 검색 또는 ID로 D01–D08(Desktop), W01–W08(사용자 웹), A01–A08(관리 업무), E01(Engine 계약)을 선택한다. 상태 버튼은 해당 목업을 열고 화면설계 링크로 돌아온다.
- 웹 목업의 역할은 액션별 권한을 바꾼다. QA/Suite 새 초안 저장 → 다른 사용자 검수 → 게시 → 같은 버전 조회, 요청 → queued, 예약 → 선택한 발생 이력, 업무 done → 원본 failed 유지가 연결된다. 모든 데이터는 예시이며 실제 게시나 실행을 하지 않는다.
- Desktop은 기존 조작 목업을 재사용한다. 통합 검토에서는 별도 sessionStorage namespace를 사용하여 기존 studio/home localStorage의 사용자 예시 작업을 읽거나 덮지 않는다. D07 결과와 D08 터미널은 명시적인 상태 검토이며 Engine/PTY 호출이 아니다.
- 결정과 근거에는 담당들의 반례/수정/합의, 6개 상태 축, 원본 MD 8개→현재 기능·화면·근거·미완료/후속 인수 대응표가 있다. 현재 구현/실제 검증/화면 구조 제안/미완료를 구분한다.

## 근거와 한계

새 웹 IA는 설계 제안이다. 현재 실제 앱 route `/qa/blueprints`, `/qa/shared` 및 코드·API 근거를 화면별로 명시했다. 개인 QA 배정 inbox, 전체 Suite Desktop 실행, 사용자/팀/역할 CRUD, 전체 Agent 재고 UI, 실제 Slack 알림, 모바일 실기기/TV·일반 whitebox·recorder·범용 코드 export의 미완료를 지우지 않았다. 원본 TC 전체 설명 메타데이터 폼도 부분 범위로 남긴다.

목업의 여러 QA 예시는 동일 공개 XML fixture를 화면 구성용으로 공유한다. 원문 내용이 다른 실제 제품 데이터나 새 실행 증거가 아니다. XML 다운로드는 공개 fixture 원문이며 자동 실행하지 않는다. 게시/요청/예약 상태는 현재 페이지 메모리 안의 검토 데이터이고 브라우저 새로고침 시 기본 예시로 돌아온다. Desktop 편집 예시만 별도 검토 session에 저장한다.

현재 실제 Windows 앱은 [프로젝트 홈 안내](../../../docs/project-home.md), 실제 인수는 [홈](../../../docs/validation-project-home.md)과 [XML 작업실](../../../docs/validation-xml-block-studio.md)을 따른다. 이번 기획 작업으로 제품 코드·Engine pin·Release는 변경하지 않았다.

## 검증

- `node design/mockups/product-planning/verify.mjs`: [94항목 PASS](verification.json). 25화면 설계/목업 연결, 역할·공유 버전·Suite 순서·요청/예약·상태·원본 요구·1440/1024 넘침과 한글을 확인했다. 새 API/Engine 실행 검사가 아니다.
- 기존 `verify-home.mjs` 14검사와 `verify.mjs` 16검사 PASS. [홈 회귀](../xml-block-studio/verification-home.json), [편집기 회귀](../xml-block-studio/verification-editor.json).
- 웹 담당이 24개 실제 Chromium 상호작용을 독립 검토했다. [최종 교차검토 기록](evidence/web-cross-review.md), 관리 workspace의 `product-planning-20261111/web-prototype-review-accepted/verification.json`에 근거가 있다.
- 관리자가 25개 화면/71개 근거 링크, Desktop 원본 저장소 byte 불변 및 sessionStorage 분리, 두 크기의 대표 화면을 독립 확인했다. 복구 후 최종 14캡처에서 pageerror·가로 넘침 0, Release/기존 파일 보존, strict/diff를 재확인해 관리 인수했다. 최종 검토 기록은 `coordination/product-planning-20261111`에 있다.
- `capture.mjs`의 [최종 캡처](screenshots)는 1440×900과 1024×768의 관계도·화면설계·웹·관리·Desktop을 기록한다. 초기 확인 후 추가된 UI는 최종 캡처로 갱신한다.
- 저장소 verify의 초기 실행은 작성 중 README 링크 부재에서 중지했다. 링크를 완료한 뒤 **최종 verify exit 0**: [최종 로그](../../../artifacts/product-planning/repository-verify-final.log). foundation·lint/boundary·types/packages·전체 strict OpenSpec·build·실제 browser UI/routes를 통과했다.

최종 CSS 줄바꿈 보완 과정에서 stylesheet를 잘못 교체한 중간 실패를 발견해 원래 규칙 전체를 복원했다. 최종 8,648 bytes CSS로 94검사와 18캡처를 재생성했고 1024 관계도 scrollWidth=1024 및 실제 시각을 다시 확인했다. 이 중간 실패를 최종 인수로 사용하지 않는다.

권한/작성자/중복 게시/예약 행 identity/Suite 버전 전달 및 공유 호환성의 독립 반례는 수정 후 다시 확인했다. 외부 계정, 원격 게시, 제품 실행 인수 확대는 하지 않았다.

## 파일

`data.js`는 담당 조사 JSON의 로컬 포함본, `app.js`는 기획 탐색/화면 registry, `prototypes.js`는 웹 예시 조작, `requirements.js`는 원본 대응표다. `evidence`에는 조사·합의의 snapshot 사본이 있으며 Engine의 실행 소스를 복제한 것이 아니다. 기존 제품 문서도 [roadmap](../../../docs/planning/roadmap.md), [시스템 설계](../../../docs/architecture/system-design.md), [조직 업무](../../../docs/architecture/organization-auth-workflow.md), [공용 QA](../../../docs/architecture/shared-scenarios.md)에 현재/역사/미완료로 정합했다.
