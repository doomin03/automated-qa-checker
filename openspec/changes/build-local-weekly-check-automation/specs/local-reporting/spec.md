## ADDED Requirements

### Requirement: local result storage

The system SHALL store all results under `outputs/runs/{runId}/`.

#### Scenario: run completes

Given a local run completes
When reporting starts
Then the system SHALL create a run folder containing `run-summary.json`.

### Requirement: report formats

The system SHALL support JSON, JUnit XML, and at least one human-readable HTML or Markdown report.

#### Scenario: JUnit report generated

Given a run has target and scenario results
When reporting completes
Then `junit.xml` SHALL represent passed, failed, broken, skipped, and not implemented results.

### Requirement: failure evidence

The system SHALL store failure evidence including screenshots, logs, traces, videos, console logs, network errors, or platform logs when available.

#### Scenario: Android failure

Given an Android scenario fails
When reporting completes
Then the target folder SHALL contain screenshot evidence and logcat output when available.

### Requirement: secret redaction

The system MUST redact secrets from local reports and logs.

#### Scenario: password input fails

Given a scenario uses a password variable
When the password step fails
Then the report SHALL NOT contain the raw password value.
