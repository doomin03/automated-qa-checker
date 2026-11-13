## ADDED Requirements

### Requirement: Recoverable provider readiness
Desktop SHALL provide explicit executable selection, local path preferences, bounded reinspection, and official installation guidance without automatically installing software or storing credentials.

#### Scenario: Missing provider
- **WHEN** Claude or Codex is not found
- **THEN** the user can select an existing executable or copy official setup guidance and retry, while start remains unavailable until inspection passes
- **AND** the app does not execute an installer or imply login/model readiness

#### Scenario: Remembered path changes
- **WHEN** a remembered executable disappears or a delayed inspection finishes after the provider/path changes
- **THEN** the old result cannot enable the new selection and the persisted path is revalidated before start

#### Scenario: Preference persistence fails
- **WHEN** atomic preference save fails or the stored document is invalid
- **THEN** the existing bytes remain intact and the UI reports the failure without inventing successful persistence

### Requirement: Session-bound authoring guidance
Desktop SHALL expose the prepared authoring guide and versioned context for the selected session and distinguish file preparation from observed CLI discovery and model usage.

#### Scenario: Guide ready only
- **WHEN** SKILL.md and environment manifests exist with valid hashes
- **THEN** the UI reports prepared files and does not claim that the provider discovered or used them

#### Scenario: Delayed context delivery
- **WHEN** clipboard or context preparation awaits while session identity/input epoch changes
- **THEN** no prepared text is delivered to the newly selected session and no Enter or QA execution is synthesized

### Requirement: Actual interactive authoring acceptance
Desktop SHALL retain a traceable boundary from interactive AI file edits through public Engine validation and GUI state to explicit execution, without treating fixture edits as actual model output.

#### Scenario: Valid XML and JSON edits
- **WHEN** an installed authenticated provider edits each supported format in separate isolated QA sessions
- **THEN** file hashes, validated snapshot, GUI changes, explicit run events/result and evidence are matched to the same QA
- **AND** file receipt/validation alone causes zero QA runs

#### Scenario: Invalid or stale model output
- **WHEN** output is invalid, conflicts with GUI changes, or belongs to an earlier writer/QA/mode epoch
- **THEN** the last valid graph and unrelated sourceMap/results remain intact and the unresolved state is visible

#### Scenario: Provider unavailable
- **WHEN** installation, account, quota, trust scope or network prevents actual editing
- **THEN** the exact unverified stage remains incomplete and preparation/fixture successes are recorded separately

### Requirement: Accessible terminal interaction
Desktop SHALL preserve the existing canvas and session state while readiness guidance is used at small viewport/large text and with terminal keyboard or IME focus.

#### Scenario: Small viewport and IME
- **WHEN** the user accesses setup at 800×600/text1.5 and types composed Korean text or Ctrl+C/Delete in the terminal
- **THEN** relevant controls remain reachable and terminal input does not mutate canvas nodes or redirect to another session

### Requirement: Evidence-based legacy task reconciliation
Checker SHALL map old terminal task conditions to actual later evidence, preserve failure history and distinguish superseded release plans from releases that were built.

#### Scenario: Partial task coverage
- **WHEN** later tests cover only part of an old task, such as Codex startup without file editing
- **THEN** the task remains incomplete with the missing condition listed rather than being checked from a broader feature claim
