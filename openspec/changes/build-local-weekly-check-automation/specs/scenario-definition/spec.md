## ADDED Requirements

### Requirement: YAML scenario format

The system SHALL define scenarios as human-readable YAML files with id, name, tags, riskLevel, variables, and steps.

#### Scenario: valid scenario loads

Given a target references a valid scenario YAML
When the configuration loader validates the target
Then the scenario SHALL be accepted and associated with that target.

### Requirement: supported step commands

The system SHALL validate common, coordinate, input, image, web, and accessibility-assisted step commands before execution.

#### Scenario: unknown step command

Given a scenario contains step type `tapMagicButton`
When the scenario is validated
Then the system SHALL return a validation error before execution.

### Requirement: secret variables

The system SHALL resolve secret variables from environment variables without printing raw secret values in logs or reports.

#### Scenario: password variable missing

Given a scenario variable references `SAMPLE_TEST_PASSWORD`
And the environment variable is missing
When the scenario is validated
Then the system SHALL return a clear configuration error without exposing any secret value.

### Requirement: post-action state checks

The system MUST support assertions for text visibility, image visibility, image disappearance, URL change, app process status, loading completion, popup absence, and network error absence.

#### Scenario: expected image missing

Given a scenario expects a home header image
When the image is not found within the configured timeout
Then the step SHALL fail and store evidence.
