# AGENTS.md

## Project

This repository implements `build-local-weekly-check-automation`, an OpenSpec-driven local QA automation project for weekly checks of production web sites and deployed Android, iOS, and webOS app artifacts.

Primary planning source:

- `openspec/changes/build-local-weekly-check-automation/proposal.md`
- `openspec/changes/build-local-weekly-check-automation/design.md`
- `openspec/changes/build-local-weekly-check-automation/decisions.md`
- `openspec/changes/build-local-weekly-check-automation/tasks.md`
- `openspec/changes/build-local-weekly-check-automation/specs/**/spec.md`

## Implementation Boundary

- Implement the OpenSpec change incrementally.
- Keep the current execution mode local-only.
- Do not enable n8n, GitLab, PostgreSQL, Slack, email, schedule, remote runner, cloud device farm, or external webhook behavior.
- Do not run real production crawling, real account login, APK installation, emulator boot, iOS Simulator boot, or Appium sessions unless the user explicitly asks.
- Treat setup scripts as user-run helpers. Normal QA commands must not auto-install global tools.

## Tech Stack

- TypeScript with strict mode
- Node.js CLI
- pnpm
- Playwright for future web crawling
- Appium and WebdriverIO for future mobile automation
- Zod for future runtime config validation
- YAML config files for targets, devices, scenarios, and integrations

## Directory Conventions

- `configs/targets/index.yaml` is the target registry entry point.
- `configs/targets/{web,android,ios,webos}/` contains target YAML files.
- `configs/crawlers/` contains crawler policies.
- `configs/devices/` contains device profiles.
- `tests/scenarios/` contains YAML scenarios.
- `tests/images/` contains baseline images.
- `src/` contains TypeScript implementation.
- `scripts/` contains setup and local helper scripts.
- `outputs/runs/` contains generated run results and must not be committed.

## Safety Rules

- Production scenarios default to `READ_ONLY`.
- `SAFE_WRITE` requires explicit opt-in.
- `DESTRUCTIVE` scenarios are blocked by default.
- Secrets must be read from environment variables and redacted from logs, reports, and errors.
- Product failures must be reported as `FAILED`.
- Tooling, device, binary, config, and automation failures must be reported as `BROKEN`.
- Known unsupported runner features must be reported as `NOT_IMPLEMENTED`, not hidden as success.

## Setup Script Rules

- macOS `.sh` scripts are the primary setup path.
- `.bat` scripts are helper scripts for Windows Android/ADB checks only.
- iOS Simulator setup is macOS-only and must fail clearly on non-macOS systems.
- ADB may be installed on macOS through Homebrew with `brew install --cask android-platform-tools`.
- Android Emulator setup may require Android Studio or Android SDK emulator packages beyond ADB.
- Setup scripts may print checks and install missing local tooling only when the user runs them directly.

## Development Rules

- Keep changes scoped to the current OpenSpec task.
- Update `openspec/changes/build-local-weekly-check-automation/tasks.md` checkboxes when a task is actually implemented.
- Prefer clear typed models over `any`.
- Avoid global side effects in module top-level code.
- Do not add network calls unless a future integration is explicitly implemented and enabled by config.
- Keep Windows and POSIX path handling in mind, but macOS is the primary runtime target.
