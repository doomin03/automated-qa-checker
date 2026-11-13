# Design

## Context

2026-11-12 다중 터미널 인수는 실제 셸 파일 변경/GUI·template/compose·PASS/FAIL/cancel을 포함한다. Codex는 0.162.1의 업데이트 메뉴 시작까지만 검증했고 Claude는 PATH와 두 일반 설치 후보에서 발견되지 않았다. 예전 비대화 Codex 생성 인수를 interactive TUI 파일 편집으로 대체하지 않는다. 상세 미완료 대응은 [gap-mapping.md](gap-mapping.md)에 있다.

## Goals / Non-Goals

CLI가 없거나 경로를 모르는 사용자에게 실행 가능한 다음 조작을 제공하고, 준비된 세션에서 명시 요청이 파일·GUI·실행 결과로 이어지는 것을 실제 인수한다. 기존 다중 PTY/pool·writer epoch·composition 보호는 유지한다. 모델 선택/과금 자동화, credential 복사, 전역 config 변경, 앱 내 AI API·설치 스크립트 실행, 새 실행 DSL은 포함하지 않는다.

## Decisions

### D1. 준비 상태와 설치 선택

Model은 provider id, 실행 파일, 진단 시각/결과를 분리한다. 상태는 미설치/확인 필요/사용 가능/지원 옵션 없음/진단 실패이며 로그인·모델 준비를 단정하지 않는다. 기존 `TerminalProfileService.inspect`의 bounded 프로세스/EOF/출력 검사를 재사용한다. Codex는 실제 help 옵션을 확인하며 Claude는 version probe 성공을 interactive 기능 완전 검증으로 표시하지 않는다.

새 터미널 폼에 기존 실행 파일 선택, 경로 기억, 공식 설치 안내 복사, 다시 확인을 제공한다. 공식 설치는 사용자가 외부에서 수행하고 앱은 재탐색한다. 설치 명령을 PTY에 자동 전송/실행하지 않는다. 선택한 경로만 앱 전용 로컬 preferences에 atomic 저장한다(프로젝트 공유 문서·Engine pin·Git asset 제외). 저장 실패면 기억 실패를 표시하되 현재 명시 경로 진단은 가능하다. 저장 경로는 다음 실행에서 재진단하며 성공 상태를 영구 신뢰하지 않는다. 알 수 없는 provider/상대 경로/잘못된 형식은 원문을 보존하며 거절한다. View는 파일 IO를 수행하지 않고 기존 composition root에서 Repository/VM을 조립한다.

### D2. 작성 환경을 확인하고 문맥 전달

세션 메뉴에 고정 QA/시작 cwd, 가이드 경로·버전·hash, contract 버전, 활성 파일을 읽기 전용으로 표시한다. `authoring-environment.json`의 prepared만으로 CLI discovery/사용 확인을 만들지 않는다. Codex `$qa-authoring` 및 Claude `/qa-authoring` 안내는 공식 문서와 로컬 실제 UI를 대조하고, 호출은 사용자가 직접 제출한다. 문맥 요청 복사/미제출 입력도 session id+inputEpoch를 고정해 clipboard await 중 탭/QA/작성자 변경 시 다른 터미널에 보내지 않는다. 자동 Enter/모델 호출은 없다. 일반 셸에 AI 준비 배지를 붙이지 않는다.

### D3. 실제 AI 인수

저장소 밖 전용 QA 사본에서 기존 CLI 로그인으로 시작한다. 업데이트 건너뛰기는 설치 변경 없이 가능하다. 관리 승인된 정확한 세션 경로의 일회성 `-c projects.<path>.trust_level`만 시험에 사용하며 전역 설정에 영구 저장되는 trust UI 선택은 하지 않는다. 전체 저장소/홈 trust 또는 전역 권한 완화는 하지 않는다. 전역 config는 내용 대신 전후 SHA만 대조한다. 준비된 가이드가 실제 표시/호출되는지 별도로 증거를 남긴다. 모델의 말만으로 발견 성공을 단정하지 않고 CLI 관찰과 실제 읽은 문맥/요청 결과를 구분한다.

2026-11-12 복구 시험 `artifacts/terminal-readiness/native/run-6cb831f3/verification.json`에서 요청 입력 뒤 Codex 사용량 한도 오류를 확인했다. 파일 SHA 불변, GUI 새 노드 없음, sync 오류 없음, 소유 PID 종료/cleanupUnknown=false/config SHA 불변이다. 최초 시험과 의미 있는 복구 한 번 이후 추가 모델 호출하지 않았으며 실제 편집·skill 사용·XML/JSON end-to-end 인수는 미완료다.

XML 한 사례와 JSON 한 사례를 각각 시작해 원본 노드를 보존하면서 지정된 단언/스크린샷 등 제한된 수정을 요청한다. 실제 파일 bytes hash→공개 plan snapshot→GUI node/edge→명시 run의 hash/events/result/PNG를 연결한다. 유효하지 않은 출력은 마지막 유효 그래프 유지, GUI dirty/두 형식 충돌/QA 또는 writer ABA는 기존 정책 그대로다. 파일 편집 완료가 자동 run을 일으키면 실패다. TUI 로그인/요금/네트워크/도구 미설치 때문에 중단되면 단계와 외부 조건을 기록하고 end-to-end task는 미완료로 둔다. 실제 Claude가 없으면 provider fixture와 가이드 준비만 완료로 기록한다.

### D4. UI 범위와 인수

frontend-design/qa-workbench-design의 기존 compact neutral desktop 셸을 유지한다. 새 화면 재설계 없이 추가 폼의 명확한 상태·복구 버튼과 세션 환경 메뉴만 보완한다. 800×600/text1.5에서 scroll/키보드로 접근하고, terminal focus의 Ctrl+C/Delete가 canvas를 수정하지 않으며 한글 IME 조합 중 전환/붙여넣기 상태를 실제 Windows에서 확인한다. 현재 1440/1024/800 split/resize 인수는 재사용한다. 새 native 캡처는 준비 실패/복구와 실제 AI 편집 결과에 한정한다.

### D5. 기존 명세와 배포

옛 `qa-desktop-interactive-terminal` task는 전체 조건별 증거를 연결한 뒤 체크한다. 과거 alpha.8 특정 Release 이름은 후속 alpha.9 인수가 대체했다는 명시적인 migration 주석으로 정합하며 존재하지 않는 과거 배포를 만들지 않는다. archive/sync는 미완료 실제 AI 인수를 닫기 전 수행하지 않는다. root README/AGENTS/시스템설계의 현재 버전 문구는 역사 문장과 구분해 최종 정합한다.

readiness 제품 수정은 alpha.9에서 집중 인수하고 최종 배포는 관리 승인 alpha.10 portable/runtime 정합 change와 합쳐 한 번 생성한다. 기존 frozen package와 모든 Release는 보존하고 새 소스/SDK/vendor/config/전체파일·startup manifest로 인수한다. 서버 runtime mismatch는 계속 명시 오류이며 로컬 판정은 보존한다. `qa-desktop-portable-runtime`의 새 SDK/runtime 동결 게이트를 따른다.

## Risks / Trade-offs

- 실행 파일 존재/버전과 계정·모델 사용은 독립이다. 로컬 프로필 저장은 CLI 로그인 저장이 아니다.
- 공식 설치 절차는 바뀔 수 있으므로 URL와 확인 날짜를 표시하고 고정 원격 스크립트를 묵시 실행하지 않는다.
- 실제 AI 출력은 비결정적이므로 제한된 의미 검사로 인수하고 모든 프롬프트 정확도 보장으로 확대하지 않는다.
- 실제 IME/승인 화면과 fake keyboard/PTY fixture 증거를 분리한다.

## Research Evidence

2026-11-12 로컬 `codex.exe --version`은 `codex-cli 0.162.1`, help에 no-daemon/no-alt-screen/sandbox/ask-for-approval 확인. 실행 파일은 현재 설치 경로에서 탐지했으나 사용자 경로를 커밋된 기본값으로 추가하지 않는다. Claude는 현재 검사에서 미발견이며 설치하지 않았다.

- [공식 Codex commands](https://learn.chatgpt.com/docs/developer-commands?surface=cli)
- [공식 Codex skills](https://learn.chatgpt.com/docs/build-skills)
- [공식 Claude 설치/개요](https://code.claude.com/docs/en/overview)
- [공식 Claude skills](https://code.claude.com/docs/en/skills)

OpenAI Docs, frontend-design, qa-workbench-design 스킬을 적용했다. 앞선 Engine 작성 책임 이관 사용자 결정이 기존 UI compiler 관련 skill 문구보다 우선한다.
