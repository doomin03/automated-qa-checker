# 엔진 계약 소비

현재 engine 0.1.0-alpha.1 / contract 0.1.0-draft.1의 **local-preview public JSON artifact**를 소비한다. [engine-dependency.json](../../packages/contract/engine-dependency.json)의 exact version/artifact/SHA-256으로 generated/engine-contract.json을 검증한다.

엔진 source/submodule/file dependency를 추가하지 않는다. bundle은 스키마와 예제 데이터만 포함한다. 현재 runtimeIntegrationEnabled=false이며 웹 화면은 검사·event 재생만 수행한다. 아직 원격 npm/GitHub release는 없다.

## 현재 연결

engine aqa run → run 폴더의 blueprint.json/events.jsonl → 사용자가 웹 화면에 파일 선택 → schema/hash/run/attempt/sequence 검사 → node 상태 표시.
파일 따라가기는 브라우저에서 사용자가 고른 파일을 주기적으로 읽는다. 자동 실행 요청이나 model CLI 호출은 아니다.

## 이후 직접 실행

Flutter bridge에서 executable + argument array로 고정 engine CLI를 실행하고 stdout JSONL/stderr를 분리한다. version/capability 검사 후 사용자 요청에 따라 실행한다. 취소·비정상 종료·최종 result 누락·artifact 경로를 검증한다.
원격 Agent/lease/replay는 P4의 별도 authenticated protocol이며 현재 file replay UI를 서버 연동 완료로 간주하지 않는다.

