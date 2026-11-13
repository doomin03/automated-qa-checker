## ADDED Requirements

### Requirement: Discover published QA using the current server contract

The Desktop SHALL expose authenticated project membership, published QA versions, and published Suite cases through the existing generated API and SHALL distinguish available published QA from locally received copies and personal assignments.

#### Scenario: Browse published versions
- **WHEN** a user connects and selects an authorized server project
- **THEN** the home displays its version and Suite lists with cursor pagination, selection details, and search scoped to loaded items
- **AND** it does not label these published versions as personally assigned work

#### Scenario: View-only membership
- **WHEN** a viewer can read a version but cannot pin it
- **THEN** the UI and server preserve the permission restriction and no local received QA is created through a failed receipt

### Requirement: Explicit immutable receipt into a local QA

The Desktop SHALL receive a selected immutable version into a new local QA in the explicitly selected local project, retain verified original XML and provenance, and SHALL NOT overwrite the current editor or execute automatically.

#### Scenario: Receive a QA version
- **WHEN** the user confirms a selected version, destination project, and QA name
- **THEN** the application rechecks the remote version and XML hash, pins it through the current API, persists receipt provenance, and creates the local QA
- **AND** the document opens as an unvalidated direct XML document with explicit validation and execution actions

#### Scenario: Receive a Suite member
- **WHEN** a user pins a published Suite and chooses one of its cases
- **THEN** the member version/hash is checked and received as an individual QA with Suite provenance
- **AND** the UI does not claim Desktop whole-Suite orchestration

#### Scenario: Same version already received
- **WHEN** a local copy already exists for the selected server origin, project, and version
- **THEN** the user can explicitly open that copy or create a separate new copy
- **AND** existing local edits are preserved

### Requirement: Durable receipt identity without workspace migration

Receipt metadata SHALL be persisted outside the strict workspace v1 JSON and SHALL be associated with both local project and QA identity while preserving the immutable original version and excluding credentials.

#### Scenario: Reopen and edit a received copy offline
- **WHEN** the application reopens a received QA without server connectivity
- **THEN** its original version and XML remain available and the current document can be edited independently
- **AND** the home distinguishes unchanged original content from local modifications

#### Scenario: Receipt persistence fails
- **WHEN** receipt storage or workspace commit fails
- **THEN** the previous workspace remains intact, incomplete receipt metadata is not shown as a received QA, and the user receives an actionable error

### Requirement: Reject stale or invalid receipt operations

The receipt coordinator SHALL bind asynchronous results to the captured connection, server project, selected version, local destination, and document identity.

#### Scenario: Context changes during receipt
- **WHEN** a pending receipt loses its captured connection or destination identity
- **THEN** its late result does not create or overwrite a QA in the new context

#### Scenario: Remote XML or version identity mismatch
- **WHEN** XML hash or immutable version identity validation fails
- **THEN** no received QA is created and existing documents remain unchanged

### Requirement: Preserve actual Engine runtime and publication limits

The Desktop SHALL retain its pinned alpha.8 Engine and the default server alpha.6 runtime and SHALL distinguish original-version provenance from result-publication compatibility.

#### Scenario: Execute XML received from the default server
- **WHEN** received alpha.6-published XML validates and runs locally with alpha.8
- **THEN** the result reports the actual alpha.8 runtime and is not automatically published to the incompatible default server
- **AND** source edits or composition that change the execution snapshot do not inherit the original execution version identity

### Requirement: Actual received-QA product acceptance

Acceptance SHALL include real local-server API receipt and native Windows execution, separate from mockups and production-service claims.

#### Scenario: Verify the complete journey
- **WHEN** the change is accepted
- **THEN** evidence covers separately reviewed/published server QA, native selection/pin/new-local-QA receipt, public Engine validation and PASS with artifacts, and restored provenance
- **AND** previous releases and Engine pins remain preserved
