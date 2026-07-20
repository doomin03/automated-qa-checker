# Technical Decisions

## Decision 1: Web Crawling Uses Playwright

Web crawling SHALL use Playwright with Chromium as the default browser engine. WebKit can be added later when a target requires Safari-like behavior.

Reason: Playwright provides reliable navigation, request, console, screenshot, and trace APIs for production web health checks.

## Decision 2: Web Crawling And Web Scenarios Are Separate

CRAWL, SCENARIO, and VISUAL checks SHALL remain separate web check types.

Reason: crawling is broad and safety-constrained, while scenarios are explicit user flows and visual checks are needed for Canvas, Flutter Web, WebGL, and game screens.

## Decision 3: Mobile Apps Are Black-Box Targets

Mobile validation SHALL treat APK, IPA, APP, and IPK artifacts as deployed black-box applications.

Reason: the automation system cannot assume source access, Flutter keys, React test IDs, Vue test IDs, Android resource IDs, iOS accessibility identifiers, test builds, internal APIs, or test hooks.

## Decision 4: Appium Is The Mobile Automation Base

Android and iOS automation SHALL use Appium and WebdriverIO. Android SHALL use UiAutomator2. iOS SHALL use XCUITest.

Reason: this gives one cross-platform automation model while preserving platform-specific adapters.

## Decision 5: Artifact Compatibility Is Validated Before Execution

APK, APP, IPA, and IPK compatibility SHALL be validated before installation, launch, or scenario execution.

Reason: invalid combinations are environment/configuration failures, not product failures. In particular, IPA plus iOS Simulator is blocked.

## Decision 6: Local Execution Is The Current Boundary

The current implementation SHALL be local-only. n8n, GitLab, PostgreSQL, Slack, scheduling, and remote execution remain future integrations behind No-op Integration.

Reason: the requested project must run on an internal macOS build machine and must not create external network side effects in the current phase.

## Decision 7: Parallel Execution Is Disabled By Default

Targets SHALL execute sequentially by default.

Reason: mobile simulators, real devices, Appium sessions, and webOS tooling are prone to resource contention during early implementation.

## Decision 8: Result Statuses Separate Product And Infrastructure Failures

The result model SHALL distinguish `FAILED` from `BROKEN`.

Reason: a production page bug and a missing emulator are different problems and must be reported differently.
