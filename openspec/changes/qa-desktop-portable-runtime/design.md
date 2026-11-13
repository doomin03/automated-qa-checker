# Design

## Context

현재 `DesktopDefaultsService.load`는 asset desktop-installation.json의 nodePath/cliPath 절대 문자열을 사용한다. `CliProcess.start`는 부모 환경의 Playwright cache를 상속한다. `install-desktop-engine.mjs`는 package 자체 payload를 고정하지만 전이 node_modules와 Node/browser 배포물은 Release에 포함하지 않는다. 기존 동작은 개발 PC 인수로 유효하며 다른 PC 배포 완료로 해석하지 않는다.

## Decisions

### D1. 배포 구조와 검증된 입력

새 배포 root는 Flutter Release와 `runtime/node`, `runtime/engine`, `runtime/browsers`, 라이선스/출처 및 상대 receipt를 포함한다. package manager cache/기존 workspace/개인 installation receipt/credentials를 복사하지 않는다. Node 실행 파일+LICENSE의 승인된 출처/버전/hash를 먼저 확보한다. 임의 PATH node를 공식 배포 검증 완료라고 표시하지 않는다. Chromium은 설치 Engine의 정확 Playwright 버전으로 별도 destination에 내려받아 해당 배포만 inventory한다. 모든 transitive dependency와 browser 파일을 inventory에 포함하고 package 승인 manifest와 별도로 범위를 기록한다.

### D2. 상대 경로와 신뢰 범위

receipt는 executable root 기준 상대 경로만 허용한다. 절대/UNC/drive/.. segment/빈 path/심볼릭 링크·junction 경로 이탈을 거절하고 canonical containment를 확인한다. 승인된 runtime package files/execution bundle/authoring bundle와 receipt를 생성 asset에 고정해 외부 receipt와 교차 검증한다. Node/브라우저/의존성 bytes 무결성은 별도 file manifest로 검사한다. 이는 로컬 payload 정합성 검사이며 OS 코드서명/적대적 로컬 관리자 방어라고 하지 않는다. 검사는 UI를 막지 않는 비동기 작업이고 오류를 표시한다. 별도 검증 Cancel UI는 제공하지 않는다. 기존 실행 취소/Service dispose 요청은 검증 await 이후 프로세스 spawn 전에 다시 검사하여 늦은 실행을 막는다. 읽기 전용 isolate 검증은 완료될 수 있지만 취소된 실행을 재개하지 않는다.

전체 payload SHA 검사는 별도 isolate에서 최초 수행한다. 이후 전체 경로·파일 수·크기·mtime/ctime fingerprint가 같을 때만 같은 세션의 해시 결과를 재사용하고, 변경되면 전수 해시를 다시 검사한다. 동시 요청은 같은 검증 Future에 합류한다. 이는 timestamp까지 위조하는 로컬 공격자를 방어하는 코드서명이 아니다. packager는 매번 고유 staging을 만들고 기존 staging의 잔존 파일을 새 manifest로 승인하지 않는다. 복사 전후 Engine package files를 승인 manifest와 대조하며, 새 staging의 Playwright `.links`와 npm `.package-lock.json`만 실행 불필요한 설치 metadata로 제외한다. 원래 설치/캐시는 건드리지 않는다.

최초 relocation의 순수 Dart SHA 전수 검증은 38,102ms였다(원래 evidence 보존). 관리 승인 최적화는 Dart isolate가 먼저 Node 경로의 canonical containment/중간 링크 부재와 승인 공식 node.exe SHA를 확인하고, 그 Node로 앱에 고정된 builtin fs/crypto verifier만 실행한다. manifest는 stdin JSON, root는 별도 argv이며 shell이나 사용자 스크립트를 평가하지 않는다. 부모 환경을 상속하지 않고 SystemRoot/TEMP만 전달해 NODE_OPTIONS/NODE_PATH 주입을 차단한다. verifier stdout/stderr는 각각 1MiB 이하, 총 60초 후 소유 process만 종료한다. Node SHA 사전 확인은 공식 hash와 경로·size·mtime/ctime fingerprint가 같은 경우만 재사용한다. 검증 원인 오류를 표시하되 파일 내용/credential은 출력하지 않는다. 최초 Node 사전 검증 시간과 총 시간을 새 evidence에 기록한다. 외부 CLI 경로에는 이 verifier나 bundled browser를 강제하지 않는다.

### D3. 설정과 프로세스

기존 사용자 명시 nodePath/cliPath를 우선한다. 자동 기본값에는 출처와 당시 기본 경로를 함께 저장하여 다음 배포에서 검증된 상대 defaults로 갱신한다. 사용자가 경로를 변경한 경우에는 명시 설정으로 고정한다. 출처 기록이 없는 과거 설정은 자동 생성이었다고 추측하지 않고 보존하며, 명시적인 '번들 기본값 사용' 동작으로 전환한다. portable receipt가 존재하지만 손상됐으면 과거 개발 경로로 무음 fallback하지 않는다. 결과/report는 쓰기 가능한 사용자 AppData에 저장한다. 읽기 전용 배포 위치에서도 실행 가능해야 한다.

Engine Service는 검증된 bundled CLI 사용 시에만 `PLAYWRIGHT_BROWSERS_PATH`를 해당 bundle browser root로 전달한다. 전역 환경변수/사용자 cache는 수정하지 않는다. 외부 명시 CLI에 bundled browser를 강제 연결하지 않는다. public process argument-array/timeout/cancel/immutable run snapshot 정책은 유지한다. 일반 AI terminal 프로필은 기존 외부 설치 CLI를 그대로 사용하며 Codex/Claude credentials나 CLI 프로그램을 번들에 복사하지 않는다.

### D4. alpha.10 작성 metadata

작성 bundle 경로는 `authoring-release.json.artifact`를 package root 내 엄격한 상대 경로로 해석한다. 새 `qa-authoring-0.1.0-draft.1-engine-0.1.0-alpha.10.json`와 기존 alpha.9 metadata를 모두 지원한다. 경로 검증 뒤 metadata hash와 pin authoringBundleSha256 및 승인 설치 manifest의 해당 파일 hash를 대조한다. contractVersion만으로 파일명을 조립하는 기존 가정은 제거한다. 검증 gate 전 archive 설치/pin 승격은 하지 않는다.

### D5. 인수와 통합 순서

readiness 집중 인수와 독립적으로 packager/receipt 테스트를 진행하고, SDK/서버/runtime pin이 관리 동결된 뒤 마지막 앱 build/Release 한 번으로 합친다. 새 별도 배포를 공백·한글 경로에 복사하고 PATH에서 Node를 제외한 실행 환경에서 startup→로컬 fixture 웹 PASS/FAIL/cancel→PNG를 확인한다. 자체 browser root만 존재하는 조건을 확인하며 기존 cache를 삭제하거나 이름 변경하지 않는다. Node/Engine/browser/receipt 변조·누락 및 사용자 설정 우선·실행 오류 표시도 검증한다. 같은 PC의 relocation은 새 Windows 설치/VC runtime/정책이 다른 물리 PC 인수와 다르다.

## Open Questions

- 2026-11-12 관리 승인: Node 24.18.0 공식 win-x64 ZIP SHA256 `0ae68406b42d7725661da979b1403ec9926da205c6770827f33aac9d8f26e821`, node.exe `9a4eb5f1c29c6a2e93852ead46b999e284a6a5ca8bab4d4e241d587d025a52de`. 출처 `https://nodejs.org/dist/v24.18.0/SHASUMS256.txt`; 다운로드 bytes를 다시 검사한다.
- 관리 승인 alpha.10 archive `0476445261b2596954167f335968d8bbb0a513867c930553604ba9b2b1c780e3`, execution bundle `b99337961c1477549d9dd52b65f6ec888d47679f4735d3025435ee06881f93c1`, authoring bundle `65c2510ad9ff79fe69888209f7180a7006afe9698f1721388744aee7870bb139`. 앱 pin은 Checker 앱 담당자만 변경하며 서버/Agent pin은 별도 담당·관리 게이트다.
- Windows 재배포에 필요한 VC runtime의 bootstrap 포함 또는 prerequisite 명시 방식은 실제 clean 환경 증거를 보고 결정한다. 임의 전역 설치는 하지 않는다.
- 서버/Agent alpha.10 승격은 별도 관리 계약 작업이며 portable packager가 서버 설정을 쓰지 않는다.
