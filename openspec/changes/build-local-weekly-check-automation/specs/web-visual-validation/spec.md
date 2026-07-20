## ADDED Requirements

### Requirement: visual mode for non-DOM screens

The system SHALL support Visual Mode for Flutter Web, Canvas, WebGL, Three.js, game screens, and UI without useful accessibility trees.

#### Scenario: Flutter Web visual scenario

Given a web target marks a scenario as visual
When the scenario runs
Then the runner SHALL validate screen state through screenshots, image matching, or coordinate-driven assertions instead of requiring DOM selectors.

### Requirement: visual web access check

The system SHALL still use Playwright navigation to confirm the page itself is reachable before visual interactions begin.

#### Scenario: visual page does not load

Given a visual web scenario target URL returns a 500 response
When the scenario starts
Then the system SHALL fail the page access check before executing visual coordinates.

### Requirement: visual evidence

The system SHALL store screenshots for failed visual assertions.

#### Scenario: image threshold fails

Given a visual assertion requires similarity `0.90`
When the observed similarity is `0.75`
Then the scenario SHALL fail and store the compared screenshot evidence.
