# Design

## Context

현재 apps/web은 React Blueprint JSON 편집과 event replay를 제공하고 apps/app은 README만 있다. 관리자 전용이라는 기존 문서 표현을 최신 사용자 요구로 정정한다. Engine가 XML 투영과 qa.blueprint/v1 원본을 소유하며 alpha.2 CLI export와 엄격한 XML 검사를 준비 중이다.

## Goals / Non-Goals

XML 원문 편집기를 통해 사용자 지정 테스트를 만들고 CLI validate/plan/run으로 이어지는 최소 단위를 제공한다. drag/drop 전체 빌더는 qa-flow-editor 후속 인수이며 이번 XML 편집기로 완료 처리하지 않는다. 인증·공용 Registry 서버·직접 네트워크 전송·자동 동기화는 포함하지 않는다.

## Decisions

- 파일 교환 첫 단위: 웹 공용 또는 사용자 편집 Blueprint를 XML로 내려받기→Desktop 열기/붙여넣기→검증/계획→명시 실행→이벤트/결과 표시. 웹 serializer는 공개 XML 규격을 소비하는 선언형 문서 작성 기능이며 엔진 parser/validator 소스는 복사하지 않는다. 공개 engine CLI import/export와 round trip으로 검증한다.
- XML은 외부 표현이다. Engine가 파싱→schema/graph 검증→정규 실행계획→adapter 호출을 담당한다. 현재 실제 adapter는 Playwright이며 Appium 지원을 이 변경에서 완료했다고 표기하지 않는다. 향후 블록 편집기 역시 같은 선언형 구조를 만든다.
- Desktop는 Dart Process.start의 runInShell=false와 인자 배열을 사용한다. 설정은 사용자가 선택한 Node/CLI 경로이며 정확한 엔진 버전을 조회한다. 문서는 임시 snapshot으로 저장해 편집 중 실행 대상 변화를 막는다.
- Desktop는 engine CLI import/validate/plan을 이용하므로 XML parser를 별도로 구현하지 않는다. GUI는 명령 문자열/임의 shell/script를 제공하지 않는다.
- 결과는 해당 실행 report 하위의 파일만 읽고 runId/sequence를 추적한다. 비정상 종료·불완전 이벤트는 성공으로 표시하지 않는다. 전체 stderr 원문을 그대로 제품 로그에 누적하지 않는다.
- Flutter는 QA .tools 로컬 SDK로 정확 버전 고정하고 pnpm workspace에는 넣지 않는다. 공식 stable 태그와 doctor로 Windows 도구를 확인한다. 글로벌 PATH/설정 변경과 Visual Studio 관리자 설치를 하지 않는다.
- 사용자 추가 결정에 따라 Flutter는 기능별 MVVM + provider를 사용한다. View→ChangeNotifier ViewModel→Repository→파일/API/engine Service 경계로 조립하고 Model은 immutable이다. shell·Provider 인수는 상위 모노레포 6.1/qa-flow-editor2.1에서 공유하며 본 change의 엔진/XML 인수와 혼동하지 않는다.

## Risks / Trade-offs

- 파일 교환은 서버 실시간 공유가 아님 → UI와 문서에 실제 전달 방법을 표시한다.
- XML 원문 편집은 시각적 블록 편집기 아님 → 기존 qa-flow-editor drag/drop tasks는 미완료 유지한다.
- Windows signal 취소 동작 불확실 → 프로세스 종료를 graceful 취소 성공으로 단정하지 않고 후속 엔진 계약 검증으로 분리한다.
- SDK 다운로드/Windows 도구 누락 → 가능한 analyze/test와 실제 실패 증거를 구분하며 Windows build 미검증을 숨기지 않는다.
