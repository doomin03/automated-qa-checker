# Automated QA Checker

Local-first QA automation for weekly production smoke checks across web, Android, iOS, and webOS targets.

Implementation follows the OpenSpec change at `openspec/changes/build-local-weekly-check-automation`.

## Current Status

The project is being scaffolded. External integrations are disabled by default and must remain no-op until a future OpenSpec change enables them.

Current executable scope:

- Target registry loading
- Scenario YAML loading
- `qa:list`
- `qa:run` / `qa:scenario` minimal JSON result generation

Actual Appium and Playwright platform runners are not implemented yet and return `NOT_IMPLEMENTED`.

## Local Setup

macOS is the primary runtime target:

```bash
chmod +x setup.sh
./setup.sh
```

Windows helper for Android ADB checks:

```bat
setup.bat
```

iOS Simulator setup is macOS-only.

Detailed setup script usage is documented in [docs/SETUP_SCRIPTS.md](docs/SETUP_SCRIPTS.md).

## User Guides

주간 체크 대상 등록, 시나리오 작성, 기준 이미지 위치, 실행 명령은 [docs/WEEKLY_CHECK_MANUAL_KO.md](docs/WEEKLY_CHECK_MANUAL_KO.md)에 정리되어 있습니다.

프로젝트 폴더 구조와 YAML 필드별 작성법은 [docs/PROJECT_STRUCTURE_KO.md](docs/PROJECT_STRUCTURE_KO.md)를 참고하세요.

등록부터 실행까지의 사용자 워크플로우는 [docs/USER_WORKFLOW_KO.md](docs/USER_WORKFLOW_KO.md)를 참고하세요.

실제 Runner 구현 순서는 [docs/IMPLEMENTATION_ROADMAP_KO.md](docs/IMPLEMENTATION_ROADMAP_KO.md)에 정리되어 있습니다.
