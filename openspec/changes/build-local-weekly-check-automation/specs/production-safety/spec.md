## ADDED Requirements

### Requirement: risk levels

The system SHALL classify scenarios as `READ_ONLY`, `SAFE_WRITE`, or `DESTRUCTIVE`.

#### Scenario: default read-only run

Given a target has READ_ONLY and SAFE_WRITE scenarios
When the user runs `pnpm qa:run --target sample`
Then only READ_ONLY scenarios SHALL run by default.

### Requirement: safe-write opt-in

The system SHALL require an explicit `--allow-safe-write` option to execute SAFE_WRITE scenarios.

#### Scenario: safe-write allowed

Given a target has a SAFE_WRITE scenario
When the user runs `pnpm qa:run --target sample --allow-safe-write`
Then the SAFE_WRITE scenario MAY run.

### Requirement: destructive blocking

The system MUST block DESTRUCTIVE scenarios by default.

#### Scenario: destructive scenario selected

Given a target has a DESTRUCTIVE scenario
When the user runs `pnpm qa:run --target sample`
Then the scenario SHALL be SKIPPED or blocked with a safety error and SHALL NOT execute.

### Requirement: production crawler safety

The crawler MUST NOT perform payments, orders, deletes, account withdrawal, real messages, real email, real push notifications, mass production data creation, or infinite repeat actions.

#### Scenario: delete URL excluded

Given crawler config excludes `/**?delete=*`
When the crawler discovers `/item?id=1&delete=true`
Then the crawler SHALL NOT visit that URL.
