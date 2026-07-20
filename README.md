# Automated QA Checker

Local-first QA automation for weekly production smoke checks across web, Android, iOS, and webOS targets.

Implementation follows the OpenSpec change at `openspec/changes/build-local-weekly-check-automation`.

## Current Status

The project is being scaffolded. External integrations are disabled by default and must remain no-op until a future OpenSpec change enables them.

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

Detailed registration and execution steps are documented in [docs/SETUP_SCRIPTS.md](docs/SETUP_SCRIPTS.md).
