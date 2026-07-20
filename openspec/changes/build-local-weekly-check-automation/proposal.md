# Build Local Weekly Check Automation

## Summary

Create an OpenSpec change for a local QA automation project that checks production web sites and deployed Android, iOS, and LG webOS app artifacts from an internal macOS build machine.

This change defines requirements and architecture only. It does not implement source code, package setup, runners, scripts, CI, or external integrations.

## Motivation

Several production services are currently checked manually every week. The manual process is repetitive, slow, and inconsistent across web, mobile, and TV targets. It also makes it hard to compare failures over time or preserve screenshots, logs, and structured results.

External device farms and paid cloud testing services are out of scope because of cost and operational constraints. The system therefore needs to run locally on an internal macOS build machine using Chromium, Android Emulator, iOS Simulator, connected iPhones, and optional webOS devices.

## Current Scope

The current scope is a local-first QA automation project design:

- YAML-based target registry for web, Android, iOS, and webOS targets
- Local execution only on macOS
- Playwright-based web crawling
- Explicit web scenario validation
- Visual validation for Flutter Web, Canvas, WebGL, game, and image-driven screens
- Appium/WebdriverIO-based mobile black-box validation
- Image and coordinate based interaction
- APK, APP, IPA, and IPK artifact installation or installability checks
- Android Emulator, iOS Simulator, real iPhone, and webOS device discovery and preparation
- Scenario YAML schema and step command model
- Production safety rules
- Local JSON, JUnit XML, HTML, Markdown, screenshot, trace, video, and log reporting
- Local CLI command surface
- No-op integration interface for future automation expansion

## Out Of Scope

This change SHALL NOT implement or activate:

- GitLab Pipeline execution
- GitLab Runner automation
- n8n webhook calls
- PostgreSQL persistence
- Slack or email notifications
- Recurring schedules
- Remote build machine orchestration
- Cloud device farms or paid external services
- Real production crawling during this proposal phase
- Test account login during this proposal phase
- Package, source, runner, CLI, or script implementation

## Impact

The resulting OpenSpec artifacts will give implementation agents a clear contract for building the project without needing to rediscover the target platforms, safety rules, execution boundaries, or result model.

The change affects requirements planning only. Existing source code and package files are not changed.

## Success Criteria

- Proposal, design, tasks, and capability-specific delta specs exist.
- Each capability spec contains SHALL or MUST requirements.
- Each major requirement has at least one verifiable scenario.
- Web crawling, web scripted validation, and web visual validation are separate capabilities.
- Mobile app validation is defined as black-box validation.
- APK, IPA, APP, and IPK behavior is clearly separated.
- IPA plus iOS Simulator is explicitly blocked.
- Production safety rules are explicit.
- Local execution and future integrations are separated.
- PASSED, FAILED, BROKEN, SKIPPED, and NOT_IMPLEMENTED are distinct result states.

## Risks

- Real iPhone IPA installation behavior depends on signing and device trust configuration.
- webOS device automation depth may vary by emulator, TV model, and available tooling.
- Image and coordinate scenarios require maintenance when UI layouts change.
- Production checks must avoid destructive or data-mutating actions by default.
- Appium and platform tooling can create environment failures that must not be reported as product failures.

## Pre-Implementation Checks

- Confirm macOS build machine versions for Node.js, pnpm, Java, Android SDK, Xcode, Appium, and webOS ares CLI.
- Confirm whether real iPhone IPA installation is supported or only existing installed apps can be launched.
- Confirm which production accounts are READ_ONLY-safe.
- Confirm the initial web, Android, iOS, and webOS sample targets.
- Confirm whether HTML or Markdown is the primary human-readable report format.
