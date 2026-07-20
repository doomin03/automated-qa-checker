## ADDED Requirements

### Requirement: disabled integration defaults

The system SHALL keep n8n, GitLab, PostgreSQL, and Slack integrations disabled by default.

#### Scenario: local run with disabled integrations

Given `configs/integrations.yaml` has all integrations disabled
When a local run completes
Then the system SHALL NOT send results to external network services.

### Requirement: No-op Integration

The system SHALL provide a `NoopIntegration` implementation for the current phase.

#### Scenario: publish methods called

Given a local run starts and completes
When integration publish methods are invoked
Then `NoopIntegration` SHALL complete without network I/O.

### Requirement: future extension interface

The system SHALL define extension points for future n8n webhook, GitLab artifact, PostgreSQL, and Slack integrations without activating them.

#### Scenario: integration config enabled accidentally

Given an integration is enabled in config before its implementation is available
When the config is loaded
Then the system SHALL reject or mark the integration as NOT_IMPLEMENTED instead of silently sending network requests.
