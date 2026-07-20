## ADDED Requirements

### Requirement: local-only default execution

The system SHALL run in local execution mode by default on a macOS build machine.

#### Scenario: local run starts

Given integrations are disabled
When the user runs `pnpm qa:run --group weekly`
Then the system SHALL execute targets locally and SHALL NOT call external webhooks, CI APIs, or notification APIs.

### Requirement: sequential execution by default

The system SHALL execute web, Android, iOS, and webOS targets sequentially by default.

#### Scenario: multiple targets run

Given three enabled targets are selected
When the user runs `pnpm qa:run --group weekly`
Then the system SHALL start the next target only after the previous target has completed cleanup.

### Requirement: cleanup after failure

The system MUST run cleanup steps even when a target or scenario fails.

#### Scenario: Appium scenario fails

Given an Appium scenario fails during a step
When the target run ends
Then the Appium session SHALL be terminated and local evidence SHALL be written.
