# qa-auth-workflow

## ADDED Requirements

### Requirement: Verified organization authentication

The system SHALL validate OIDC state, nonce, signed ID token issuer/audience/expiry and allowed workspace before creating a server session. Project membership SHALL be provisioned independently of authentication.

#### Scenario: Forged or replayed callback

- **WHEN** callback state, signature, nonce, audience, workspace or lifetime is invalid or already used
- **THEN** authentication fails without creating a session or granting project access

### Requirement: Session and Desktop delivery boundaries

The system SHALL keep session secrets outside logs and durable plaintext storage, validate CSRF for cookie mutations and bind short-lived one-use Desktop codes to a loopback callback and PKCE verifier.

#### Scenario: Desktop code cannot be reused

- **WHEN** an expired, consumed or wrong-verifier callback code is exchanged
- **THEN** no session is returned and no test starts

### Requirement: Independent work state

The system SHALL persist authorized revision-checked work state separately from immutable Engine outcome and audit changes.

#### Scenario: Concurrent triage

- **WHEN** two actors update the same revision
- **THEN** one update succeeds and the other receives a conflict while Engine outcome remains unchanged

### Requirement: Durable notification delivery

The system SHALL separate notification permissions from login, persist retries and expose delivery failure without changing execution outcome.

#### Scenario: Sink unavailable across restart

- **WHEN** an authorized local fixture sink fails and the server restarts
- **THEN** the same delivery identity resumes with bounded retries and no duplicate work-state transition

### Requirement: Evidence bounded baseline comparison

The system SHALL compare immutable outcomes and node failures only when scenario snapshot, target, Engine version and verified check-report profile/reference identity match. Missing environment evidence SHALL produce incomparable with a reason. Explicit baseline selection SHALL NOT promote image files or modify original results.

#### Scenario: Environment identity absent

- **WHEN** a run has no verified profile/reference evidence or differs from its chosen baseline
- **THEN** comparison is incomparable and no regression or improvement is invented

#### Scenario: Previous comparable result

- **WHEN** an earlier run has matching verified comparison identity
- **THEN** the system returns its immutable outcome and changed node failures separately from work status
