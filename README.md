# Automated QA Checker

Local-first QA automation for weekly production smoke checks across web, Android, iOS, and webOS targets.

Implementation follows the OpenSpec change at `openspec/changes/build-local-weekly-check-automation`.

## Current Status

The project is being scaffolded. External integrations are disabled by default and must remain no-op until a future OpenSpec change enables them.

## Local Setup

macOS is the primary runtime target:

```bash
./scripts/setup-local.sh
```

Windows helper for Android ADB checks:

```bat
scripts\setup-local.bat
```

iOS Simulator setup is macOS-only.
