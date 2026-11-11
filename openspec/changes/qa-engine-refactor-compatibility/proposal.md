# Proposal

## Why

Engine 모듈 분리 이후에도 Checker가 사용하는 공개 CLI·계약 파일·이벤트·결과가 동일하게 동작해야 한다. 내부 리팩터링 성공과 독립 설치 소비 호환을 별도로 확인해 패키징 누락이나 경로 변경을 발견한다.

## What Changes

- 실제 소비 검색을 바탕으로 CLI 진입점, package root 계산, schema/release 파일, manifest와 JSONL/결과 호환 경계를 기록한다.
- 승인된 alpha.8 후보만 version/hash별 별도 설치해 공개 API exports·CLI/XML·실제 Flutter Service PASS/FAIL/cancel·1000node 결과를 검사한다.
- 후보 harness의 alpha.7 하드코딩만 명시적인 기대 버전 검증으로 확장하며 기존 alpha.7 증거는 덮지 않는다.
- 기본 alpha.6 설치/manifest/서버/Agent/Release와 고정 alpha.7 후보·인수 파일을 보존한다.

## Capabilities

### New Capabilities

- `qa-public-engine-compatibility`: 독립 Engine 내부 변경과 무관하게 공개 배포 경계로 소비를 검증하는 호환 인수.

### Modified Capabilities

없음. sync된 기준 spec은 없으며 기존 `qa-engine-process-consumption`의 timeout/취소 정책은 변경하지 않는다.

## Impact

대상은 소비 경계 문서, 격리 설치/harness 및 인수 자료다. 새 Engine 실행 DSL, 제품 기능, HTTP 변경, 기본 pin 승격, 운영 배포, Windows 재빌드와 Engine 저장소 수정은 범위 밖이다. 제품 코드는 호환 결함이 실제 재현될 경우에만 관리 검토 후 수정한다.

integrationId: automated-qa-foundation
contractVersion: 0.3.0-draft.2 (alpha.8 candidate-1 격리 인수; 기본 alpha.6/draft.1 유지)
counterpartRepoChange: automated-qa-engine/qa-engine-modular-refactor
dependsOn: qa-engine-service-consumption
acceptanceCriteria: Engine 전체 verify·관리 hash 게이트 이후 독립 설치 전수 hash/공개 경로/API/CLI/XML/Service 결과 인수, alpha.6 및 alpha.7 불변 확인
