## ADDED Requirements

### Requirement: black-box mobile validation

The system SHALL validate deployed app artifacts as black-box applications without assuming source code access or test-only identifiers.

#### Scenario: no test id exists

Given an Android APK exposes no test IDs
When a scenario needs to tap the login button
Then the runner SHALL use available text, accessibility, image, or coordinate strategies instead of requiring a test ID.

### Requirement: Appium-based mobile runners

The system SHALL use Appium and WebdriverIO with UiAutomator2 for Android and XCUITest for iOS.

#### Scenario: Android scenario starts

Given a valid Android APK target and prepared Android device
When the scenario starts
Then the runner SHALL create an Appium UiAutomator2 session.

### Requirement: app crash detection

The mobile runner SHALL distinguish app crash or process termination from successful completion.

#### Scenario: app terminates unexpectedly

Given a scenario is running
When the app process terminates unexpectedly
Then the scenario SHALL fail and capture screenshot or platform logs when available.
