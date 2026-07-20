## ADDED Requirements

### Requirement: artifact compatibility

The system SHALL validate artifact type compatibility before device installation or launch.

#### Scenario: IPA with simulator

Given an iOS target uses artifact type `ipa`
And its device profile is `ios-simulator`
When the target is validated
Then the system SHALL block execution before installation.

### Requirement: Android APK support

The system SHALL support APK installation for Android Emulator and real Android devices.

#### Scenario: missing APK

Given an Android target references a missing APK path
When the target run starts
Then the system SHALL return BROKEN before creating an Appium session.

### Requirement: iOS artifact support

The system SHALL support APP artifacts for iOS Simulator and IPA artifacts for real iPhone targets.

#### Scenario: real iPhone IPA installer missing

Given a real iPhone target references an IPA
And automatic IPA installation is not configured
When the target run starts
Then the system SHALL return BROKEN with `IOS_IPA_INSTALLATION_NOT_CONFIGURED`.

### Requirement: webOS IPK support

The system SHALL support IPK installation through configured webOS tooling.

#### Scenario: ares CLI missing

Given a webOS target references an IPK
And ares CLI is not installed
When the target run starts
Then the system SHALL return BROKEN before installation.
