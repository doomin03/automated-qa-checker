# Server Agent runtime alignment

## ADDED Requirements

### Requirement: Current runtime is pinned without overwriting history

Checker SHALL 별도 서버 manifest와 설치 경로에서 검증된 alpha.10 archive와 파일 hash를 사용하고 legacy alpha.6 설치·assets·불변 저장 자료를 덮어쓰지 않아야 한다.

#### Scenario: Installer detects a mismatching package

- **WHEN** 입력 archive 또는 기존 설치 파일이 승인 pin과 다르다
- **THEN** 준비 명령은 실패하며 기존 runtime/receipt를 정상으로 보고하거나 덮어쓰지 않는다

#### Scenario: Old data remains readable after runtime upgrade

- **WHEN** alpha.6 Run과 게시 버전이 있는 DB를 alpha.10 서버로 연다
- **THEN** 기존 조회와 저장된 runtime/hash/결과는 유지되고 alpha.6 신규 ingestion은 current exact pin 검사로 거부한다

### Requirement: Shared results retain actual evidence and authorization

서버 SHALL 실제 alpha.10 실행의 이벤트·결과·PNG를 기존 인증/소유권/snapshot 경계를 통해 수신하고 판정과 전송·증거·업무 상태를 분리해야 한다.

#### Scenario: Chromium result and PNG are shared

- **WHEN** 동일 pin의 실행을 등록하고 이벤트·결과·PNG를 전송한다
- **THEN** 실제 판정과 verified evidence를 조회하며 PNG 다운로드 bytes/SHA가 원본과 일치한다

### Requirement: Agent identities and ownership are never silently upgraded

서버 SHALL 새 runtime의 Agent를 별도 신뢰 provisioning으로 등록하고 기존 Agent/job/lease/fence/receipt/history를 자동으로 재작성하지 않아야 한다.

#### Scenario: Old registration cannot claim with a new executable

- **WHEN** alpha.6 등록의 Agent가 alpha.10 runtime triple로 claim한다
- **THEN** claim은 거부되며 기존 등록·작업·lease 이력은 보존된다

### Requirement: Real Suite scheduling and cancellation preserve status axes

Checker SHALL 새 runtime의 실제 Agent를 통해 Suite 순차 실행과 예약 발생 및 취소를 검증하고 실행 결과·lease·예약·전송/증거·업무 상태를 혼합하지 않아야 한다.

#### Scenario: Due schedule executes once

- **WHEN** 제어된 clock의 due occurrence가 중복 tick 또는 재시작을 거쳐 실제 Agent에 전달된다
- **THEN** 하나의 occurrence와 실행만 생성되고 실제 case 결과·receipt·cleanup을 조회할 수 있다

#### Scenario: Cancellation is not a successful terminal result

- **WHEN** 진행 중인 실제 실행에 취소를 요청한다
- **THEN** 요청 응답과 최종 결과 및 정리 확증을 구분하고 소유 process 종료를 확인하며 cancelled/timeout/unknown을 passed로 보고하지 않는다
