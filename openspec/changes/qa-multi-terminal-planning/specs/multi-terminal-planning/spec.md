## ADDED Requirements

### Requirement: Integrated document and terminal workspace
The prototype SHALL preserve home and received-QA journeys and show the D08 terminal dock below the D05 Blueprint or D06 XML editor without replacing the editor with an explanatory overlay.

#### Scenario: Open and hide the terminal
- **WHEN** a user opens the terminal, changes sessions, hides it and restores it
- **THEN** the editor content, selection, pan/zoom or XML scroll and input remain intact, and hiding does not terminate sessions

#### Scenario: Review routes remain isolated
- **WHEN** D05, D06 or D08 is opened from the planning portal
- **THEN** the requested editor/dock state is shown using review storage without overwriting standalone saved work

### Requirement: Explicit session identity and readiness
The prototype SHALL model Claude Code, Codex, PowerShell and command-prompt sessions with fixed project/QA/cwd identity, editable display names, independent input/output and honest readiness and process states.

#### Scenario: Add a provider session
- **WHEN** a user selects a ready example profile or an unconfigured profile
- **THEN** the ready example creates a simulated session, while the other explains setup needs without claiming an installed or running CLI

#### Scenario: Change document
- **WHEN** a user changes project or QA with existing sessions
- **THEN** those sessions retain their original identity and cannot apply to the newly selected document

#### Scenario: Close versus terminate
- **WHEN** a user closes a menu with Escape or hides the dock
- **THEN** no process termination or interrupt is implied
- **AND** explicit termination distinguishes cleanup in progress, exited and cleanup unknown

### Requirement: Single writer and validation boundaries
The prototype SHALL allow at most one automatic writer per QA and require example Engine validation plus matching session/document/revision/hash and execution guards before draft application.

#### Scenario: Approved automatic writer
- **WHEN** the selected writer produces a valid example candidate with matching identity and no active QA run
- **THEN** the draft may update in automatic mode, while persistence and QA execution require separate actions

#### Scenario: Stale or invalid candidate
- **WHEN** validation fails, another session proposes a change, the base revision/hash changes, the document changes or a QA run is active
- **THEN** the current draft and last valid graph remain unchanged and the candidate stays in a copy/review or deferred state

#### Scenario: Unknown writer cleanup
- **WHEN** the writer terminates but cleanup is unconfirmed
- **THEN** the UI prevents silently assigning another writer until cleanup is explicitly resolved

#### Scenario: Regranting writer ownership
- **WHEN** a candidate was prepared before writer ownership was transferred or revoked and the original session later becomes writer again
- **THEN** the old candidate remains ineligible through its writer epoch and a newly prepared candidate is required

### Requirement: Accessible adaptable dock controls
The prototype SHALL support bounded pointer and keyboard resize, collapse/restore, enlarge/restore and two-session horizontal split without losing editor or session state.

#### Scenario: Narrow window
- **WHEN** two panes cannot retain their minimum width
- **THEN** the dock uses selected-session tabs and restores the preferred split after widening

#### Scenario: Keyboard and focus
- **WHEN** a user resizes with keys, edits a session name, submits example input or dismisses a menu
- **THEN** visible focus, input selection and appropriate scroll are preserved without unexpected editor rerenders or focus theft

#### Scenario: Reduced motion
- **WHEN** reduced motion is requested or a splitter is being dragged
- **THEN** panel movement is immediate and does not delay pointer or text input

### Requirement: Honest planning evidence
The planning artifact SHALL separate current single-Codex product implementation from proposed multi-provider UX, and terminal lifecycle from Engine validation/run outcomes and business state.

#### Scenario: Inspect scope and evidence
- **WHEN** a reviewer opens the D08 specification or usage guide
- **THEN** current support, proposed controls, example-only behavior, Engine/Checker ownership and remaining actual product acceptance are distinguishable

#### Scenario: Acceptance review
- **WHEN** the change is reported complete
- **THEN** focused interaction checks, existing home/editor/portal regressions, 1440/1024 visual review, counterpart feedback and strict/repository checks are recorded without claiming actual CLI execution
