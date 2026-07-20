## ADDED Requirements

### Requirement: safe Playwright crawler

The system SHALL crawl production web URLs with Playwright while staying within configured safe scope.

#### Scenario: same-origin crawling

Given crawler config has `sameOriginOnly: true`
When the crawler discovers a link to another origin
Then the crawler SHALL NOT navigate to that external origin.

### Requirement: crawler health checks

The crawler SHALL check HTTP status, broken links, broken images, JavaScript page errors, console errors, failed network requests, missing title, empty body, and loading timeouts.

#### Scenario: broken image

Given a crawled page contains an image that fails to load
When the crawler checks the page
Then the page result SHALL include a failure for the broken image and store failure evidence.

### Requirement: crawler loop prevention

The crawler MUST enforce max depth, max pages, per-page timeout, total timeout, URL normalization, query normalization, fragment removal, and duplicate URL blocking.

#### Scenario: repeated URL with fragment

Given a page links to `/notice#top` and `/notice#bottom`
When the crawler normalizes URLs
Then the crawler SHALL visit the normalized `/notice` URL only once.

### Requirement: crawler prohibited actions

The crawler SHALL NOT submit forms, click arbitrary buttons, upload files, download files, perform payments, perform orders, delete data, logout, create production data, or directly explore API endpoints by default.

#### Scenario: form is present

Given a crawled page contains a form
When the crawler discovers the form
Then the crawler SHALL NOT submit the form.
