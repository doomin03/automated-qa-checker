# Tasks

## 1. Project Foundation

- [x] Create the TypeScript project skeleton without enabling external integrations.
- [x] Configure strict TypeScript settings.
- [x] Configure pnpm scripts for local-only commands.
- [x] Add the recommended folders for configs, binaries, tests, src, outputs, scripts, docs, and future integration notes.
- [x] Add documented setup script templates for `scripts/setup-local.sh` and `scripts/setup-local.bat`.
- [x] Add documented Android ADB setup command blocks for `scripts/android/setup-adb.sh` and `scripts/android/setup-adb.bat`.
- [x] Add documented macOS-only iOS Simulator setup command blocks for `scripts/ios/setup-simulator.sh` and `scripts/ios/check-simulator.sh`.

## 2. Result Model

- [x] Define `PASSED`, `FAILED`, `BROKEN`, `SKIPPED`, and `NOT_IMPLEMENTED` statuses.
- [x] Define run, target, scenario, step, evidence, and error result models.
- [x] Ensure product failures and automation infrastructure failures can be represented separately.

## 3. Configuration Schemas

- [x] Define Zod schemas for target registry files.
- [x] Define Zod schemas for web, Android, iOS, and webOS target files.
- [x] Define Zod schemas for crawler config.
- [x] Define Zod schemas for device profiles.
- [x] Define Zod schemas for integrations config with all integrations disabled by default.

## 4. Target Registry

- [x] Load `configs/targets/index.yaml`.
- [x] Resolve listed target YAML paths.
- [x] Filter disabled targets by default.
- [x] Support platform and group filtering.
- [x] Return clear validation errors for missing or invalid target files.

## 5. Device Profiles

- [x] Load web viewport profiles.
- [x] Load Android Emulator and device profiles.
- [x] Load iOS Simulator and real iPhone profiles.
- [x] Load webOS device profiles.
- [x] Validate locale, timezone, OS, viewport, and platform compatibility fields.

## 6. Scenario Definition

- [x] Define YAML scenario schema with id, name, tags, risk level, variables, and steps.
- [ ] Validate scenario paths referenced by targets.
- [x] Validate supported step commands.
- [ ] Resolve variables from environment without exposing secret values.
- [x] Reject malformed YAML before execution.

## 7. Local CLI

- [x] Implement `qa:list` with platform and group filters.
- [ ] Implement `qa:doctor`.
- [ ] Implement `qa:devices`.
- [ ] Implement `qa:crawl`.
- [ ] Implement `qa:discover`.
- [ ] Implement `qa:scenario`.
- [ ] Implement `qa:run` for target, group, all, and scenario filters.
- [ ] Implement `qa:capture`.
- [ ] Implement `qa:coordinate`.
- [ ] Implement `qa:report`.

## 8. Web Crawling

- [ ] Implement Playwright Chromium crawler.
- [ ] Enforce same-origin scope by default.
- [ ] Apply include and exclude URL rules.
- [ ] Normalize URLs, query strings, fragments, and duplicate slashes.
- [ ] Enforce max depth, max pages, per-page timeout, and total timeout.
- [ ] Check HTTP status, broken links, images, console errors, page errors, network failures, title, empty body, and loading timeout.
- [ ] Capture failure screenshots and traces.

## 9. Web Scripted Validation

- [ ] Implement DOM-oriented web scenario runner.
- [ ] Support role, text, label, CSS, XPath, image, percent coordinate, and absolute coordinate selectors.
- [ ] Require post-action assertions for success.
- [ ] Capture screenshots, traces, console logs, and network errors on failure.

## 10. Visual Engine

- [ ] Implement screenshot capture abstraction.
- [ ] Implement image matching result model.
- [ ] Implement image comparison threshold handling.
- [ ] Implement percent coordinate conversion.
- [ ] Implement anchor-image relative coordinate taps.
- [ ] Keep absolute coordinate taps as the final fallback.

## 11. Appium Common Runner

- [ ] Implement common Appium/WebdriverIO session lifecycle.
- [ ] Ensure sessions are always cleaned up in finalization.
- [ ] Share scenario step execution where possible.
- [ ] Capture screenshots and platform logs on failure.

## 12. Android Adapter

- [ ] Discover Android Emulator and connected Android devices.
- [ ] Start emulator when configured.
- [ ] Wait for boot completion.
- [ ] Validate APK paths before execution.
- [ ] Install, reset, or reinstall apps according to target config.
- [ ] Run scenarios with UiAutomator2.
- [ ] Capture logcat on failure.

## 13. iOS Simulator Adapter

- [ ] Discover configured iOS Simulator.
- [ ] Boot simulator when needed.
- [ ] Validate APP artifacts.
- [ ] Block IPA plus iOS Simulator before execution.
- [ ] Install APP with `xcrun simctl`.
- [ ] Run scenarios with XCUITest.

## 14. Real iPhone Adapter

- [ ] Detect connected iPhone UDID.
- [ ] Validate trust and developer mode assumptions.
- [ ] Check WebDriverAgent readiness.
- [ ] Launch installed app by bundle id.
- [ ] Abstract IPA installation behind an adapter.
- [ ] Return BROKEN with `IOS_IPA_INSTALLATION_NOT_CONFIGURED` when automatic IPA installation is unavailable.

## 15. webOS Adapter

- [ ] Check ares CLI availability.
- [ ] Discover configured webOS emulator or TV.
- [ ] Validate IPK path.
- [ ] Install IPK with `ares-install`.
- [ ] Launch app with `ares-launch`.
- [ ] Return NOT_IMPLEMENTED for unsupported screen automation.

## 16. Artifact Installation

- [ ] Validate APK compatibility with Android targets.
- [ ] Validate APP compatibility with iOS Simulator targets.
- [ ] Validate IPA compatibility with real iPhone targets only.
- [ ] Validate IPK compatibility with webOS targets.
- [ ] Fail before execution for missing binary paths.

## 17. Reporting

- [ ] Write `run-summary.json`.
- [ ] Write target summary JSON.
- [ ] Write scenario result JSON.
- [ ] Write JUnit XML.
- [ ] Write HTML report or Markdown report.
- [ ] Store screenshots, traces, videos, device logs, console logs, and network errors under the run folder.
- [ ] Redact secrets from all report output.

## 18. Production Safety

- [ ] Enforce READ_ONLY as the default allowed risk level.
- [ ] Require `--allow-safe-write` for SAFE_WRITE scenarios.
- [ ] Block DESTRUCTIVE scenarios by default.
- [ ] Stop risky follow-up actions after a failed validation.
- [ ] Prevent crawler form submits, arbitrary button clicks, downloads, payments, orders, deletes, logout, and external domain navigation by default.

## 19. No-op Integration

- [x] Define `TestResultIntegration`.
- [x] Implement `NoopIntegration`.
- [ ] Load `configs/integrations.yaml` with all integrations disabled by default.
- [ ] Ensure local runs do not send external network requests when integrations are disabled.

## 20. Documentation And Samples

- [ ] Document architecture.
- [ ] Document how to add targets.
- [ ] Document how to write scenarios.
- [ ] Document web crawling behavior.
- [x] Document local macOS setup.
- [ ] Document future n8n and GitLab integration direction.
- [ ] Add sample targets and sample scenarios after implementation begins.

## 21. Verification

- [ ] Type check the implementation.
- [ ] Validate malformed YAML behavior.
- [ ] Validate missing binary behavior.
- [ ] Validate IPA plus iOS Simulator blocking.
- [ ] Validate FAILED and BROKEN separation.
- [ ] Validate local-only integration behavior.
- [ ] Validate report generation from a local sample run.
- [ ] Validate Android setup scripts detect `adb`, list connected devices, and warn when `emulator` is unavailable.
- [ ] Validate iOS setup scripts fail clearly outside macOS and list available simulators on macOS.
