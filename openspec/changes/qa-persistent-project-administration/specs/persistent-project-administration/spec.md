# Persistent project administration

## ADDED Requirements

### Requirement: Identity storage mode is explicit and durable

서버 SHALL 명시 managed 모드에서만 영속 관리 mutation을 허용하고 기존 기본 provisioned 시작 정책을 유지해야 한다. managed DB를 provisioned로 자동 재조정해서는 안 된다.

#### Scenario: Managed restart preserves administrator changes

- **WHEN** 관리자가 role/활성 상태를 변경한 후 같은 DB를 다른 seed와 managed로 재시작한다
- **THEN** 저장된 변경과 revision이 보존되고 seed가 membership을 삭제·권한승격하지 않는다

#### Scenario: Accidental downgrade fails closed

- **WHEN** managed로 기록된 DB를 기본 provisioned 모드로 연다
- **THEN** 서버는 identity 자료를 수정하기 전에 명시 오류로 시작을 거부한다

#### Scenario: Existing test provisioning remains compatible

- **WHEN** managed 전환 기록이 없는 기존 provisioned fixture가 새 seed로 재시작한다
- **THEN** 기존 활성 사용자·membership 재조정 규칙과 인증 테스트가 유지된다

### Requirement: Administration respects project authority

서버 SHALL 프로젝트의 활성 역할을 조회와 mutation마다 검사하고 qa_manager의 동급/상위 관리 및 모든 사용자의 자기승격을 거부해야 한다. global user 변경은 모든 해당 membership 프로젝트의 system_admin 권한을 요구해야 한다.

#### Scenario: Project manager cannot disable another project's principal

- **WHEN** 한 프로젝트만 관리하는 사용자가 다른 프로젝트에도 속한 사용자의 global active를 바꾸려 한다
- **THEN** 변경은 거부되고 다른 프로젝트 정보와 token/hash가 노출되지 않는다

#### Scenario: Last administrator cannot be removed

- **WHEN** 변경이 프로젝트의 마지막 active system_admin 또는 마지막 active qa_manager 이상을 제거한다
- **THEN** 원자 transaction은 거부되고 기존 권한과 revision을 보존한다

### Requirement: Mutations preserve revision and audit history

서버 SHALL user/membership 변경을 revision과 감사 기록으로 원자 처리하고 hard user 삭제 대신 비활성·회원 해제를 구분해야 한다. membership 재추가도 삭제 이전 revision을 재사용해서는 안 된다.

#### Scenario: Concurrent membership update is rejected

- **WHEN** 두 요청이 같은 membership revision으로 서로 다른 변경을 시도한다
- **THEN** 하나만 반영되고 나머지는409이며 과거 실행·게시·pin 자료는 바뀌지 않는다

#### Scenario: Deactivation invalidates existing authentication

- **WHEN** 허용된 관리자가 사용자를 비활성화했다가 다시 활성화한다
- **THEN** 비활성 시점의 세션/desktop code는 다시 사용할 수 없고 새 인증을 요구한다

### Requirement: Management endpoints are bounded and additive

서버 SHALL 기존 active member/context 계약을 유지하고 별도 관리 directory의 페이지를1..100으로 제한해야 한다. 신규 사용자 생성은 멱등하며 기존 외부 ID 충돌은 비밀정보 없는 오류를 반환해야 한다.

#### Scenario: Provisioned deployment rejects administrative writes

- **WHEN** 기존 provisioned 서버에 사용자 생성 또는 membership 변경 요청을 보낸다
- **THEN** 명시 저장 모드 오류로 거부하고 기존 환경 권위와 데이터를 유지한다

#### Scenario: SDK preserves nullable display name

- **WHEN** displayName이 null인 관리 응답을 TS 및 Dart SDK로 읽고 직렬화한다
- **THEN** null 및 role/revision/active가 손실 없이 유지되고 credential 필드는 없다

#### Scenario: Generated clients can explicitly clear a display name

- **WHEN** TS 또는 Dart SDK가 clearDisplayName:true와 현재 userRevision으로 PATCH를 전송한다
- **THEN** 서버는 표시명을 null로 저장하고 nullable 응답을 보존한다. displayName과 clearDisplayName 동시 지정, displayName:null, 다른 변경 없는 clearDisplayName:false는 거부하며 active-only 변경은 기존 표시명을 유지한다
