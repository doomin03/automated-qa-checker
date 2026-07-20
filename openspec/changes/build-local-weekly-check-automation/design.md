# Design

## Goals

Design a TypeScript-based local QA automation system that runs weekly production smoke checks for web sites and deployed app artifacts from an internal macOS build machine.

The design keeps implementation local-only for the current phase and leaves future GitLab, n8n, PostgreSQL, and Slack integrations behind disabled adapters.

## Architecture Overview

The system is organized around these modules:

- `config`: loads and validates YAML configuration with Zod.
- `core`: owns run context, target result, scenario result, statuses, and shared errors.
- `cli`: exposes local commands such as `qa:list`, `qa:run`, `qa:doctor`, and `qa:report`.
- `crawler`: performs Playwright crawling for web targets.
- `runners`: runs web, Android, iOS, and webOS checks through platform-specific adapters.
- `devices`: discovers and prepares Android Emulator, iOS Simulator, real iPhone, and webOS devices.
- `artifacts`: validates and installs APK, APP, IPA, and IPK artifacts where supported.
- `visual`: performs image matching, screenshot comparison, and coordinate conversion.
- `reports`: writes local JSON, JUnit XML, HTML or Markdown reports, logs, screenshots, traces, and videos.
- `integrations`: exposes a disabled-by-default integration interface with a No-op implementation.

## Target Registry

Targets are configured through `configs/targets/`.

`configs/targets/index.yaml` is the single entry point for enabled target files. Target files are grouped by platform:

- `configs/targets/web/`
- `configs/targets/android/`
- `configs/targets/ios/`
- `configs/targets/webos/`

Target YAML includes id, name, enabled flag, platform, execution mode, production environment marker, device profile, group tags, evidence settings, and scenario paths. App targets also include artifact information and app identifiers.

## Crawler Config

Web crawler configuration lives in `configs/crawlers/`.

Crawler config defines start URLs, same-origin scope, max depth, max pages, timeouts, include and exclude patterns, discovery behavior, basic checks, and safety rules. The crawler does not click arbitrary buttons, submit forms, trigger downloads, execute payment/order/delete flows, or explore API endpoints directly.

## Scenario Runner

Scenarios are YAML files under `tests/scenarios/`.

Scenarios contain id, name, tags, risk level, variables, and ordered steps. Steps are validated before execution. A step click or input action is not considered successful until the scenario verifies the expected next state with text, accessibility, image, URL, process, loading, popup, or network assertions.

## Platform Runner Abstraction

Each runner implements a common lifecycle:

1. Load and validate target and device profile.
2. Prepare device or browser session.
3. Validate artifact compatibility.
4. Execute crawl, scripted, or visual checks.
5. Write evidence on failure.
6. Clean up browser or device sessions even after failures.
7. Return a normalized target result.

Web uses Playwright. Android and iOS use Appium and WebdriverIO. webOS uses ares CLI for installation and launch, with unsupported screen automation surfaced as NOT_IMPLEMENTED.

## Device Manager

Device profiles live in `configs/devices/`.

The device manager discovers:

- Chromium browser profiles for web
- Android Emulator and connected Android devices
- iOS Simulator devices
- Connected real iPhones
- Registered webOS emulator or TV devices

Missing tooling, unavailable devices, invalid UDIDs, trust issues, and boot failures are reported as BROKEN, not FAILED.

## Local Setup Script Command Blocks

The implementation SHALL document and later provide setup scripts under `scripts/` without running them automatically during normal QA runs.

Recommended script layout:

- `scripts/setup-local.sh`: macOS local setup entry point
- `scripts/setup-local.bat`: Windows/PowerShell-friendly Android setup helper and iOS unsupported notice
- `scripts/android/setup-adb.sh`
- `scripts/android/setup-adb.bat`
- `scripts/ios/setup-simulator.sh`
- `scripts/ios/check-simulator.sh`

The `.sh` scripts are the primary path because the target build machine is macOS. The `.bat` scripts exist only as helper documentation for Android/ADB setup on Windows developer machines. iOS Simulator setup MUST be marked macOS-only.

### `scripts/setup-local.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[setup] local QA environment"

if ! command -v brew >/dev/null 2>&1; then
  echo "[error] Homebrew is required on macOS: https://brew.sh"
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  brew install node
fi

if ! command -v pnpm >/dev/null 2>&1; then
  corepack enable
  corepack prepare pnpm@latest --activate
fi

"$ROOT_DIR/scripts/android/setup-adb.sh"
"$ROOT_DIR/scripts/ios/setup-simulator.sh"

echo "[setup] done"
```

### `scripts/setup-local.bat`

```bat
@echo off
setlocal

echo [setup] local QA helper for Windows
echo [setup] Android ADB checks can run on Windows.
echo [setup] iOS Simulator setup is macOS-only and is intentionally skipped.

call "%~dp0android\setup-adb.bat"

where node >nul 2>nul
if errorlevel 1 (
  echo [warn] Node.js is not installed or not on PATH.
) else (
  node --version
)

where pnpm >nul 2>nul
if errorlevel 1 (
  echo [warn] pnpm is not installed or not on PATH. Run: corepack enable
) else (
  pnpm --version
)

echo [setup] done
endlocal
```

### `scripts/android/setup-adb.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "[android] checking Android SDK and ADB"

if ! command -v adb >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    brew install --cask android-platform-tools
  else
    echo "[error] adb not found. Install Android SDK platform-tools and add adb to PATH."
    exit 1
  fi
fi

adb version
adb devices

if command -v emulator >/dev/null 2>&1; then
  emulator -list-avds || true
else
  echo "[warn] Android emulator command not found. Install Android Studio or Android SDK emulator."
fi
```

### `scripts/android/setup-adb.bat`

```bat
@echo off
setlocal

echo [android] checking ADB

where adb >nul 2>nul
if errorlevel 1 (
  echo [error] adb not found. Install Android SDK platform-tools and add it to PATH.
  exit /b 1
)

adb version
adb devices

where emulator >nul 2>nul
if errorlevel 1 (
  echo [warn] emulator command not found. Install Android Studio or Android SDK emulator.
) else (
  emulator -list-avds
)

endlocal
```

### `scripts/ios/setup-simulator.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "[ios] checking Xcode and iOS Simulator"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[error] iOS Simulator setup requires macOS."
  exit 1
fi

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "[error] Xcode command line tools are required."
  exit 1
fi

sudo xcodebuild -license accept || true
xcode-select -p
xcrun simctl list devices available

if ! command -v appium >/dev/null 2>&1; then
  npm install -g appium
fi

appium driver list --installed | grep -q xcuitest || appium driver install xcuitest

echo "[ios] available runtimes"
xcrun simctl list runtimes available
```

### `scripts/ios/check-simulator.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

DEVICE_NAME="${1:-iPhone 15}"

echo "[ios] checking simulator: ${DEVICE_NAME}"

UDID="$(xcrun simctl list devices available | awk -v name="$DEVICE_NAME" '$0 ~ name && $0 ~ /Booted|Shutdown/ { gsub(/[()]/, "", $NF); print $NF; exit }')"

if [[ -z "${UDID}" ]]; then
  echo "[error] simulator not found: ${DEVICE_NAME}"
  exit 1
fi

xcrun simctl boot "$UDID" || true
xcrun simctl bootstatus "$UDID" -b
xcrun simctl list devices | grep "$UDID"
```

These command blocks are reference requirements for later implementation. They MUST NOT be executed during OpenSpec proposal creation.

## Artifact Installer

Artifact handling is platform-specific:

- APK is supported on Android Emulator and real Android devices.
- APP is supported on iOS Simulator.
- IPA is supported on real iPhone only.
- IPA plus iOS Simulator is blocked before execution.
- IPK is supported on webOS emulator or real webOS TV where ares CLI is configured.

IPA installation is adapter-based because signing and distribution behavior vary. If automatic installation is not configured, the system reports BROKEN with `IOS_IPA_INSTALLATION_NOT_CONFIGURED`.

## Visual Engine

The visual engine supports image matching, screenshot comparison, crop extraction, percent coordinate conversion, absolute coordinate fallback, and relative coordinate taps from matched anchor images.

Element discovery priority for black-box app scenarios is:

1. Screen text
2. Accessibility information
3. Baseline image
4. Relative coordinates from a baseline image
5. Percent coordinates based on screen size
6. Absolute pixel coordinates

Absolute pixel coordinates are the final fallback.

## Result Reporter

Results are written only to local files under `outputs/runs/{runId}/`.

Supported outputs:

- `run-summary.json`
- `junit.xml`
- `report.html`
- `report.md`
- target summaries
- scenario summaries
- screenshots
- traces
- videos
- browser console logs
- network errors
- device logs such as logcat

Result statuses are:

- `PASSED`: expected product behavior was observed.
- `FAILED`: product behavior differs from expected behavior.
- `BROKEN`: automation, device, environment, binary, or configuration failure.
- `SKIPPED`: excluded by configuration or precondition.
- `NOT_IMPLEMENTED`: requested feature is known but unsupported by the current runner.

## Integration Model

Current execution mode is local only.

The integration interface is:

```ts
interface TestResultIntegration {
  publishRunStarted(context: RunContext): Promise<void>;
  publishRunCompleted(result: RunResult): Promise<void>;
  publishTargetCompleted(result: TargetResult): Promise<void>;
}
```

The current implementation is `NoopIntegration`. n8n, GitLab, PostgreSQL, and Slack integrations are future extension points and must remain disabled in the current phase.

## Local Execution Flow

1. CLI receives target, group, or all-target request.
2. Config loader validates target registry, device profiles, scenarios, and crawler config.
3. Production safety filter allows READ_ONLY scenarios by default.
4. Targets run sequentially by default.
5. Each runner prepares its environment and executes checks.
6. Failures capture evidence immediately.
7. Cleanup runs even after failure.
8. Local reports are written.
9. No external webhooks or APIs are called.

## Web Crawling Flow

1. Open Chromium with Playwright.
2. Visit configured start URLs.
3. Stay within the allowed origin and include/exclude rules.
4. Normalize URLs to prevent repeat loops.
5. Check HTTP status, broken links, broken images, console errors, page errors, failed network requests, title, empty body, and loading timeout.
6. Capture failure screenshots and traces.

## Android Flow

1. Discover Android Emulator or connected device.
2. Start emulator when configured and wait for boot.
3. Validate APK path.
4. Install or reset app according to target config.
5. Start Appium UiAutomator2 session.
6. Execute scenario steps.
7. Capture screenshot and logcat on failure.
8. End Appium session in cleanup.

## iOS Simulator Flow

1. Discover or boot configured iOS Simulator.
2. Validate artifact type is APP.
3. Block IPA for simulator targets.
4. Install APP with `xcrun simctl`.
5. Start Appium XCUITest session.
6. Execute scenario steps.
7. Capture evidence on failure.
8. End session and cleanup.

## Real iPhone Flow

1. Detect connected iPhone and UDID.
2. Validate trust and developer mode.
3. Check WebDriverAgent availability.
4. Validate artifact type is IPA or launch existing installed bundle.
5. Use IPA installer adapter if configured.
6. Report BROKEN if IPA installation is not configured.
7. Start Appium XCUITest session.
8. Execute scenarios and cleanup.

## webOS Flow

1. Check ares CLI availability.
2. Discover configured webOS emulator or TV.
3. Validate IPK path.
4. Install with `ares-install`.
5. Launch with `ares-launch`.
6. Report launch result.
7. Return NOT_IMPLEMENTED for unsupported screen automation instead of marking success.

## Production Safety

All production checks default to READ_ONLY. SAFE_WRITE requires an explicit CLI flag. DESTRUCTIVE scenarios are blocked by default.

Secrets are loaded from environment variables and are redacted from logs, reports, errors, and screenshots metadata.

After a failed validation, the runner stops risky follow-up clicks and records evidence immediately.

## Architecture Decisions

- Web checks use Playwright crawling as the default.
- Web crawling, scripted validation, and visual validation are separate modes.
- Flutter Web, Canvas, WebGL, and game screens use Visual Mode.
- Mobile checks are Appium-based black-box tests.
- Element discovery prioritizes text, accessibility, images, relative coordinates, percent coordinates, then absolute coordinates.
- Test targets are managed through YAML registry files.
- Current execution is local-only.
- n8n and GitLab are future integrations behind No-op Integration.
- Parallel execution is disabled by default.

## Open Questions

- Which initial production targets should be used as samples?
- Should the first human-readable report be HTML, Markdown, or both?
- Which real iPhone IPA installation method is available on the build machine?
- Which webOS target will be used for first verification?

## Trade-Offs

- Image and coordinate testing works for black-box targets but needs baseline maintenance.
- Local macOS execution avoids external cost but depends heavily on installed platform tools.
- Sequential execution is slower but reduces device/session conflicts for the initial version.
- No-op integration keeps current runs safe but requires later work for CI and notifications.
