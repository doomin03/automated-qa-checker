## ADDED Requirements

### Requirement: XML file assets as reusable authoring blocks

The Checker SHALL distinguish an imported XML file asset from its canvas instances and from primitive Engine execution nodes.

#### Scenario: Reuse an XML file
- **WHEN** the user imports a supported XML document and places it twice on a canvas
- **THEN** two separate instances refer to the stored asset identity and verified content hash
- **AND** the source file remains unchanged and no execution begins

#### Scenario: Choose or cancel a native file dialog
- **WHEN** the user requests an XML import or direct document open
- **THEN** a native file picker is the default and an explicit path input remains available
- **AND** cancelling or changing the QA while choosing does not mutate the document or switch modes

### Requirement: Public-contract compilation

The Checker SHALL compile supported XML-block compositions into the existing public Engine representation and validate the final XML through the public Engine before execution.

#### Scenario: Build a supported composition
- **WHEN** the user requests compilation of a supported block graph
- **THEN** the application provides a deterministic final XML snapshot and source correspondence
- **AND** the public Engine accepts its execution representation without a Checker-only execution node or schema extension

#### Scenario: Reject unsupported semantics
- **WHEN** an input, connection, target, or reference conflict is outside the explicitly accepted composition rules
- **THEN** compilation fails with a useful block/file diagnostic and preserves the source authoring document
- **AND** it does not emit or execute a guessed partial result

#### Scenario: Compose supported source graphs
- **WHEN** validated single-start/single-end source Blueprints with identical supported targets are connected sequentially
- **THEN** instance-specific nodes, selectors, variables, and known references are remapped deterministically while internal branch labels and secret resolver keys are preserved
- **AND** unsupported references, testcase/preset metadata, target profiles, cycles, or incomplete outer connections are diagnosed without mutating the sources

#### Scenario: Trace generated execution failures
- **WHEN** the public Engine identifies a generated node in validation or execution output
- **THEN** the Checker source map identifies its authoring instance, XML asset, and original node
- **AND** the mapping belongs to the compiled snapshot rather than a later edited draft

### Requirement: Direct XML workflow remains available

The Desktop SHALL allow users to open, edit, validate, and explicitly run a supported XML document without converting it into a reusable-block composition.

#### Scenario: Run an XML file directly
- **WHEN** the user opens a valid XML file, validates it, and explicitly requests execution
- **THEN** the application passes an immutable snapshot through the public Engine path and displays its actual result and evidence
- **AND** opening or validation alone never begins execution

### Requirement: Revision-safe authoring and preservation

The Checker SHALL preserve previous workspaces and source files and separate authoring state, layout, compiled execution snapshots, and result ownership.

#### Scenario: Source changes during compilation
- **WHEN** the document, asset bytes, QA identity, or relevant settings change before compilation finishes
- **THEN** the stale result is not applied as the current executable document
- **AND** previous source and run evidence retain their original identity

#### Scenario: Restore a saved authoring document
- **WHEN** the user reopens a saved XML-block document
- **THEN** stored assets, instance identities, connections, and layout are restored without rewriting the original XML files or silently migrating unrelated workspace data
