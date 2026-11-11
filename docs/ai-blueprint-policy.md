# AI CLI와 GUI의 역할

이 정책을 GUI에 반영하는 것이 적절하다. 사용자에게 필요한 기능은 생성된 QA 정의를 가져오고, 무엇을 실행할지 확인하고, 실패 위치와 진행을 이해하는 것이다. 모델별 실행 규칙을 GUI에 넣지 않는다.

웹은 사용자 공용 시나리오·XML 전달·진행 앱이며 Flutter Desktop은 블록/Flow 또는 XML 전체를 편집해 개별 테스트를 개발·실행한다. JSON은 내부 편집 모델로 사용 가능하며 XML과 같은 엔진 정규화/검증/실행계획 경로로 연결한다. 임의 테스트 스크립트 실행을 뜻하지 않는다.

## 현재 구현

- apps/web의 React 화면에서 Blueprint JSON을 읽고 engine가 발행한 public JSON Schema로 검사한다.
- 문서의 nodes/edges를 Blueprint로 표시하고 JSON 편집/내보내기를 제공한다. import는 실행을 시작하지 않는다.
- engine 실행 폴더의 events.jsonl을 읽어 run/attempt/sequence와 blueprint hash를 확인한다.
- 이벤트 재생과 파일 따라가기로 대기/실행/성공/실패/미실행 상태를 표시한다. 실제 실패 예제 포함.
- 웹은 공개 형식으로 XML을 내보내고 Flutter는 XML/JSON/Flow를 같은 공개 Engine compile 경로로 검증한다.
- Flutter 프로젝트/QA와 지속 지침을 로컬 저장하고 설치된 Codex CLI에 일회성 변경 요청·전체 문서를 전달한다. 후보는 전체 Engine 검증과 diff를 거쳐 사용자가 적용한다. 생성/가져오기/검증은 QA를 실행하지 않는다.

## 후속 구현

현재 Codex0.162.1만 실제 생성 인수를 마쳤다. Claude adapter/실제 연결, AI 이미지 해석과 전체 대화 이력은 후속이다. API 키를 앱에 저장하지 않고 CLI 기존 인증을 사용한다. 모델별 고정 호출 옵션은 LocalAiCliService에 있으며 graph semantics로 들어가지 않는다. 지원되지 않는 CLI 옵션은 권한 확대 fallback 없이 실패한다. CLI read-only 옵션을 OS 전체 격리 보장으로 과장하지 않는다.

새 앱은 별도 alpha.8 runtime이며 서버·Agent는 alpha.6을 유지한다. 정확한 실행·저장·전송 안내는 [Desktop 시작 안내](desktop-ai-quickstart.md), 실제 인수는 [검증 기록](validation-desktop-ai.md)을 따른다.

## 진행 신뢰성

실제 snapshot hash가 다른 기록을 같은 Flow 위에 표시하지 않는다. 중복 전송은 제거하고 gap/상충 중복/서로 다른 run/잘못된 node 종료는 오류다. 기록이 없거나 실행하지 않은 분기는 미실행이며 성공이 아니다.
화면 좌표/색은 실행 정책과 분리한다. 디자인은 기능 인수 이후 수정할 수 있다.

