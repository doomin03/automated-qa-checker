## ADDED Requirements

### Requirement: Reviewable desktop workspace
목업 SHALL 시나리오 목록과 Flow/XML 편집·검증·명시 실행·결과·공유 문맥을 연결하고 항상 mock data와 제안 UI임을 표시한다.

#### Scenario: Author inspects a scenario
- **WHEN** 사용자가 목록의 시나리오를 선택한다
- **THEN** 편집 화면에서 단계 선택과 XML 입력을 확인할 수 있고 실제 엔진이나 서버를 호출하지 않는다

### Requirement: Explicit validation and execution
목업 SHALL 검증과 실행을 분리하고 변경한 XML의 검증을 무효화한다.

#### Scenario: Invalid input cannot execute
- **WHEN** 사용자가 잘못된 XML을 검증하거나 검증 후 XML을 바꾼다
- **THEN** 실행이 비활성화되며 검증/변경 상태를 텍스트로 알린다

#### Scenario: Validation is not execution
- **WHEN** 유효한 데모 XML을 검증한다
- **THEN** 자동 실행하지 않고 검증된 초안·대상을 표시한 상태에서 테스트 실행 버튼을 눌러야 시뮬레이션을 시작한다

### Requirement: Honest outcome and sharing states
목업 SHALL PASS/FAIL/환경 오류/미실행을 색에 의존하지 않고 구분하며 공유 상태와 QA 결과를 독립 표시한다.

#### Scenario: Failed or interrupted demo
- **WHEN** 실패·환경 오류·중단 데모 결과가 선택된다
- **THEN** 원인과 실행하지 않은 후속 단계를 구분하고 성공으로 표시하지 않는다

#### Scenario: Share a draft
- **WHEN** 사용자가 공유 초안 제출 데모를 수행한다
- **THEN** 실제 서버 전송/발행이 아님을 명시하며 QA outcome을 변경하지 않는다

### Requirement: Local review evidence
목업 SHALL 외부 라이브러리 추가 없이 로컬 HTML로 열리며 실제 브라우저 인수와 캡처·한국어 UX 설계를 소유 폴더에 제공한다.

#### Scenario: Reviewer opens local artifact
- **WHEN** 검토자가 HTML과 UX 문서를 연다
- **THEN** 실행 방법, 현재 기능과 제안 배치의 차이, 데모 한계, 브라우저 상호작용 증거를 확인할 수 있다
