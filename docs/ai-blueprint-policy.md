# AI CLI와 GUI의 역할

이 정책을 GUI에 반영하는 것이 적절하다. 사용자에게 필요한 기능은 생성된 QA 정의를 가져오고, 무엇을 실행할지 확인하고, 실패 위치와 진행을 이해하는 것이다. 모델별 실행 규칙을 GUI에 넣지 않는다.

웹은 사용자 공용 시나리오·XML 전달·진행 앱이며 Flutter Desktop은 블록/Flow 또는 XML 전체를 편집해 개별 테스트를 개발·실행한다. JSON은 내부 편집 모델로 사용 가능하며 XML과 같은 엔진 정규화/검증/실행계획 경로로 연결한다. 임의 테스트 스크립트 실행을 뜻하지 않는다.

## 현재 구현

- apps/web의 React 화면에서 Blueprint JSON을 읽고 engine가 발행한 public JSON Schema로 검사한다.
- 문서의 nodes/edges를 Blueprint로 표시하고 JSON 편집/내보내기를 제공한다. import는 실행을 시작하지 않는다.
- engine 실행 폴더의 events.jsonl을 읽어 run/attempt/sequence와 blueprint hash를 확인한다.
- 이벤트 재생과 파일 따라가기로 대기/실행/성공/실패/미실행 상태를 표시한다. 실제 실패 예제 포함.
- XML/YAML은 engine CLI에서 import로 JSON을 만든 뒤 GUI에 넣는다.

## 후속 구현

웹 임의 Blueprint의 XML 내보내기 수정은 미검증 상태로 보존되어 있다. 현재 사용자 지시에 따라 원본 모노레포 OpenSpec 이관·검토를 먼저 한다. 파일 전달 첫 단위와 서버 전달/진행 자동 수신 전체 목표는 각각 handoff/platform changes에서 추적한다.

Flutter Desktop에 같은 정책과 고정 engine CLI bridge를 구현한다. 사용자가 허용한 실행 파일과 인자 배열로 호출하고, schema 검증 → 변경 비교 → 실행 요청 순서로 연결한다.
향후 Claude/Codex 등 provider adapter를 만들 경우 명령·입출력 계약을 별도 모듈로 두고 모델별 옵션을 graph semantics에 넣지 않는다. 선택한 CLI의 인증/사용량은 별도로 표시한다. 이번 버전은 해당 CLI를 직접 호출하지 않는다.

## 진행 신뢰성

실제 snapshot hash가 다른 기록을 같은 Flow 위에 표시하지 않는다. 중복 전송은 제거하고 gap/상충 중복/서로 다른 run/잘못된 node 종료는 오류다. 기록이 없거나 실행하지 않은 분기는 미실행이며 성공이 아니다.
화면 좌표/색은 실행 정책과 분리한다. 디자인은 기능 인수 이후 수정할 수 있다.

