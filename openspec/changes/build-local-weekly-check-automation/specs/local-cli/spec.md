## ADDED Requirements

### Requirement: target listing command

The system SHALL provide `pnpm qa:list` with optional `--platform` and `--group` filters.

#### Scenario: platform list

Given enabled web and Android targets exist
When the user runs `pnpm qa:list --platform web`
Then only web targets SHALL be listed.

### Requirement: doctor command

The system SHALL provide `pnpm qa:doctor` to check local dependencies and configuration.

#### Scenario: missing Xcode

Given an iOS target is configured
And Xcode tooling is unavailable
When the user runs `pnpm qa:doctor`
Then the doctor result SHALL report the iOS tooling issue.

#### Scenario: setup scripts are referenced

Given `qa:doctor` reports missing Android or iOS local tooling
When the user reads the doctor output
Then the output SHALL reference the relevant setup script path such as `scripts/android/setup-adb.sh` or `scripts/ios/setup-simulator.sh`.

### Requirement: execution commands

The system SHALL provide `qa:crawl`, `qa:discover`, `qa:scenario`, `qa:run`, `qa:capture`, `qa:coordinate`, and `qa:report`.

#### Scenario: run single scenario

Given target `sample-web` references scenario `sample.web.login`
When the user runs `pnpm qa:run --target sample-web --scenario sample.web.login`
Then only the selected scenario SHALL run for that target.

### Requirement: coordinate command

The system SHALL provide a coordinate conversion command for target device profiles.

#### Scenario: convert coordinate

Given target `sample-android` has a `1080x2400` device profile
When the user runs `pnpm qa:coordinate --target sample-android --x 540 --y 1800`
Then the command SHALL output the equivalent percent coordinate.
