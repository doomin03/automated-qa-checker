# Spec Delta

## Purpose

사용자가 로컬 프로젝트와 개별 QA를 지속적으로 관리하고, 하나의 Desktop 작업 공간에서 XML과 블록을 편집한 뒤 실제 검증·실행·증거를 확인하도록 한다. 서버 연결 없이도 이 기본 경로를 사용할 수 있다.

## ADDED Requirements

### Requirement: Durable projects and QA documents
앱은 프로젝트/QA 생성·이름 변경·목록 열기, 프로젝트 지침과 QA별 요청, 문서의 명시 저장을 SHALL 제공한다. QA 식별자는 실행 Blueprint 식별자와 독립적이며 파일 변경 실패나 동시 쓰기는 기존 저장본을 손상시키지 않아야 한다.

#### Scenario: Restart restores saved work
- **WHEN** 사용자가 프로젝트/QA를 만들고 문서·프로젝트 지침·QA 요청을 저장한 뒤 앱을 재시작한다
- **THEN** 목록, 이름, 저장된 내용과 수정 시각이 복원되고 QA는 자동 실행되지 않는다

#### Scenario: Failed save and concurrent writer
- **WHEN** 저장 중 I/O 오류 또는 다른 앱 인스턴스의 저장 충돌이 발생한다
- **THEN** 이전 저장본과 현재 편집 초안을 유지하고 오류를 표시하며 성공으로 표시하지 않는다

#### Scenario: Prompt edits are unsaved work
- **WHEN** XML을 수정하지 않고 프로젝트 지침 또는 QA 요청만 수정한 뒤 QA 전환이나 종료를 시도한다
- **THEN** 미저장 변경으로 표시하고 저장/취소를 제공하며 저장한 프롬프트는 재시작 후 복원된다

### Requirement: Desktop editing workspace
앱은 프로젝트 목록 → QA 목록 → 도킹 편집 공간을 SHALL 제공한다. 편집 공간은 Flow/XML, 선택 노드 속성, AI 요청 패널, 실행 로그·결과를 제공하며 기본 편집 기능과 연결 설정을 구분한다.

#### Scenario: Canvas and XML share a document
- **WHEN** 사용자가 노드·연결·속성을 수정하거나 XML을 수정한 뒤 검증한다
- **THEN** 동일한 실행 문서에서 그래프와 검증 계획을 만들며 지원하지 않는 원문을 묵시적으로 삭제하지 않는다

#### Scenario: Compact desktop
- **WHEN** 창이 1024×768 또는 1440×900이다
- **THEN** 패널 접기와 내부 스크롤로 캔버스·AI 요청·실행 버튼에 접근할 수 있고 패널이 겹치지 않는다

### Requirement: Explicit execution and trustworthy evidence
앱은 검증·실행·취소를 명시 동작으로 SHALL 제공하며 실행 snapshot에 묶인 단계 진행, 실패 이유, 수집된 PNG와 디자인 검사 결과를 표시해야 한다. QA 이동이나 편집이 실행 결과의 소속을 바꾸어서는 안 된다.

#### Scenario: Run then edit another document
- **WHEN** 실행 중 QA를 전환하거나 문서를 수정하려 한다
- **THEN** 실행 중 전환을 차단하거나 고정된 실행 snapshot으로 분리하며 이전 실행 상태를 새 초안에 적용하지 않는다

#### Scenario: Failure evidence and absent screenshots
- **WHEN** 실제 Engine 실행이 실패하고 검증된 PNG 또는 디자인 보고서가 존재한다
- **THEN** 원본 실패 단계·이유·이미지·수치를 보여 주며 이미지 미수집 또는 환경 오류를 성공이나 AI 분석으로 표시하지 않는다

#### Scenario: Completed run retains its QA identity
- **WHEN** 실행 완료 뒤 다른 QA로 이동하여 이전 결과를 연다
- **THEN** 결과·이미지에 원래 프로젝트/QA와 실행 snapshot 소속을 표시하고 현재 QA의 실행 결과로 오인시키지 않는다

### Requirement: Desktop runtime isolation
새 앱은 검증된 alpha.8 실행 package와 manifest를 SHALL 함께 사용하고 기존 alpha.6 서버·Agent 설치와 이전 Release를 보존해야 한다. 서버와 실행 version이 다르면 공유 게시의 비호환을 명시하며 로컬 실행 결과를 바꾸지 않는다.

#### Scenario: New and previous apps coexist
- **WHEN** 새 Release를 설치·실행한다
- **THEN** 앱 전용 alpha.8을 사용하고 기존 alpha.6 설치·Release의 파일 hash는 변하지 않는다

#### Scenario: Runtime mismatch
- **WHEN** CLI 경로가 내장 manifest와 다른 version 또는 파일 hash를 가리킨다
- **THEN** 실행을 거부하고 일치하는 앱 runtime 설치를 안내한다
