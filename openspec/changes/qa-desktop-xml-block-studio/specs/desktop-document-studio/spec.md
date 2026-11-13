## ADDED Requirements

### Requirement: Document-oriented desktop shell

The Desktop SHALL provide a document-oriented application shell with menus, a compact command toolbar, QA document tabs, tools, a block palette, a canvas, inspectors, document structure/history, and terminal/output/result docks.

#### Scenario: Open a QA document
- **WHEN** the user opens a QA from the workspace
- **THEN** the application opens the document in the working shell and exposes its file/source, dirty, validation, and execution state
- **AND** the canvas is the primary editing surface rather than a dashboard or card landing page

### Requirement: Functional Blueprint interactions

The Desktop SHALL support selection, pan, zoom, fit, node dragging, pin-based connections, deletion and undo with consistent canvas coordinates and focus boundaries.

#### Scenario: Edit under zoom
- **WHEN** the user moves a block or connects pins after panning and zooming
- **THEN** the position and connection follow the canvas coordinate system and the intended nodes
- **AND** layout-only movement does not change the execution document

#### Scenario: Use the interactive terminal
- **WHEN** terminal input has keyboard focus
- **THEN** typing, Delete, and Ctrl+C reach the terminal without triggering canvas editing commands
- **AND** collapsing the dock does not silently end its process

### Requirement: Usable docks and honest user controls

The Desktop SHALL remain usable at 1440×900 and 1024×768 and every visible command SHALL perform its stated action or explain why it is disabled.

#### Scenario: Reduce available space
- **WHEN** the window is resized to 1024×768
- **THEN** panels can be collapsed or changed by tabs without overlap and essential canvas, validation, execution, and cancellation actions remain accessible

### Requirement: Native product acceptance

The change SHALL be accepted using the real Flutter product and public Engine with preserved prior releases.

#### Scenario: Deliver the updated app
- **WHEN** the work is reported complete
- **THEN** native screenshots, actual user interactions, public Engine outcomes/artifacts, tests, and a separately identified Windows release substantiate the result
- **AND** an HTML mockup or placeholder does not substitute for product acceptance
