# Spec Delta

## Purpose

독립 Engine의 내부 모듈 구조가 바뀌어도 Checker가 사용하는 공개 배포 경로와 실행·문서 계약이 호환되는지 검증한다. 후보 인수를 기본 설치 승격과 분리하고 이전 검증 증거를 보존한다.

## ADDED Requirements

### Requirement: Public distribution compatibility
소비 호환 인수 SHALL Engine 소스 저장소의 내부 import 없이 설치 package의 공개 CLI, exports, 선언 타입과 공개 계약 파일로 수행한다.

#### Scenario: Internal modules are split
- **WHEN** 새 후보가 내부 구현을 여러 파일로 분리한다
- **THEN** 기존 공개 진입점과 계약 파일이 설치 package에서 해석되고 필요한 파일이 빠짐없이 포함된다
- **AND** private deep import나 Engine 원본 소스 경로로 누락을 우회하지 않는다

### Requirement: Exact isolated candidate identity
후보 소비 SHALL 관리 승인된 tgz SHA·정확한 version·contractVersion·bundle SHA를 확인하고 별도 설치 파일 manifest를 검증한다. 파일 개수를 이전 배포판 숫자로 고정하지 않는다.

#### Scenario: Candidate identity differs
- **WHEN** 후보 tarball, metadata 또는 설치 파일 hash가 승인값과 다르다
- **THEN** 후보 인수를 실패시키고 기본 설치와 기존 증거를 수정하지 않는다

### Requirement: Observable execution compatibility
새 후보 SHALL Checker의 기존 명시 실행 경로에서 PASS/FAIL/cancel 및1000node 결과를 구분하고 XML 문서 의미와 이벤트·결과 identity를 유지한다.

#### Scenario: Public XML and large flow execution
- **WHEN** 공개 CLI로 XML을 export/import/validate/plan하고 실제 Service에서 실행한다
- **THEN** 동일 Blueprint 의미·snapshot을 유지하며 PASS/FAIL 및 긴 visited/unvisited 목록을 올바르게 소비한다

#### Scenario: Paused event delivery cancellation
- **WHEN** UI 이벤트 전달이 멈춘 상태에서 취소를 요청한다
- **THEN** 공개 취소 제어와 durable result 저장이 진행되고 실제 terminal·exit·result가 일치할 때만 cancelled로 표시한다

### Requirement: Preserve prior accepted environments
후보 호환 검사 SHALL 기본 alpha.6 설치/Release/서버/Agent 설정과 고정 alpha.7 후보 및 증거를 보존한다. 격리 인수를 운영 승격으로 표시하지 않는다.

#### Scenario: Candidate acceptance finishes
- **WHEN** alpha.8 호환 검사가 통과한다
- **THEN** 별도 버전/hash·실제 결과·검사 한계를 기록하고 기존 설치·배포 파일·계약 pin 불변을 확인한다
