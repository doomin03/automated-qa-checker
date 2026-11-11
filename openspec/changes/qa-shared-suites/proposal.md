# Why

Registry 단일 Blueprint XML만으로는 여러 고정 시나리오를 순서대로 검수·발행·실행 요청하는 원본 P3/P4 Suite 요구를 충족하지 못한다. 이미 승인된 플랫폼 범위 안에서 Suite 업무 계약과 사용자 웹 경로를 분리 인수한다.

# What Changes

- 동일 프로젝트의 published Blueprint version/hash를 ordered case 목록으로 묶고 stopOnFailure를 고정한다.
- 초안→독립 검수→immutable version 발행·개인 pin·페이지 조회를 제공한다.
- Agent enqueue는 SuiteService.resolvePublished 결과를 받아 각 XML을 공개 Engine CLI plan으로 검증한다. 수신·검수·pin은 실행하지 않는다.
- 웹 기능 폼과 생성 SDK를 연결하고 권한/중복/동시발행/재시작/명시 실행 요청을 검증한다.

# Capabilities

## New Capabilities

- `qa-shared-suites`: 고정 Registry 버전의 검수된 ordered 실행 모음.

# Impact

Checker 담당 modules/suite/**, test/suite.test.mjs, 사용자 웹. 서버 하위 담당은 AppModule/main wiring, 생성 SDK, Agent/Scheduler를 소유한다. migration6은 Suite 전용이다. dependsOn: qa-platform-services, qa-agent-protocol. counterpart: Engine qa-agent-protocol; HTTP agentProtocolVersion0.1.0-draft.1의 ordered cases/suitePolicy를 재사용한다. Engine 실행 schema를 새로 만들지 않으며 raw qa.suite/v1 XML 업로드와 동일하다고 주장하지 않는다.
