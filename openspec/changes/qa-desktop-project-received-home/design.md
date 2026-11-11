# Design

## 1. 확인한 현재 상태와 요구사항 근거

- Checker `main`, HEAD `4f97e920a399d4a5434ab1ecbe44c4d879d397a4`. 이전 XML studio/terminal 등 작업의 미커밋 파일을 보존한다.
- 원본 `CHECKER_CODEX_PROMPT.md:11-12,26,61`, `PHASES_AND_ACCEPTANCE.md:35-38`: 회사 프로젝트, 게시 TC/Suite 검색·다운로드·고정, 로컬 수정과 upstream 비교. 원본의 관리자 앱 용어는 최신 사용자 웹 역할을 축소하는 근거가 아니다.
- `DesktopWorkspaceView._listing`은 로컬 프로젝트/QA만 표시한다. `SharedPanel`은 RunPanel의 고급 기능에 있고 `WorkbenchViewModel.receive`는 현재 editor만 수정한다. `Workspace` v1은 strict key 검사로 출처 필드를 임의 추가할 수 없다.
- 기존 PlatformClient는 `/me`의 프로젝트 membership, 게시 versions/details/pin, Suite details/pin, cursor pagination을 제공한다. 업무 assignee는 run 단위이며 게시 TC/Suite를 사용자에게 배정하는 inbox 계약은 없다.
- `SharedRepository.accept`는 XML SHA 확인, 원격 immutable version 재확인, pin, 캐시를 수행한다. 조직 로그인은 기존 PKCE; 개발 로컬 토큰은 메모리에만 보관한다.
- `qa-workbench-design`의 2026-11-11 보완과 공식 `frontend-design`을 적용한다. 편집기 중심 지침을 홈 제거로 해석하지 않는다.

## 2. 화면·토큰 계획과 검토

색상은 기존 studio의 canvas `#1c1c1c`, chrome `#292929`, panel `#323232`, control `#414141`, text `#e0e0e0`, selection `#8ea8bd`를 유지한다. Segoe UI/Malgun Gothic, 본문 13px·패널 제목 14px·도구 12–13px. 좌측 정렬과 1px 구분선, 4px 간격 단위로 목록과 선택 내용을 묶는다.

```text
파일   보기   도움말                         서버 연결 상태
홈  | 로컬 프로젝트 | 받은 QA
탐색              | 검색 / 프로젝트·출처 필터     | 선택 상세
로컬 프로젝트     | 프로젝트 또는 QA 행 목록      | 이름 / 버전 / 출처
서버에서 받기     | 상태 / 수정 시각 / 버전        | 받을 로컬 프로젝트
가져온 사본       | 더 보기                        | 열기 / 새 사본 받기
현재 선택 / 저장 상태 / 연결 상태
```

홈에서는 선택한 목록과 다음 행동이 중심이며 큰 KPI/hero/카드는 없다. 1024 폭에서는 선택 상세를 하단/좁은 패널로 바꿔 목록과 주요 버튼을 유지한다. 편집기는 기존 studio를 유지하고 항상 `홈` 및 프로젝트 breadcrumb로 돌아갈 수 있다. 기획 검토 결과: 편집기를 숨기지 않으면서 프로젝트와 수신이 문서보다 먼저 발견된다. 서버 버전 ID/hash/절대 경로는 상세 접기 안으로 둔다.

## 3. 상태 소유와 연결

- 새 Home ViewModel은 Workspace/Shared/Organization의 상태를 조합하고 목록 검색·선택·연결 프로젝트·수신 결과를 소유한다. View는 표시와 사용자 입력만 담당한다.
- 연결 프로젝트 발견은 기존 PlatformClient.me를 Repository에서 호출한다. 목록에는 API가 허용한 membership 프로젝트만 보인다. SharedRepository의 단일 연결을 재사용하고 별도 비공식 HTTP 경로/인증을 만들지 않는다.
- 서버 QA 탭은 `받을 수 있는 QA`(게시 versions/Suites)와 `가져온 사본`(로컬 QA에 연결된 출처)를 구분한다. Suite는 고정 후 개별 case를 받는다. 전체 Suite 자동 생성·순차 실행이나 개인 배정 inbox는 이번 범위 밖이며 지원하지 않는 동작은 명시한다.
- 검색은 현재 받아온 페이지의 이름/package/version에 적용하고 범위를 표시한다. 더 보기로 기존 cursor를 소비한다. API에 없는 전역 검색 기능을 주장하지 않는다.
- 연결 없음은 서버 연결/로그인 행동을, 빈 목록은 프로젝트 전환/새로 고침을, 오류는 재시도를 제시한다. 로컬 프로젝트/가져온 사본은 서버 없이 열린다.

## 4. 수신과 영속성

- 수신 전 사용자가 대상 로컬 프로젝트와 QA 이름을 선택한다. 기존 프로젝트 또는 명시적인 새 프로젝트 생성 경로를 제공한다. 가져오기는 항상 새 QA이며 기존 QA 열기는 별도 행동이다.
- 같은 origin/serverProject/versionId를 이미 받은 경우 `기존 사본 열기`와 `새 사본 받기`를 구분한다. 최신 버전이라고 자동 교체하지 않는다. 새 버전도 새 QA로 받고 기존 사본/수정은 보존한다.
- `workspace.json` v1 strict 형식은 변경하지 않는다. 별도 received-QA sidecar는 localProjectId/qaId에 origin, serverProjectId, packageId, versionId, version, XML sha256, blueprintSnapshotHash, 수신 시각, 선택 Suite의 ID/version/hash/case를 연결한다. 자격증명은 저장하지 않는다.
- Receipt와 원본 XML은 bounded 검증 후 새 QA ID에 대한 immutable sidecar로 먼저 기록하고 workspace를 기존 lock/revision/atomic rename으로 commit한다. sidecar 실패이면 QA를 만들지 않는다. workspace commit 실패 시 고아 sidecar는 목록에 노출하지 않으며 이전 workspace는 보존한다. 두 파일 transaction을 보장한다고 주장하지 않는다. 목록은 실제 존재하는 QA와 결합한 출처만 보여준다.
- 로컬 QA 수정은 원본 snapshot을 변경하지 않는다. 원본 XML SHA와 현재 문서 SHA 차이로 `원본과 같음/로컬 수정됨`을 표시한다. 손상 sidecar는 오류로 보존하고 원래 로컬 QA는 계속 열 수 있다.
- 원본 XML은 직접 XML 문서로 열고 검증은 명시 행동이다. 파일 블록으로 사용하는 것은 작업실의 기존 명시 가져오기 경로다. 조합 미지원 원문을 수신 단계에서 버리지 않는다.

## 5. 경합·이동·실행 경계

- 연결/서버 프로젝트/버전 선택/로컬 목적지/현재 문서 identity를 수신 시작에 capture한다. await 이후 동일한지 확인하고 다른 연결 또는 문서의 늦은 결과는 적용하지 않는다. disconnect/logout/프로젝트 변경은 ticket을 무효화한다.
- 수신 중 목적지와 선택 변경은 차단하거나 명시 취소로 ticket을 무효화한다. Home에서 시작한 수신은 기존 editor에 `_apply`하지 않는다.
- editor→홈/다른 QA 이동은 기존 문서와 블록 sidecar dirty를 모두 검사하고 저장/버리기/취소를 제공한다. run/compile/save 중에는 문서 변경을 차단한다. 저장 실패는 이동 성공으로 처리하지 않는다.
- 공개 Engine 검증은 alpha.8 실제 runtime을 유지한다. 서버 alpha.6와 snapshot이 같아 원본 versionId를 연계할 수 있어도 게시 호환을 의미하지 않는다. 기본 alpha.6 서버는 alpha.8 실행 게시를 거절하므로 자동 게시를 켜지 않고 결과 공유 가능으로 표시하지 않는다. 편집/조합 snapshot이 바뀌면 원본 versionId를 실행 version으로 붙이지 않는다.
- 프로젝트 홈페이지와 서버 수신에 필요한 shared 경로만 정리하며 다른 세션 소유 terminal/primitive editor/layout 코드는 수정하지 않는다.

## 6. 검증·산출물

- Repository/VM: 기존 v1 roundtrip, sidecar 손상/저장 실패, 동일 버전 재수신 정책, 다른 로컬 프로젝트/늦은 연결 응답, pagination/search, viewer pin 거부, XML hash 불일치.
- Flutter: 홈 기본 진입·프로젝트 생성/목록/QA 열기·미저장 복귀 보호·수신 UI와 busy 보호·원본/로컬 수정 상태.
- 실제 Windows: 격리 APPDATA와 실제 로컬 Nest/SQLite alpha.6 서버에서 author 작성→별도 reviewer 검수→발행된 TC/Suite를 tester가 조회/고정→로컬 QA 수신→alpha.8 validation/run PASS와 PNG→재Provider/재실행 출처·문서 복원. 서버 DTO fixture만으로 수신 인수를 대체하지 않는다. 운영 원격 서비스/실계정 인수는 별도다.
- 1440×900/1024×768 홈·선택 상세·수신·편집 복귀 스크린샷, 새 목업 동작·저장 상태 검증. 이전 목업 스크린샷/로그는 이력으로 보존한다.
- 새 Release `artifacts/releases/desktop-project-home-alpha8`에 manifest/source manifest/configuration/native launch를 기록한다. 기존 studio Release와 Engine 설치/pin은 변경하지 않는다.
