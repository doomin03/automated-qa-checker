# Proposal

## Why

실서비스 준비 감사에서 Desktop CLI 명령의 timeout이 프로세스 exit에만 적용되고 이후 pipe drain에는 적용되지 않는 경계를 확인했다. 프로세스 종료와 출력 종료를 함께 유한하게 관리하고, 느린 UI 소비·큰 출력·취소·비정상 종료에서도 실제 결과를 정확히 구분해야 한다.

## What Changes

- Flutter 공개 CLI transport의 전체 기한, 출력 한도, 취소와 종료 정리를 공통화한다. UI 구독 속도와 OS 출력 drain을 분리한다.
- 실제 자식 프로세스 fixture로 inherited pipe·과대 출력·잘못된 JSONL·중단/구독 취소를 재현하고 고정 공개 패키지 PASS/FAIL/cancel을 회귀한다.
- 서버의 비실행 plan bridge와 Agent transport 경계를 조사하고 재현된 Checker 결함만 보완한다.
- 40/1000node Flow의 캔버스 잘림을 보완해 마지막 노드 접근·선택과 기존 좌표/원문 보존을 검증한다.
- 웹/모바일/Windows 제어 지원, 설치·pin·운영 환경의 제약과 실제 검증 시간을 기록한다. 기존 앱·목업·Release는 보존한다.

## Capabilities

### New Capabilities

- `qa-engine-process-consumption`: 공개 CLI 프로세스와 출력의 유한한 수명, 보수적 결과 판정 및 소비자 검증.

### Modified Capabilities

없음. 아직 sync된 기준 spec은 없으며 기존 handoff의 명시 실행·취소 구분 요구를 보강한다.

## Impact

Flutter run_review Service/transport/test, scenario_editor canvas 범위와 검증 문서가 대상이다. HTTP/DSL/실행 결과 schema는 변경하지 않는다. Engine 소스 수정은 담당자에게 관리 경유 요청하며 초기 alpha.6 pin을 유지한다. 후속 Engine 후보는 관리 승인된 version/hash의 별도 외부 설치로 검증하며 자동 pin 승격하지 않는다.

integrationId: automated-qa-foundation
contractVersion: 0.3.0-draft.1
dependsOn: qa-user-web-desktop-handoff, qa-desktop-mvvm-boundaries, qa-agent-protocol
counterpartRepoChange: automated-qa-engine/qa-engine-service-hardening
candidateContractVersion: 0.3.0-draft.2 (runtime alpha.7 candidate-3 격리 인수 완료; 기본 pin alpha.6 유지)
acceptanceCriteria: 실제 프로세스 경계 회귀, 공개 package PASS/FAIL/cancel, Flutter analyze 및 관련 회귀, 운영 제약 명시
