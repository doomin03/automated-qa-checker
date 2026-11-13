# Engine 기획 근거와 3담당 흐름 합의

검토일: 2026-11-11. Engine 담당의 읽기 전용 기획 감사다. 제품·pin 변경, commit/push, 신규 전체 실행 검증을 하지 않았다. 이 문서는 새 구현 완료 보고가 아니다.

## 1. 기준과 실제 상태

- Engine repo: `C:/workspace/QA/automated-qa-engine`, main, HEAD `ecdb8ff87b1b45b93a38921a44d36c8adb068cd8`. 다수 기존 tracked 수정/untracked 구현이 있으며 현재 제품은 HEAD 단독이 아닌 working tree와 고정 배포 artifact로 판단한다.
- 사용자 원본 8 MD의 역할 원칙: Engine은 실행, Checker는 누가/무엇을/언제/어디서 실행하고 공유하는지 소유. 원본의 언어·명령·계약 예시는 확정 현재 구현이 아니다. Dart 우선 검토 후 실제 선택은 Node ESM이다. 원본의 관리자 앱 표기보다 최신 사용자 지시인 사용자 웹+관리 역할, Windows Desktop 편집·실행을 우선한다.
- 참고 `docs/architecture/repository-audit.md`는 2026-10-24 조사 기록이다. 당시 unborn HEAD/미설치 SDK 상태를 현재 상태로 복제하지 않는다.
- 현재 Engine alpha.8 / contract 0.3.0-draft.2, 독립 로컬 tgz preview. 원격 npm 공개·운영 배포 완료를 의미하지 않는다.
- Desktop runtime manifest는 alpha.8. 기본 서버/공통 contract/runtime pin 및 운영 Agent는 alpha.6 / draft.1. `README.md:62`, `docs/validation-alpha.8.md:55-66`, Checker `packages/contract/engine-dependency.json`, `engine-runtime.json`, `apps/app/assets/desktop-engine-runtime.json`을 구분한다.
- 문서시점 주의: `docs/xml-format.md`는 alpha.5 서두 및 과거 Appium 후속 문장을 포함하고, system-design 표 일부에는 alpha.7이 남아 있다. XML 구조 설명만 참고하고 최신 지원/버전은 실제 release·package·adapter·alpha.8 검증기록으로 판정한다. 과거 OpenSpec 시나리오 역시 당시 범위다.

## 2. 제품 관계와 용어

| 구성 | 소유 책임 | 입력 | 출력/다음 연결 |
|---|---|---|---|
| 사용자 웹 | 공용 게시 QA/Suite 탐색·전달, 실행 진행·공유 결과 확인 | 서버 권한/고정 게시 버전 | XML/버전/hash, 서버 진행·증거 |
| 관리 역할 웹 | 검토/게시, 일정·Agent 자원·운영·업무 관리 | 동일 서버의 권한 있는 작업 | 게시 버전, 실행 요청/예약, 업무 상태 |
| Desktop | 로컬 프로젝트/QA, 직접 XML 및 파일 블록 편집, 검증/명시 실행/결과 표시 | 직접 파일 또는 받은 XML | 단일 실행 XML, 로컬 Engine 요청, 로컬 결과 |
| Engine package/CLI | 정본 schema, 파싱/검증/plan, interpreter/adapter, event/result/evidence | 공개 Blueprint·TC·Suite 문서, 실행설정·외부 secret resolver | immutable plan, run 결과/증거 |
| 선택 Agent | 승인 lease 수신·Engine child·durable 보고·복구 | 서버 lease와 로컬 허용 정책의 교집합 | case별 원본 Engine event/result 및 전달 상태 |
| 서버 | 사용자/RBAC, registry, 일정/queue/lease, 결과 보관/업무 상태 | 앱/웹/Agent 요청 | 고정 게시물/업무·실행 API |

Engine에 Flutter·Slack·중앙 DB가 필수 의존성이 아니다. 다른 Node 프로젝트가 `automated-qa-engine` API 또는 설치된 `aqa` CLI를 직접 소비한다. 공개 core/playwright/appium import와 validate/plan은 브라우저·세션을 시작하지 않는다. `docs/package-api.md:14-20,50-69`, `docs/architecture/system-design.md:9-10`.

용어는 **수신 원본**(XML byte hash+원격 버전), **로컬 QA**(project+qa identity), **조합 문서**(Checker 편집 metadata), **실행 snapshot**(Engine canonical Blueprint hash), **실행 결과**, **증거 전달 상태**, **업무 상태**로 구분한다. XML byte SHA는 받은 원문 무결성, snapshot SHA는 정규화된 실행 정의의 동일성이다. 동일 snapshot만으로 같은 로컬 QA·같은 runtime·서버 업로드 호환성을 증명하지 않는다.

## 3. 화면 설계에 반영할 실제 흐름

### 로컬 개발·실행

내 프로젝트 → 로컬 QA → 직접 XML 작성/열기 또는 XML 파일 블록 배치 → 조합(지원 가능한 경우) → 공개 Engine 검증 → plan 확인 → 사용자의 실행 → 실행 snapshot 고정 → events 진행 → terminal 결과와 실제 artifact 확인.

- 블록 하나는 XML 파일의 재사용 instance다. 내부 action 노드와 블록 instance를 혼동하지 않는다. 엔진에 파일별 session을 요청하는 구조가 아니다.
- 현재 Checker 제한 조합은 동일 target, 단일 start/end 파일, 전체 연결된 순차 outer graph를 사용한다. instance별 node/selector/variable와 schema 참조를 namespace하고 중간 start/end를 접합한다. secret.ref는 외부 키라 보존한다. 합성 결과를 공개 Engine으로 다시 검증한다.
- unsupported references/testCase/authoring 등은 조합 거부와 직접 XML 보존을 구분한다. Engine 자체가 지원하는 입력이라도 현재 파일 조합기가 지원한다고 뜻하지 않는다. Blueprint에는 native import/include/call/subflow가 없다. `xml_block_compiler.dart:25-35,116-129,160-224` 및 기존 독립 CLI 교차검증 artifact 참고.
- 임의 XML을 받았다고 실행 가능으로 표시하지 않는다. 원문 보존, 파싱·검증 결과, capability/대상 준비 여부를 표시한다.
- AI는 작성 보조 경로다. Engine이 모델 설치·로그인·대화를 소유하지 않는다. AI 작성 성공은 검증 성공 또는 테스트 PASS가 아니다. `docs/ai-authoring.md:5-14,40-43`.

### 공용 QA 수신

서버에서 받기 → 권한 있는 게시 버전/Suite 탐색 → 버전 고정 → Suite라면 case 하나 선택 → 목적 로컬 프로젝트·새 QA 이름 → 원본 receipt + 직접 모드 sidecar → workspace commit → 가져온 QA/내 프로젝트 → 열기 → 별도 검증/실행.

- 현재 Desktop 홈: 내 프로젝트 / 서버에서 받기 / 가져온 QA. 개인 배정 inbox는 구현되지 않았다. 전체 Suite Desktop 일괄 실행은 구현되지 않았다(Checker 담당 확인).
- receipt는 원문/hash/remote identity를 local project+qa에 묶는다. orphan sidecar는 실제 workspace QA에 결합되지 않으면 목록에 나타나지 않는다. 새 QA는 직접 모드로 재열린다.
- 입력 수정 또는 조합 후 snapshot이 바뀌면 원본 출처는 유지하되 그 게시 versionId에 실행 결과를 귀속하지 않는다. 같은 원문을 가진 다른 로컬 QA에 원본 버전을 임의 연결하지 않는다. `SharedRepository.versionFor:53-62`는 문서 owner+origin+project+snapshot을 함께 확인한다.
- 앞선 독립 Dart 검토에서 receipt 동시writer, 늦은 offline/commit, hash·크기 제한·불변성을 확인했다. 이 기획 작업에서 native 재실행했다고 보고하지 않는다.

### 서버 자동 실행

게시 고정 QA/Suite → 권한 있는 즉시 요청/일정 → 서버 occurrence/job/lease → 별도 Agent → case별 Engine run → 원본 events/result/artifact 전송·ACK → 서버 진행/증거 확인 → 별도 업무 처리.

- Desktop 종료와 Agent 종료는 다르다. Desktop이 꺼져도 별도 Agent가 실행 중이며 서버·정책·자원이 준비돼야 자동 실행된다. Engine package만 설치해서 예약이 자동 시작되지 않는다.
- 실제 alpha.6 Nest/독립 Agent ordered Suite PASS/FAIL/cancel/게시·예약 인수 이력이 있다. alpha.8은 별도 HTTP fixture/설치 인수다. 기본서버 alpha.8 전환 인수로 합치지 않는다. `docs/agent.md:5,11,39,49-53`, `docs/validation-alpha.6.md:53,103,114`, `docs/validation-alpha.8.md:58-59`.
- Agent는 불명확한 이전 실행을 자동 재실행하지 않는다. 미확정 종료/기기 상태는 quarantine/reconcile 대상으로 표시한다. 업무 알림과 원본 Engine event stream은 다른 객체다.

## 4. 입력·출력·지원 경계

| 구분 | 현재 공개 범위 | 기획에 표시할 제약 |
|---|---|---|
| 입력 | JSON/YAML/XML Blueprint, TC 참조, JSON/YAML Suite, 별도 bounded authoring | raw Suite XML 미지원; 문서 크기 1MiB; 임의 shell/eval 없음 |
| Flow | start/action/assertion/branch/end, 유한 DAG, 명시 retry/timeout/cancel | 최대1000 nodes/2000 edges; runtime cycle 없음; 한 Blueprint 한 target/session |
| 반복 | authoring repeat 1..100 → 표준 DAG 전개 | 반복 안 branch/start/end/중첩 repeat 미지원; GUI 조합지원과 별개 |
| Web | Playwright 실제 Chromium, 입력·클릭·단언·스크린샷·시각/layout/UX·DOM capture | locator/target/기준 자산 필요; 임의 앱 자동 이해 아님 |
| Native | Appium Android/iOS protocol·capability·정리 코드와 fixture | 실기기 인수 미완료; TV 미지원 |
| Capture/secret | 공개 DOM 변수 capture, 외부 secretRef resolution | 캡처와 secret의 정책 충돌 거부; 실제 secret 값 metadata/artifact에 삽입 금지 |
| Suite | CLI `run-suite` ordered cases/stopOnFailure, Agent ordered lease | Desktop 전체 Suite UI가 생기는 것은 아님; Engine CLI Suite와 서버 registry Suite 구분 |
| 실행 출력 | runId/attempt/sequence events, plan/result/evidence, PNG 등 | 미수집 증거는 생성된 것처럼 표시하지 않음; artifact 한도256 |

근거: `packages/core/domain/actions.mjs:1-2`, `packages/cli/execution/suite.mjs:4-17`, `docs/package-api.md:55-69`, `docs/xml-format.md:17-27`, `docs/authoring.md:33-35`. Playwright/NATIVE_ACTIONS 목록은 플랫폼별로 다르므로 모든 액션을 모든 target에서 켜지 않는다.

## 5. 화면의 상태·예외 표기

| 조건 | 화면 의미 | 금지할 오해 |
|---|---|---|
| 입력/graph/secret 사전검증 실패 | 해당 오류·수정 위치, 실행 미시작 | run 성공/실패 결과를 꾸미거나 runId 합성 |
| 실행 전 준비 완료 | 검증/계획 완료, 실행 가능 조건 확인 | 이미 실행했거나 PASS라고 표시 |
| 실행 중 취소 클릭 | 취소 요청 중 → terminal 결과 확인 | 요청 전송 즉시 cancelled 합성 |
| passed/failed/blocked/infra_error/cancelled | Engine 결과 그대로 | 업무 완료/전송 완료와 동일 취급 |
| unvisited/선택 안 된 분기 | 미실행 | 성공으로 칠함 |
| step.skipped | 개별 단계 생략 | run terminal outcome처럼 사용 |
| 저장 결과와 CLI exit 불일치 | 전달 오류/결과 분리 표시 | exit3을 이유로 확정 cancelled/failed 결과 덮기 |
| evidence 없음/수집 오류 | 실제 수집 상태·사유 | infra_error/cancelled에 가상 스크린샷 표시 |
| 공유 실패/버전 불일치 | 로컬 결과 유지 + 공유 상태 오류 | 로컬 passed를 Engine blocked로 변경 |

CLI mapping: passed0/failed1/입력2/infra3/blocked4/cancelled5. 하지만 출력 전달 실패는 확정 result와 다른 exit3을 낼 수 있다. `packages/cli/README.md:13-27`. 취소 후 graceful cleanup과 강제 process kill은 다르며 Appium session 정리 불명은 별도 운영 위험이다.

## 6. alpha.6 서버와 alpha.8 Desktop

- 서버 게시 예제 alpha.6 XML과 alpha.8 fixture는 byte SHA `bc2210abfcdb7de02ae77e51598535da63e2dcd4c501670e5e160aa3fa3bd729`로 동일한 확인 이력이 있다. 공개 지원 입력을 받아 alpha.8로 로컬 검증·실행하는 데 서버 pin 승격은 필수가 아니다.
- alpha.8 tgz SHA `4215662445780eeecd016ad6acf2a7b2c5e16b9a4e62cf8ae88e30ee0452e77f`, bundle SHA `638d48f182d12819ebd167d42457c7dceaa90928abb38c32a4867e3c94b10763`.
- 서버 `platform.service.ts:143-144`는 input.engineVersion==server.engine.version 및 plan identity를 검사한다. 기본 alpha.6 서버에 alpha.8 결과를 자동 공유 가능한 선으로 그리면 틀리다. runtime version을 alpha.6으로 바꾸어 보내서도 안 된다.
- Checker `docs/validation-desktop-ai.md:26`의 공유 인수는 alpha.8 manifest를 명시 주입한 격리 서버다. 기본 서버·Agent pin 전환이 아니다. 기획은 로컬 실행과 서버 호환 게시를 구분하고 후자는 명시 호환 조건/후속 계약 단계로 남긴다.

## 7. 3담당 대화와 반영

1. Engine→Checker 1차: 원본/로컬/조합/snapshot/결과/업무를 나누고 alpha.6 서버와 alpha.8 Desktop lane, 개인배정·전체Suite 미구현을 제안했다.
2. Checker 피드백: 홈 3곳, 게시 Suite 고정 후 case 하나 수신, receipt의 local project+qa 귀속, snapshot 변경 시 원본version 귀속 금지 확인. 이 문서 §3과 화면 예외에 반영했다.
3. Engine→웹 1차: 실행결과와 업무/전달 상태, 서버 runtime equality, ordered Agent Suite와 Desktop Suite 범위를 전달했다.
4. 웹 피드백: 사용자 게시 QA/Suite→Desktop lane과 권한 있는 Agent 요청/예약→서버 lane 분리, outcome/evidence/work/job/occurrence 다섯 상태를 분리하겠다고 제안했다.
5. Engine 재검토: 웹의 ‘blocked compatibility’는 Engine outcome=blocked가 아니라 공유 호환성 상태로 고쳐야 한다고 전달했다. 취소요청/실제 terminal 및 존재하는 증거만 연결하는 조건도 전달했다. Checker에 이 피드백을 공유했다.
6. 웹 최종 응답: 위 보완을 수용하고 Engine 판정/실행요청·lease/증거정합/업무/예약 occurrence/전송의 6개 상태를 구분하기로 했다. 웹 Suite UI 검증의 `agentActuallyExecuted:false`와 별도 실제 Agent 인수를 구분하며 사용자·관리 workspace는 동일 Nest API/RBAC를 공유한다.
7. Checker 최종 응답: E01은 실제 Engine GUI가 아닌 XML→validate→plan/snapshot→event/result/evidence 검토 화면으로 명세화했다. 결과 연결은 Engine→Desktop(로컬), Engine→Agent→서버→웹으로 표시하고 Desktop→서버는 runtime/게시 snapshot 호환 조건부로 표시한다. Engine 담당이 이 경계에 동의했다.
8. 웹 권한 최종 확인: SchedulerService.createExecution/create/setEnabled와 AgentService.preparePublished/cancel은 qa_tester 이상이다. 관계도에 사용자 웹→즉시 Agent 실행 요청/예약/취소 edge를 추가했다. 관리 workspace와 최소 API 권한을 동일 개념으로 취급하지 않는다. 복구/감사/알림요청은 qa_manager+, 초안은 qa_editor+, 검수·게시에는 qa_manager+ 및 독립 검토자 조건을 적용한다(웹 담당 확인).

합의 상태: Desktop·웹의 1차 피드백을 받은 뒤 위 범위로 반영 완료. 구체 화면 수/배치·권한 액션 matrix와 마지막 용어 정합은 관리자가 세 담당 문서를 통합한다. Engine의 새 schema/버전 또는 서버 pin 변경은 이번 기획에서 요청하지 않는다.

## 8. 검증 근거와 이번 작업의 한계

- 기존 alpha.8 인수: `docs/validation-alpha.8.md:55-66`의 188/188, 독립 설치148파일, 공개 CLI/API/실제 Chromium 및 Checker 격리 소비 기록. 새 실행 결과가 아니다.
- 기존 조합 독립검토: `artifacts/checker-xml-composition-review-20261111/review.json`, `mapping-review.json`.
- 기존 상태/출처 독립검토: `artifacts/checker-xml-block-state-review-20261111/final-closure-review.json`, `artifacts/checker-received-home-review-20261111/final-closure-review.json`.
- 이번 검토는 Git/manifest/실제 source/docs/specs와 담당 간 대화를 확인했다. native UI/전체 서버·Suite/실기기·외부 계정 검증을 새로 실행하지 않았다.
- 원본 8 MD: CHECKER_CODEX_PROMPT, CODEX_MASTER_PROMPT, CONTRACTS_AND_EXAMPLES, COPY_PASTE_FIRST, ENGINE_CODEX_PROMPT, PHASES_AND_ACCEPTANCE, README, WORKTREE_OPENSPEC_GUIDE. 원본 요구와 과거 예시·로드맵, 현재 실행 구현, 새 화면 제안을 각각 구분했다.
