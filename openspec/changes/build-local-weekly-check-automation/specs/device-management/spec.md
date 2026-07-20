## ADDED Requirements

### Requirement: device discovery

The system SHALL discover configured Android, iOS Simulator, real iPhone, and webOS devices before execution.

#### Scenario: Android device unavailable

Given an Android target requires an emulator profile
When no matching emulator or device is available
Then the target result SHALL be BROKEN.

### Requirement: iOS Simulator preparation

The system SHALL boot or reuse the configured iOS Simulator before APP installation.

#### Scenario: simulator boot fails

Given an iOS Simulator target is selected
When the configured simulator fails to boot
Then the target result SHALL be BROKEN and no scenario steps SHALL run.

### Requirement: real iPhone checks

The system SHALL check real iPhone UDID, trust relationship, developer mode assumptions, and WebDriverAgent readiness before running scenarios.

#### Scenario: iPhone not trusted

Given a real iPhone is connected but not trusted
When the target run starts
Then the system SHALL return BROKEN with a clear device readiness error.

### Requirement: webOS readiness

The system SHALL verify registered webOS target devices before IPK installation.

#### Scenario: webOS target missing

Given a webOS target references an unknown device name
When the target run starts
Then the system SHALL return BROKEN before running `ares-install`.

### Requirement: setup script command blocks

The system SHALL document future `.sh` and `.bat` setup command blocks for Android ADB checks and macOS-only iOS Simulator checks.

#### Scenario: Android setup script checks adb

Given the future Android setup script is executed
When `adb` is available on PATH
Then the script SHALL print `adb version` and `adb devices`.

#### Scenario: Android setup script warns about missing emulator

Given the future Android setup script is executed
When `emulator` is not available on PATH
Then the script SHALL warn that Android Studio or Android SDK emulator is required without reporting Android ADB setup as successful.

#### Scenario: iOS setup script outside macOS

Given the future iOS setup script is executed on a non-macOS machine
When the script checks the operating system
Then the script SHALL fail with a clear macOS-only message before running Xcode or Simulator commands.

#### Scenario: iOS setup script on macOS

Given the future iOS setup script is executed on macOS
When Xcode command line tools are available
Then the script SHALL list available iOS Simulator devices and ensure the Appium XCUITest driver is installed.
