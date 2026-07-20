## ADDED Requirements

### Requirement: YAML target registry

The system SHALL load test targets from `configs/targets/index.yaml` instead of hardcoding target lists in source code.

#### Scenario: enabled target appears in list

Given `configs/targets/index.yaml` references a valid enabled web target
When the user runs `pnpm qa:list`
Then the target SHALL be displayed with id, name, platform, enabled status, and groups.

#### Scenario: disabled target is hidden by default

Given `configs/targets/index.yaml` references a disabled target
When the user runs `pnpm qa:list`
Then the disabled target SHALL NOT be included in the default list output.

### Requirement: platform-specific target files

The system SHALL support target YAML files under `configs/targets/web/`, `configs/targets/android/`, `configs/targets/ios/`, and `configs/targets/webos/`.

#### Scenario: invalid platform directory

Given a target file declares platform `android` but is registered from `configs/targets/web/`
When the registry is loaded
Then the system SHALL return a configuration validation error before execution.

### Requirement: target filters

The system SHALL filter targets by platform and group.

#### Scenario: group filter

Given multiple enabled targets exist across groups
When the user runs `pnpm qa:list --group weekly`
Then only targets containing the `weekly` group SHALL be displayed.
