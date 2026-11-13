## Purpose

재사용 가능한 템플릿 생성과 파일 블록 합성 의미를 독립 Engine 공개 계약으로 소비하며 앱은 사용자 자료, 편집 상태와 출처 표시를 유지한다.

## ADDED Requirements

### Requirement: Verified public authoring dependency
앱은 관리 승인 version/hash로 검증된 Engine 작성 API/CLI만 SHALL 소비하며 실행 schema나 합성 의미를 별도로 재정의하지 않는다.

#### Scenario: Authoring package unavailable
- **WHEN** 선택된 Engine이 templates/compose를 지원하지 않거나 hash/version 검증에 실패한다
- **THEN** 명시 지원 오류를 보여주고 기존 Dart 합성기로 조용히 우회하거나 기본 서버 pin을 바꾸지 않는다

#### Scenario: New template document
- **WHEN** 사용자가 공개 template와 입력을 선택한다
- **THEN** Engine이 만든 문서를 새 QA draft로 표시하고 대상 연결/기기 지원/실행 성공을 생성 성공으로 해석하지 않는다

### Requirement: Composition provenance and compatibility
앱은 asset/instance/link를 공개 합성 계약으로 전달하고 반환 Blueprint/XML/sourceMap/diagnostics를 원본 UI 출처와 연결하여 SHALL 표시한다.

#### Scenario: Duplicate instances and variable references
- **WHEN** 같은 asset을 두 번 사용하는 기존 지원 조합을 새 공개 Engine으로 합성한다
- **THEN** namespace/selector/variable/capture/branch/secretRef와 순서 의미를 계약 회귀로 검증하고 원본 파일/좌표/undo를 보존한다

#### Scenario: Unsupported composition
- **WHEN** 다른 target, 순환, 누락 참조 또는 공개 계약 범위 밖 자료를 합성한다
- **THEN** 블록/필드 진단을 표시하고 원문을 보존하며 일부만 실행하거나 직접 XML 열기를 막지 않는다

#### Scenario: Stale composition output
- **WHEN** 공개 compose 대기 중 QA/asset/instance/link 또는 Engine pin이 변경된다
- **THEN** 늦은 XML/sourceMap을 최신 편집본에 적용하지 않는다

### Requirement: Preserved runtime boundaries
앱은 작성·검증과 명시 실행을 구분하고 기존 배포·설치·서버 pin을 SHALL 보존한다.

#### Scenario: Explicit execution and result mapping
- **WHEN** 사용자가 새 합성 문서를 검증한 뒤 실행한다
- **THEN** immutable snapshot의 공개 run 경로와 sourceMap으로 실제 PASS/FAIL/cancel 및 증거를 확인하고 원본 변경 후 과거 run 표시를 새 draft에 혼합하지 않는다

#### Scenario: Existing workspace and release
- **WHEN** 새 앱용 작성 Engine을 설치하고 기존 workspace를 연다
- **THEN** 이전 alpha8/서버alpha6/Release를 변경하지 않고 기존 자료와 layout을 보존하며 새 배포의 version/hash와 인수 범위를 별도 기록한다
