# Spec Delta

## Purpose

기획 A03 업무 담당자 선택에 필요한 활성 프로젝트 회원을 제한된 조회 계약으로 제공하며 사용자 관리 CRUD나 개인 실행 배정 기능을 추가하지 않는다.

## ADDED Requirements

### Requirement: Manager scoped active member page

서버 SHALL manager 이상에게 현재 프로젝트의 active 회원 userId/role/nullable displayName만 반환한다. 현재 이름 저장소가 없으므로 displayName은 null이다. limit 1..100과 users.rowid 오름차순 canonical cursor를 적용한다. token hash와 다른 프로젝트 회원은 노출하지 않는다.

#### Scenario: Project manager selects an assignee
- **WHEN** manager가 프로젝트 members를 조회한다
- **THEN** 활성 프로젝트 회원만 최소 필드와 bounded nextCursor로 반환한다

#### Scenario: Lower role or another project is denied
- **WHEN** viewer/tester/editor 또는 다른 프로젝트 manager가 조회한다
- **THEN** 403을 반환하고 회원 목록을 노출하지 않는다

### Requirement: Discovery does not grant mutation authority

서버 MUST 회원 조회가 사용자 CRUD나 업무 수정 권한을 새로 부여하지 않도록 하고 기존 assignee membership/revision 및 실행 결과 분리 정책을 유지한다.

#### Scenario: Membership changes after discovery
- **WHEN** 조회 이후 비활성 또는 타 프로젝트 회원으로 업무 담당자 변경을 시도한다
- **THEN** 기존 업무 mutation의 membership 검사가 거부한다
