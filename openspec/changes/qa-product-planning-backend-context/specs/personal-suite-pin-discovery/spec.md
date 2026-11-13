# Spec Delta

## Purpose

사용자가 이전에 고정한 공용 Suite의 정확한 versionId와 sha256을 세션이나 앱 재시작 이후에도 다시 조회하여 순서가 있는 case별 수신 여정을 이어간다.

## ADDED Requirements

### Requirement: Bounded personal pin discovery

서버 SHALL viewer 이상에게 현재 사용자와 프로젝트의 Suite pin만 PinPage로 반환한다. limit은 1..100(기본 50), cursor는 canonical base64url rowid이며 오름차순으로 조회한다. 잘못된 cursor/limit은 거부한다.

#### Scenario: Personal selections survive restart
- **WHEN** 사용자가 Suite를 고정하고 서버 재시작 이후 같은 프로젝트 목록을 조회한다
- **THEN** 저장된 packageId/versionId/sha256을 반환한다

#### Scenario: Paging cannot leak another scope
- **WHEN** 사용자 또는 프로젝트가 다른 cursor로 조회한다
- **THEN** offset만 적용하고 현재 사용자와 프로젝트 밖의 pin을 반환하지 않는다

### Requirement: Old pins remain exact and non-executing

서버 MUST 저장된 pin을 runtime 변경 때문에 삭제하거나 자동 업그레이드하지 않는다. GET은 실행을 생성하지 않는다. version detail과 context는 호환성 판단 근거이며 pin paging은 snapshot 보장을 제공하지 않는다.

#### Scenario: Stored Suite belongs to an older runtime
- **WHEN** 현재 서버 runtime과 저장된 Suite runtime이 다르다
- **THEN** 원래 pin을 그대로 반환하고 getSuite에서 정확한 불일치를 확인할 수 있다
