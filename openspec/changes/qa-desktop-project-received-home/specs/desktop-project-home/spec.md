## ADDED Requirements

### Requirement: Complete project entry journey

The Desktop and prototype SHALL start with a visible home that exposes local projects, their QA documents, and received QA, and SHALL provide a visible return path from the editor.

#### Scenario: Open a local project and QA
- **WHEN** the user starts the application and selects a project and QA
- **THEN** the application opens the selected document in the existing XML/block workbench
- **AND** the home and project path remain discoverable without advanced settings

#### Scenario: Empty or offline workspace
- **WHEN** no project exists or the shared server is unavailable
- **THEN** the home offers project creation and preserves access to existing local documents and received copies
- **AND** the interface does not imply that login is required for local editing and execution

### Requirement: Protected home navigation

The Desktop SHALL protect document and composition changes when navigating home or changing the selected QA.

#### Scenario: Leave a modified document
- **WHEN** a user returns home with unsaved document or block changes
- **THEN** save, discard, and cancel are explicit choices
- **AND** failed save does not navigate away

#### Scenario: Running or asynchronous document operation
- **WHEN** execution, compilation, or saving is active
- **THEN** changing the document is blocked until the operation completes or is explicitly cancelled

### Requirement: List-oriented desktop home

The home SHALL use searchable lists, selection details, and honest connection/loading/empty/error states using the established desktop visual language.

#### Scenario: Review at supported window sizes
- **WHEN** the home is displayed at 1440 by 900 or 1024 by 768
- **THEN** project and QA selection and their next actions remain usable without overlapping panels or KPI cards
- **AND** prototype example data is identified separately from actual server and local data
