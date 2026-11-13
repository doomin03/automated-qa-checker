# Spec Delta

## Purpose

홈·수신·파일 블록 편집·직접 문서·AI 도구·실행 결과를 하나의 Desktop 사용자 흐름으로 연결한다. 프로젝트 권한, 불변 게시 원본, 로컬 사본과 실행 snapshot을 구분하여 서버 연결이나 창 전환이 실행 판정을 왜곡하지 않게 한다.

## ADDED Requirements

### Requirement: Project context describes actual capabilities
앱은 SHALL 선택 서버/프로젝트의 검증된 역할·허용 행위·Engine 계약 정보를 보여주며 세션이나 프로젝트 교체 후 늦은 응답을 버린다. 알 수 없는 권한을 허용으로 추정하지 않고 서버의 권한 검사를 유지한다.

#### Scenario: Offline and revoked membership
- **WHEN** 오프라인이거나 서버 프로젝트 권한 조회가 실패/철회된다
- **THEN** 서버 행위는 실패 이유와 재시도를 표시하고 로컬 프로젝트 작성·편집·명시 실행은 별도로 유지한다
- **AND** 이전 프로젝트의 권한이나 연결 성공 상태를 새 프로젝트에 적용하지 않는다

### Requirement: Runtime incompatibility is separate from local outcome
앱은 SHALL Desktop 실행 런타임/계약과 서버가 수용하는 런타임/계약을 대조해 공유 불가 이유를 표시한다. 서버 게시 실패가 로컬 실행 결과·증거를 변경하거나 삭제해서는 안 된다.

#### Scenario: Desktop alpha8 and server alpha6
- **WHEN** alpha8 Desktop에서 PASS 결과를 만들고 alpha6 서버 프로젝트에 공유하려 한다
- **THEN** 로컬 PASS와 보고서/PNG는 유지하고 공유 상태만 호환되지 않음으로 표시한다
- **AND** 서버/앱의 pin을 자동 변경하거나 외부 실행 검증 완료를 합성하지 않는다

### Requirement: Received versions and Suite cases retain provenance
앱은 SHALL 게시 원본과 ordered Suite pin 목록을 조회하여 선택 case 하나를 로컬 QA 사본으로 받게 한다. 서버·프로젝트·version·hash와 로컬 QA identity를 보존하며 수신 자체는 실행하지 않는다.

#### Scenario: Reopen pinned Suite and edit one case
- **WHEN** 저장된 Suite pin을 다시 열어 ordered case를 선택해 수신하고 원문을 수정한다
- **THEN** 수신 출처는 남지만 수정된 snapshot의 실행을 원본 version 그대로 실행한 것으로 게시하지 않는다
- **AND** 기존 로컬 사본을 비승인 덮어쓰지 않고 Desktop 전체 Suite 일괄 실행 완료를 표시하지 않는다

### Requirement: Document modes keep their own source authority
앱은 SHALL XML 파일 블록의 자산·인스턴스·합성 결과와 직접 XML/JSON 문서를 구분한다. 모드 전환·QA 전환은 미저장 변경과 실행 sourceMap 소속을 보호하며 수신/합성/검증만으로 실행하지 않는다.

#### Scenario: File block composition and failure mapping
- **WHEN** 사용자가 두 XML 파일 블록을 연결하고 합성한 뒤 명시 실행한다
- **THEN** 공개 Engine으로 검증한 전체 snapshot만 실행하고 실패를 동일 snapshot/sourceMap의 해당 블록과 결과로 연결한다
- **AND** 합성 미리보기 수정이 원본 파일 자산을 묵시적으로 변경하지 않는다

### Requirement: AI tool paths expose real modification boundaries
앱은 SHALL 고정 후보 생성 도구의 검증/미리보기/명시 적용과 실제 터미널의 파일 편집 경로를 구분한다. 직접 문서에서 안정된 외부 파일을 전체 검증한 뒤 충돌 없이 반영하며, 불완전/잘못된 파일이나 GUI 변경과의 충돌에서는 마지막 유효 문서를 유지한다.

#### Scenario: Interactive edits and a concurrent GUI change
- **WHEN** QA 전용 세션에서 파일이 변경되는 동안 GUI 문서가 수정되거나 다른 QA로 전환된다
- **THEN** 늦은 검증 결과가 새 편집/QA를 덮지 않고 원문 사본을 보존하는 충돌 해결을 제공한다
- **AND** 블록 합성 모드에서는 외부 파일을 자산/합성 정본에 자동 덮지 않으며 사용자가 직접 문서 경로를 선택하게 한다

### Requirement: Progress, evidence and work state stay distinct
앱은 SHALL 실행 요청·실제 실행 진행·최종 판정·증거 정합성·서버 공유 상태를 구별한다. 취소 요청을 최종 cancelled로 합성하지 않고 현재 미검증 문서를 PASS로 표시하지 않는다.

#### Scenario: Optional skipped step and old results
- **WHEN** 원본 이벤트가 step.finished/outcome skipped를 기록하거나 QA 전환 후 이전 결과를 확인한다
- **THEN** step의 skipped를 표시하고 전체 판정은 실제 terminal/result에서 읽는다
- **AND** 결과의 원 QA/run/snapshot을 표시하며 현재 편집 문서의 결과로 바꾸지 않는다
