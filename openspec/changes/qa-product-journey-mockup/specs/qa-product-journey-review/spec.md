## ADDED Requirements

### Requirement: Product planning and app responsibilities

The mockup SHALL present Korean planning content linking user requirements to web, Desktop, and independent Engine responsibilities.

#### Scenario: Review the complete user journey
- **WHEN** the reviewer opens the planning view
- **THEN** it shows shared scenario selection, versioned XML handoff, Desktop editing, validation, explicit execution, and result review
- **AND** scheduling and role administration are identified as follow-up planning rather than working mockup integrations

### Requirement: Connected web and Desktop prototype

The mockup SHALL provide clickable web and Desktop screens with consistent example scenario context and a persistent mockup label.

#### Scenario: Receive a shared version
- **WHEN** a user selects a published scenario version and opens it in Desktop
- **THEN** the Desktop project and QA workspace show the selected source version
- **AND** no simulated run begins until validation and explicit execution

#### Scenario: Request execution from the web
- **WHEN** a user submits an example execution request
- **THEN** the web displays request receipt and progress separately from the test outcome
- **AND** it does not report a real backend or Engine connection

### Requirement: Editing and AI approval boundaries

The mockup SHALL provide Flow/XML views, selected-node context, local CLI settings examples, four AI edit scopes, candidate review, explicit apply or cancellation, and undo.

#### Scenario: Apply an example AI candidate
- **WHEN** a user requests and applies a candidate for the current document revision
- **THEN** the preview explains the changed scope and example nature before application
- **AND** applying or undoing invalidates validation without beginning execution

#### Scenario: Refuse stale candidate
- **WHEN** the document or selected-node revision changes after generating a candidate
- **THEN** candidate application is refused until a new candidate is requested

### Requirement: Explicit execution and honest outcomes

The mockup SHALL separate document validation, execution snapshot, test outcome, and workflow progress.

#### Scenario: Run and cancel
- **WHEN** a user explicitly starts a validated example scenario
- **THEN** the run uses a fixed snapshot, locks editing, and shows step progress
- **AND** cancellation retains unexecuted steps as unrun
- **AND** cancellation request remains distinct from terminal cancelled

#### Scenario: Validation fails before execution
- **WHEN** the example document fails validation
- **THEN** the user sees a document error without a new run result
- **AND** changing selection alone preserves document validation while invalidating a pending AI candidate

#### Scenario: Inspect failure or environment error
- **WHEN** a failure or environment-error example completes
- **THEN** its reason and unrun subsequent steps are visible and never presented as PASS

### Requirement: Local review and preserved assets

The mockup SHALL run without external connections, preserve previous mockups and product files, and remain usable at 1440×900 and 1024×768.

#### Scenario: Verify the review artifact
- **WHEN** the local acceptance checks run
- **THEN** they record browser interactions, screenshots, no page errors or external requests, and preserved previous-file hashes
- **AND** results are described as prototype acceptance rather than real product execution evidence
