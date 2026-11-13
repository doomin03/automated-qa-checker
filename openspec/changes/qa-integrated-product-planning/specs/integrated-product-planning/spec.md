## ADDED Requirements

### Requirement: Connected product planning entry point

The review tool SHALL connect a functional relationship map, user journeys, screen specifications, interactive prototypes, and decisions through one local entry point with stable screen identifiers.

#### Scenario: Follow a planned screen into the prototype
- **WHEN** a reviewer selects a screen and representative state in its specification
- **THEN** the corresponding prototype state opens and provides a return to that screen specification
- **AND** all screens are reachable from a journey or the searchable screen index

### Requirement: Complete and honest system boundaries

The planning artifact SHALL distinguish user web, administrative work, Checker Server, Agent, Desktop and independent Engine with labeled data transfers and separate local and server execution paths.

#### Scenario: Inspect local and remote execution
- **WHEN** a reviewer compares receiving a published QA and scheduling a server execution
- **THEN** the local alpha.8 and server/Agent alpha.6 paths remain separate
- **AND** Engine package or CLI use without Checker is visible
- **AND** runtime incompatibility, original bytes, canonical snapshots, workflow state and execution outcome are not conflated

### Requirement: Evidence-based feature and screen specifications

Each feature and screen SHALL record purpose, actor and permissions, entry and exit, data and actions, applicable states, counterpart API, acceptance criteria, and evidence independently of proposed information architecture.

#### Scenario: Review proposed administration screens
- **WHEN** a reviewer opens a new web screen grouping
- **THEN** the tool identifies it as a screen structure proposal and links the actual current route or API evidence
- **AND** unimplemented personal QA assignment, unsupported Desktop Suite execution and unverified AI behavior are not marked complete

### Requirement: Preserve complete Desktop and web journeys

The prototype SHALL retain the project and received-QA home and existing XML block workbench and SHALL include public QA discovery and progress separately from role-based review, publishing and operations.

#### Scenario: Receive and edit a published QA
- **WHEN** a reviewer follows a published version or Suite case into Desktop receipt
- **THEN** a new local QA is distinguished from the original and an existing copy
- **AND** file blocks and direct XML remain reachable with a protected home return
- **AND** the simulation does not claim an implemented deep link, live API call or Engine run

#### Scenario: Permission and execution states
- **WHEN** a reviewer changes role or opens failure, cancellation, loading, empty or disconnected examples
- **THEN** available actions and recovery information match the documented contract
- **AND** cancellation requested differs from terminal cancelled and validation failure does not create a run result

### Requirement: Inspectable design quality and decision trace

The artifact SHALL apply the established workbench visual system, include the three owners' proposal and counterexample decisions, and be verified at 1440 by 900 and 1024 by 768.

#### Scenario: Accept the planning upgrade
- **WHEN** the completed artifact is reviewed
- **THEN** screen and journey links, local interactions, role and state switches, and representative screenshots have recorded verification
- **AND** prototype evidence remains separate from prior native and Engine acceptance and preserves those artifacts
