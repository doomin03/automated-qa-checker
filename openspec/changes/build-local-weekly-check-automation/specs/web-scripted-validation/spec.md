## ADDED Requirements

### Requirement: explicit web scenarios

The system SHALL run user flows that cannot be validated by crawling as explicit web scenarios.

#### Scenario: login navigation flow

Given a web target references a login scenario YAML
When the user runs `pnpm qa:scenario --target sample-web`
Then the system SHALL execute the declared steps in order and evaluate the declared assertions.

### Requirement: DOM selector priority

The web scenario runner SHALL prefer role, visible text, label, CSS selector, XPath, image, percent coordinate, and absolute coordinate selectors in that order when multiple locator strategies are available.

#### Scenario: role and CSS are both defined

Given a step defines both a role selector and a CSS selector
When the runner resolves the element
Then the role selector SHALL be attempted before the CSS selector.

### Requirement: post-action validation

The web scenario runner MUST NOT treat a click or input action alone as success.

#### Scenario: click without expected result

Given a click step is followed by no assertion or expected state
When the scenario is validated
Then the system SHALL return a scenario validation error before execution.
