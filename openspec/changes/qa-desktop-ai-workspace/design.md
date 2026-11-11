# Design

## Context

2026-11-10 조사: Checker main/4f97e920a399d4a5434ab1ecbe44c4d879d397a4와 기존 dirty tree. 실제 앱 진입은 ScenarioEditorView이며 파일 원문/Flow/RunPanel을 제공한다. 프로젝트 목록과 AI 호출은 없고 design/mockups/desktop/blueprint-workspace는 별도 HTML 시연이다. AppProviders가 소유 의존성을 한 번 해제하며 WorkbenchViewModel이 기존 기능 순서를 조합한다. 이 경계를 유지한다.

기본 Engine alpha.6 pin JSON SHA256은 87638dc27aa8d3a33a6edfab22fb6404d146711a4b85c6b19532053177251d65, 기존 앱 runtime asset은 982ff50f7b4b96bc14378ab7ae6490cf1a43bf32595764a62fb5079b474645ec, HTTP OpenAPI는 f705acfa8a30d4c89ec8f588a2d85bd49a837ee1084d93fa273a725f3a09ef90이다. 기존 alpha6-mvvm Release는 2026-10-31 빌드이며 이후 transport 보완은 source에만 존재한다.

## Goals / Non-Goals

**Goals:** 기존 실행 기능을 유지하면서 앱 하나에서 프로젝트 선택, QA 작성, AI 후보 검토, 실제 실행·이미지 확인을 끝낸다. 신규 클래스는 기능별 MVVM/Provider 구조로 추가하고 기존 Engine 실행 의미를 재정의하지 않는다.

**Non-Goals:** 서버 runtime 승격, 원격 배포, 실기기 인수, AI 이미지 해석, API 키 보관, Figma 연동, 임의 shell 작업, 모든 CLI 플러그인의 범용 지원. 기존 mockup 완료 change는 수정하지 않는다.

## Decisions

### D1. 로컬 작업 공간과 저장 경계

features/project_workspace에 immutable Project/QA/Workspace 모델, WorkspaceViewModel, Repository와 FileService를 둔다. APPDATA 아래 AutomatedQA/workspace-v1 폴더를 기본값으로 하고 테스트는 독립 디렉터리를 주입한다. 단일 workspace.json에 version, store revision, 프로젝트/QA ID, 이름, 문서, 프로젝트 지침, QA 요청, 수정 시각, 최근 실행의 runId/snapshotHash/reportDirectory/outcome을 QA ID에 귀속해 저장한다. 결과 메타데이터 기록은 저장된 원문/지침만 유지하며 현재 미저장 편집·프롬프트를 덮지 않는다. 일회성 AI 변경 요청은 저장되는 QA 지속 요청과 구분하고 QA 전환 시 초기화한다. 첫 단위에서 SQLite/plugin 추가 대신 bounded JSON을 사용한다(파일 16MiB, 문서 1MiB, 지침/요청 각각 64KiB). 초과 시 명시 오류다.

읽기 시 구조/중복 ID/연결 무결성과 UTF-8 크기를 검사한다. 쓰기는 sibling 임시 파일 flush→원자 rename이고 OS 파일 잠금과 저장 revision 비교로 두 인스턴스의 덮어쓰기를 막는다. 훼손 파일은 자동 초기화하지 않는다. 편집은 VM에 유지하고 명시 저장, QA 전환 시 미저장 변경 확인을 제공한다. 외부 XML 열기는 가져오기이며 별도 명시 내보내기 전 원본 파일을 변경하지 않는다. 실행 결과 파일은 원래 reportRoot에 남겨 저장소 크기와 분리한다.

### D2. 도킹 View와 단일 문서 정본

app/workbench 상위 View가 프로젝트/QA 목록, 중앙 XML/Flow, 우측 선택 속성·AI, 하단 실행 결과를 조합한다. charcol/단색·최소 아이콘·그라데이션 없음 방향을 실제 Flutter에 구현한다. 기술 설정은 별도 패널이다. 기존 FlowEditorView/RunResults를 재사용하되 선택 node ID와 selection revision을 VM에 노출해 UI와 AI가 같은 문맥을 사용한다. TextEditingController/focus는 View 수명, 문서·프로젝트·선택·요청 상태는 VM 수명이다.

ScenarioEditorViewModel.draft가 열린 QA의 편집 정본이며 WorkspaceVM에 매 keystroke 복제하지 않는다. 저장/전환 시 snapshot을 취하고 새 QA 열기에서는 문서 revision을 증가시킨다. Workbench coordinator만 여러 기능의 흐름을 조합한다. RunVM은 기존 실행 상태를 계속 소유한다. 실행 중에는 QA 전환·AI 적용을 비활성화하고 snapshot 읽기 뷰를 제공한다. 1024에서는 탐색/AI 접기와 패널 내부 스크롤로 접근성을 확보한다.

### D3. 로컬 AI adapter와 권한

features/ai_authoring에 immutable settings/request/proposal/event, AiAuthoringViewModel, Repository, LocalAiCliService와 공급자별 command adapter를 추가한다. 사용자 경로와 version/help를 확인하고 알려진 adapter만 실행한다. shell 없이 absolute executable + argument array를 사용한다. prompt를 command 문자열로 결합하지 않는다. 지침·원문은 전송 전 사용자에게 대상/내용 요약을 보여 주며 CLI 기존 인증을 사용한다. 앱이 provider 키를 수집하거나 토큰 파일을 읽지 않는다.

기본 제공자는 실제 지원 CLI가 확인된 Codex이며 Claude는 미설치를 진단한다. 관리 probe에서 C:/Users/Domin/AppData/Local/Programs/OpenAI/Codex/bin/codex.exe는 codex-cli0.162.1이고 ChatGPT 로그인, structured exec exit0이 확인됐다. 고정 호출은 전역 `-a never` 뒤 `exec --ignore-user-config --ignore-rules --ephemeral --skip-git-repo-check --sandbox read-only --disable shell_tool --disable apps --disable hooks --disable multi_agent --disable remote_plugin -c agents.enabled=false -c web_search="disabled" --json --color never --output-schema <session/schema.json> --output-last-message <session/answer.json> -`이다. stdin에 prompt를 전달하며 schema는 additionalProperties:false인 summary/xml 문자열 객체다. thread.started/turn.started/item.completed(agent_message)/turn.completed를 해석한다. 지원되지 않는 flags/version은 실패로 처리하고 전체권한 fallback은 없다. read-only 자체가 모든 도구 차단 또는 OS 전체 격리를 보장한다고 설명하지 않는다. 실제 실행에서 도구 호출 이벤트가 나오면 후보를 거절한다. 근거는 관리 coordination/scripts/probe-desktop-codex.mjs 및 coordination/artifacts/desktop-codex-probe-20261110/result.json이며 QA 생성 인수와는 별개다.

프로젝트별 sessions/<request-id>를 생성해 복사 원문·prompt·후보만 두고 사용자 프로젝트/저장소를 CLI cwd로 사용하지 않는다. 작업 중 외부 원본 경로를 쓰기 대상으로 전달하지 않는다. CLI stdout에서 최종 답변을 분리해 앱이 candidate.xml을 독점 생성한다. 부득이 파일 출력을 사용하는 adapter도 세션 내부 신규 파일만 허용하며 symlink/경로 이탈을 거절한다. candidate 본문은 1MiB, stdout 총4MiB, stderr 총1MiB, 전체180초, 소유 프로세스 tree 종료 명령 최대5초+exit/pipe 정리7초의 기본 예산을 둔다. SDK/공급자 필요에 따른 변경은 실제 측정으로 기록한다.

stdout/stderr는 UI 구독과 독립적으로 drain한다. generation별 하나의 process를 추적하고 취소는 adapter의 지원 방식 우선, 유한 grace 후 소유 프로세스 종료를 수행한다. Windows child tree 잔존은 실제 fixture로 확인한다. 정리 미확인은 성공 취소로 합성하지 않는다. stream 원문은 디스크에 무제한 저장하지 않고 UI에는 제한된 생성 상태·오류를 표시한다. 인증 토큰과 환경변수 내용은 로그에 출력하지 않는다.

### D4. 제안 검증·범위·stale 적용

요청 stamp는 projectId/qaId/documentRevision/selectionRevision/promptRevision/settingsRevision/generation과 원문 hash를 포함한다. 모든 await 후 및 적용 직전에 확인한다. 텍스트 ABA 원복도 revision이 달라 거부한다. 원본과 candidate는 독립 임시 파일이며 전체 Engine import/validate/plan 공개 호출만 허용한다. AI 상태는 idle/diagnosing/generating/validating/review/failed/cancelled/stale로 실행 상태와 분리한다. 후보 검증은 EngineRepository를 통해 직접 수행하며 기존 결과를 비우는 RunViewModel.validate를 재사용하지 않는다. 실제 QA 실행 중에는 후보 검증을 시작하지 않아 공유 service의 실행/취소 수명을 섞지 않는다.

전체/선택/앞/뒤는 편집 요청 범위이다. node 배열 순서가 아닌 edge 기준 문맥과 참조 selectors/target/variables를 전달한다. AI가 요청 외 영역도 바꾸면 diff에서 모두 노출하며 좁은 범위 제안의 추가 변경 경고를 확인한 뒤에만 적용한다. 원문 XML 비교와 정규화 plan의 added/removed/changed nodes/edges 및 root fields 변경을 제공한다. byte 비교와 실행 hash 비교를 구분한다. XML 외 응답/잘못된 XML/깨진 참조는 후보 실패이며 추측해 잘라 성공 처리하지 않는다.

적용은 검증된 전체 XML을 editor에 한 번 전달하고 이전 원문을 undo snapshot으로 보관한다. undo는 적용 직후 document revision과 같을 때만 허용하며 후속 편집이 있으면 거부한다. 적용/undo는 기존 검증을 무효화하며 run을 호출하지 않는다. 화면의 실행 버튼은 별도 명시 동작이다. AI가 코드를 반환해도 앱이 실행하지 않는다. 완료 결과에는 원래 프로젝트/QA ID와 snapshot hash를 표시하고 QA 전환 뒤에도 소속을 바꾸지 않는다. 프로젝트/QA 프롬프트 dirty 상태는 XML dirty와 독립적으로 전환 확인에 포함한다.

### D5. Desktop alpha.8 설치와 기존 환경 보존

앱 전용 pin을 apps/app 아래 두고 기존 packages/contract/engine-runtime.json 및 generated/engine-contract.json은 alpha.6 유지한다. 앱 설치 도구는 검증된 alpha.8 tgz(4215662445780eeecd016ad6acf2a7b2c5e16b9a4e62cf8ae88e30ee0452e77f), bundle(638d48f182d12819ebd167d42457c7dceaa90928abb38c32a4867e3c94b10763), execution contract0.3.0-draft.2를 확인해 .local/desktop-engine/0.1.0-alpha.8/<sha>에 설치한다. 기존 .local/engine과 격리인수 폴더는 변경하지 않는다.

설치된 전체 파일 manifest와 공개 bundle을 apps/app/assets/desktop-engine-runtime.json 및 desktop-engine-contract.json에 조립하고 BlueprintCatalog/LocalEngineCliService의 기존 주입 경로로 소비한다. 기존 assets/engine-runtime.json과 engine-contract.json은 alpha.6 bytes 그대로 보존한다. 기기 경로가 포함되는 desktop-installation.json은 ignored 생성 asset이다. 새 앱은 설치 receipt에서 Node/CLI 경로를 찾거나 사용자 설정으로 연결하며 명시 runtime 설정만 저장한다. 외부 라이브러리 구현을 vendoring하지 않는다. Chromium 설치는 해당 설치 package의 Playwright CLI로 수행한다. node_modules 전체 무결성을 보증한다고 과장하지 않고 manifest 범위를 기록한다.

서버/Agent는 alpha.6 유지하므로 새 앱의 서버 게시를 자동 활성화하지 않는다. 공유 XML 가져오기는 비실행 수신이며 새 runtime으로 다시 검증한다. 게시 시 version 불일치 오류는 게시 상태에만 표시한다. 새 Release를 artifacts/releases/desktop-ai-alpha8에 전체 폴더로 저장하고 app.so/runtime asset 포함 모든 파일 hash를 기록한다.

### D6. 검증과 완료 경계

저장 재시작/충돌·I/O 실패, Provider scope disposal, 선택·문서·QA ABA stale, 네 편집 범위의 전체 diff, invalid XML, 취소/timeout/출력 제한과 프로세스 종료를 deterministic fixture로 검증한다. 실제 Codex 설치/인증을 사용한 요청은 별도 인수하며 인증 실패를 숨기지 않는다. 실제 AI가 만든 후보를 공개 Engine으로 검증하고 사용자 동작을 통해 로컬 fixture URL을 실행하여 PASS/의도 FAIL/PNG 경로를 확인한다. UI 인수는 Windows 제품 View/Provider 경로와 캡처를 사용한다. 모바일·Slack·AI 이미지 해석은 이번 증거에 포함하지 않는다.

## Risks / Trade-offs

- CLI 인증·모델 가용성 → 외부 설정 실패를 정확히 표시하고 실제 생성 인수를 별도 기록한다.
- AI 출력의 불확실성 → 전체 검증·변경 비교·명시 적용, 자동 실행 금지로 경계를 둔다.
- 단일 JSON 저장 크기 제한 → bounded 파일과 명시 오류; DB 확장은 후속 측정 근거로 결정한다.
- alpha.8 앱과 alpha.6 서버 불일치 → 로컬 경로 우선, 게시 실패 분리, 기존 운영 환경 보존.
- 큰 Flow UI 비용 → 기존 1000node 보완을 재사용하고 새 전체 가상화는 이번에 하지 않는다.

## Migration Plan

1. 기존 제품·설치·Release·HTTP·목업 hash를 기록하고 신규 기능은 기존 앱 저장소와 충돌하지 않는 workspace-v1에 둔다.
2. 프로젝트 저장/도킹 View → AI adapter/검증 승인 → 앱 전용 alpha.8 → 실제 Windows 인수 순으로 적용한다.
3. 이전 앱은 alpha6-mvvm에서 계속 실행할 수 있다. 새 폴더의 앱만 배포하며 이전 폴더를 덮어쓰지 않는다. 문제가 있으면 이전 앱으로 복귀하고 새 workspace 파일은 보존한다.
4. docs/local-demo.md와 앱 안내에 새 앱의 설정/인증/명시 실행 순서 및 실제 인수 여부를 기록한다.
