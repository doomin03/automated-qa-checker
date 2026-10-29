# automated-qa-checker

Flutter 테스트 개발·실행 앱, React 사용자 공용 시나리오·진행 웹, 공통 Nest 서버의 pnpm/Turbo 모노레포다. 관리 기능은 권한별 업무로 구분한다. **웹 관찰 화면과 Flutter MVVM/Provider 초안 편집 shell이 검증되었으며 서버는 설계 단계**다.

사용자가 전달한 모노레포 OpenSpec은 [이관 proposal](openspec/changes/refactor-server-web-app-monorepo/proposal.md), [설계](openspec/changes/refactor-server-web-app-monorepo/design.md), [원본 대응·소유권](openspec/changes/refactor-server-web-app-monorepo/integration.md)에 있다. 원본을 보존해 QA에 맞게 이관했으며 현재는 명세 검토를 먼저 한다. [모노레포 정책](docs/architecture/monorepo-policy.md)은 현재 구현된 부분과 목표를 구분한다.

기능 우선의 첫 **Blueprint 관찰 화면**을 apps/web에 구현했다. AI CLI가 만든 JSON 문서의 검사/편집/내보내기, node/edge 보기, 실제 엔진 JSONL event 재생과 파일 따라가기를 제공한다.

## 실행

Node 24.18.0 기준, 저장소 루트에서 실행한다.

```powershell
npx --yes pnpm@10.34.8 install --frozen-lockfile --ignore-scripts
npx --yes pnpm@10.34.8 run dev:web
```

http://127.0.0.1:4318 에서 열고 **실제 실패 기록 예제**를 누르면 실제 Playwright 실패 기록이 그래프에 표시된다.
자신의 실행은 engine가 저장한 blueprint.json과 events.jsonl을 가져온다. 지원 브라우저에서 이벤트 파일 따라가기를 선택하면 파일이 갱신될 때 진행을 표시한다.

## 검증

```powershell
npx --yes pnpm@10.34.8 exec playwright install chromium
npx --yes pnpm@10.34.8 run verify
```

Checker는 엔진 source를 복사하지 않는다. public contract artifact 0.1.0-alpha.1의 SHA-256을 검증하고 소비한다.
현재 검증된 웹은 AI CLI를 직접 호출하거나 QA를 자동 시작하지 않는다. XML 내보내기 코드 2파일은 구현 도중 명세 우선 지시로 중단되어 미검증 상태다. Flutter는 기능별 MVVM/Provider, XML/JSON 원문 편집·파일 열기/저장과 Windows build까지 구현했다. [앱 구조와 실행 방법](docs/architecture/flutter-mvvm.md)을 따른다. drag/drop builder·엔진 검증/실행·Nest/Slack/예약 서비스는 아직 미구현이다.

목표 흐름은 웹에서 공용/사용자 Blueprint를 XML로 전달하고, Flutter에서 블록/Flow 또는 XML을 작성·검증·명시 실행하며 진행을 웹에서 확인하는 것이다. 첫 파일 전달은 [XML handoff change](openspec/changes/qa-user-web-desktop-handoff/proposal.md), 서버 전달·진행 자동 수신은 [플랫폼 change](openspec/changes/qa-platform-services/proposal.md)에서 추적한다.

[모노레포 정책](docs/architecture/monorepo-policy.md) · [AI와 GUI 정책](docs/ai-blueprint-policy.md) · [개발 안내](docs/development.md) · [검증 결과](docs/validation.md) · [설계](docs/architecture/system-design.md) · [기획](docs/planning/roadmap.md)

main/60b32ec 기준 미커밋 변경이며 commit/push/새 worktree는 만들지 않았다.

