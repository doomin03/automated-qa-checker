## ADDED Requirements

### Requirement: interaction priority

The system SHALL use screen text, accessibility information, baseline image, image-relative coordinates, percent coordinates, and absolute pixel coordinates in that priority order for black-box interactions.

#### Scenario: text and percent coordinate exist

Given a step can locate an element by visible text and also has percent coordinates
When the runner resolves the target
Then it SHALL use visible text before percent coordinates.

### Requirement: percent coordinate conversion

The system SHALL convert percent coordinates using the current screen width and height.

#### Scenario: tapPercent conversion

Given the screen size is `1080x2400`
And a step uses `x: 50` and `y: 82`
When the step executes
Then the actual tap coordinate SHALL be `540,1968`.

### Requirement: image match result

The visual engine SHALL return image match results with found, similarity, x, y, width, and height fields.

#### Scenario: findImageAndTap

Given a baseline image is found at `x=100`, `y=200`, `width=80`, and `height=40`
When `findImageAndTap` executes
Then the runner SHALL tap the center coordinate `140,220`.
