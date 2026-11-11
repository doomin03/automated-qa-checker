## ADDED Requirements

### Requirement: Published schedule snapshots and authorization
The Checker SHALL create schedules from exactly one published Blueprint version or published Suite version and SHALL freeze the normalized ordered case snapshots, exact hashes, execution policy and canonical resource key. Reading SHALL require project viewer membership and creating, disabling or cancelling SHALL require qa_tester membership.

#### Scenario: Published pin changes after scheduling
- **WHEN** a different Registry version is later published or selected
- **THEN** the existing schedule keeps its original case snapshot hashes and suite policy

#### Scenario: Cross project scheduling
- **WHEN** a caller references a version or schedule outside the authorized project
- **THEN** the operation is rejected without queue mutation

### Requirement: Timezone occurrence uniqueness and DST handling
The scheduler SHALL interpret ISO weekdays and local HH:mm in the configured IANA timezone. A nonexistent DST local time SHALL create a missed occurrence and SHALL NOT shift execution. An overlapping time SHALL select only the earlier UTC instant. Schedule identity and normalized occurrence time SHALL be unique in persistent storage.

#### Scenario: Repeated tick and restart
- **WHEN** two ticks and a server restart scan the same due occurrence
- **THEN** exactly one execution job exists and an Agent executes that job at most once

#### Scenario: DST transitions
- **WHEN** a weekly time falls in a timezone gap or overlap
- **THEN** the gap is missed with dst_nonexistent_time and the overlap creates one occurrence at the earlier instant

### Requirement: Bounded catch-up and explicit missed reasons
The scheduler SHALL persist a scan cursor, catch up individual occurrences for at most seven days, and audit any older skipped interval. Occurrences past their deadline SHALL be missed. A queued occurrence that cannot acquire an eligible Agent or resource before its deadline SHALL be distinguished from an Engine failed assertion.

#### Scenario: No Agent before deadline
- **WHEN** an occurrence remains queued past its deadline
- **THEN** it becomes missed with no_eligible_agent_or_resource and has no fabricated Engine result

### Requirement: Disabling and cancellation preserve resource ownership
Disabling a schedule SHALL cancel queued executions and request cancellation of claimed executions. A claimed resource SHALL remain held until the existing lease cleanup and evidence requirements close it. Re-enabling SHALL not execute the disabled interval retroactively.

#### Scenario: Disable during execution
- **WHEN** an authorized tester disables a schedule with a claimed job
- **THEN** heartbeat reports cancellation and the resource remains fenced until confirmed completion
