## ADDED Requirements

### Requirement: Verified relocatable runtime
Desktop SHALL resolve a bundled Node/Engine/browser runtime relative to its executable with approved package identities and a complete payload integrity inventory.

#### Scenario: Relocation
- **WHEN** the complete new bundle is copied to another absolute path containing Korean text and spaces with development Node absent from PATH
- **THEN** the app uses its verified Node/Engine/browser payload for a real local web run and records the actual resolved paths and evidence

#### Scenario: Missing or altered payload
- **WHEN** a required runtime file or receipt is absent, modified or resolves outside the bundle
- **THEN** execution fails explicitly without silently using a developer path or global browser cache

### Requirement: User configuration preservation
Desktop SHALL preserve explicit user runtime settings and keep report storage separate from the installed bundle.

#### Scenario: Existing explicit configuration
- **WHEN** the user already configured an external runtime
- **THEN** those paths remain visible and undergo normal pin validation rather than being overwritten by portable defaults

#### Scenario: Automatic defaults and legacy provenance
- **WHEN** saved runtime paths are marked as automatic and still equal their recorded defaults
- **THEN** a new verified bundle replaces those defaults while explicit edits remain preserved
- **AND** legacy paths without provenance remain unchanged until the user explicitly selects bundled defaults

### Requirement: Versioned authoring artifact resolution
Checker SHALL resolve the authoring release artifact from public metadata and verify both its safe location and approved bytes.

#### Scenario: New and legacy metadata
- **WHEN** approved alpha.9 or alpha.10 metadata names its authoring artifact
- **THEN** the same safe resolver locates the file and compares metadata, install manifest and pin hashes without guessing a contract-only filename

### Requirement: Honest distribution evidence
Checker SHALL preserve previous Releases and distinguish relocation tests from actual acceptance on a clean independent PC.

#### Scenario: Distribution inventory
- **WHEN** a new bundle is produced
- **THEN** licenses/provenance, Node and browser identities, transitive dependencies, app/config source hashes and native startup are recorded without user credentials or developer caches
