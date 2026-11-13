# Spec Delta

## Purpose

공용 QA 수신 및 실행 결과 공유 전에 인증된 프로젝트의 역할과 정확한 서버 Engine pin을 조회하여 로컬 실행 가능 여부와 원격 공유 호환성을 구분한다.

## ADDED Requirements

### Requirement: Scoped runtime and entry actions

서버 SHALL 인증된 프로젝트 회원에게 projectId, role, allowedActions와 engineVersion/contractVersion/contractSha256/nullable archiveSha256을 반환한다. archive hash는 설치 pin metadata이며 archive 재검증 보증이 아니다. 경로·설정·token을 반환하거나 실행을 시작하지 않는다.

#### Scenario: Member reads context without executing
- **WHEN** 유효한 프로젝트 회원이 context를 조회한다
- **THEN** 해당 프로젝트 역할과 시작 시 확인된 runtime 정보를 반환하며 Engine plan/run이나 job을 생성하지 않는다

#### Scenario: Unauthorized scope is refused
- **WHEN** 인증이 없거나 해당 프로젝트 회원이 아니다
- **THEN** 각각 401 또는 403을 반환하고 runtime metadata를 노출하지 않는다

### Requirement: Entry hints preserve authoritative mutation checks

서버 MUST 기존 역할 최소값으로 allowedActions를 계산하고 ownership/독립 검토/revision/runtime 확인을 기존 mutation에서 유지한다. 클라이언트 SHALL 정확한 pin 불일치를 공유 불가로 다루고 로컬 실행 상태와 구분한다.

#### Scenario: Reviewer sees action but cannot review own draft
- **WHEN** manager가 reviewPublish 진입권한을 받고 자신의 draft를 검토하려 한다
- **THEN** 기존 mutation은 독립 검토 조건에 따라 거부한다

#### Scenario: Desktop has a different Engine release
- **WHEN** Desktop alpha.8과 기본 서버 alpha.6 정보를 비교한다
- **THEN** 불일치를 확인할 수 있으며 기존 공유 차단은 유지된다
