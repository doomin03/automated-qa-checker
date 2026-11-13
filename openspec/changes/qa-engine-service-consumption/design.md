# Design

## Context

Flutter Service의 실제 Node fixture에서 UI stream pause 동안 3MiB stdout 생산이 막히고 resume 후만 완료됐다. devices는 4MiB stderr도 제한 없이 소비했다. `artifacts/service-audit/before-pressure.json`이 근거다. inherited pipe fixture는 Windows에서 32초 후 이미 완료됐으므로 hang 재현은 아니다(`before-pipe.json`). 단 exit 후 EOF 대기에 기한이 없는 코드는 방어적으로 보완한다.

## Goals / Non-Goals

Goals: 공개 CLI를 유한한 프로세스·출력 소비자로 사용하고 UI 속도 때문에 Engine 실행/취소가 멈추지 않게 한다. 현재 MVVM·결과 검증을 유지한다.

Non-Goals: Engine runner/adapter 재구현, 외부 프로세스 전체 kill, 새 플랫폼 제어, HTTP 변경, 기존 Release 교체, 자동 pin 승격.

## Decisions

1. run_review Service 아래 작은 공통 process transport를 둔다. OS stdout/stderr는 시작 즉시 구독하고 UI 출력 stream과 분리한다. 출력 누계 stdout16MiB/stderr2MiB를 넘으면 실행을 실패로 닫는다. 큐가 무제한 성장하지 않도록 출력 누계로 보수적으로 제한한다. raw stderr는 저장·노출하지 않는다. Node spawn은 기존 absolute path+argument array+shell false를 유지한다.
2. 명령30초/실행120초라는 현재 기한을 exit+양쪽EOF까지 적용한다. 실행120초는 최대300초를 허용하는 Engine API와 별개의 앱 정책이다. 실행 watchdog 후에도 취소 grace10초를 부여하고 강제 종료/pipe 정리2초를 더해 최대132초로 제한한다. 명령은 제어 stdin을 지원하지 않아30초+정리2초다. await exit만 감싸는 방식은 EOF 구간을 보호하지 못하므로 채택하지 않는다. 테스트는 같은 정책의 짧은 생성자 주입 기한을 사용한다.
3. 사용자 취소는 공개 control stdin을 실행당 한 번 전송한다. 최대10초 내 정상 종료하지 않으면 직접 시작한 child만 강제 종료하고 환경 오류/하위 프로세스·장치 cleanup unknown을 표시한다. UI 구독 취소/dispose/프로토콜·출력 오류도 run에서는 같은 graceful 경로를 먼저 사용한다. 이미 시작된 취소 grace는 재시작하지 않는다. kill을 Engine cancelled로 합성하지 않는다. 협력하는 child의 하위 프로세스 정리는 fixture로 검증하되 손자 프로세스/모바일 세션 cleanup을 일반적으로 보증하지 않는다.
4. export도 같은 명령 transport를 사용해 중복된 무제한 drain을 제거한다. JSON/UTF8/출력 오류는 raw input을 포함하지 않는 EngineException으로 변환한다. 기존 snapshot/runId/attempt/sequence/exit/result/artifact 대조는 유지한다.
5. 서버 bridge는 close 기반·stdout/stderr2MiB·15초+5초 종료fallback을 이미 사용한다. 실제 fixture로 응답/오류를 점검하고 재현된 결함만 추가 수정한다. 서버는 실행 child를 소유하지 않고 Agent 실행은 별도 Engine package 소유임을 명시한다.
6. 고정 alpha.6의 실제 웹 PASS/FAIL/cancel과 큰 출력/느린 UI/경로 오류를 검증하고 시간을 기록한다. Engine의1000node 결과계약 및 assertion polling 수정 후보는 관리자가 version/hash를 승인한 뒤 별도 설치로 통합 인수한다. 현재 pin을 먼저 바꾸지 않는다.

## Risks / Trade-offs

큰 Flow 보완: 실제 widget에서 40/1000 node의 마지막 node가 고정1000px 캔버스 밖으로 잘리는 것을 재현했다(`before-large-flow.json`). node 좌표의 최대 범위로 캔버스 높이/폭을 산출하고 같은 scroll UI를 유지한다. 저장된 좌표를 그리기만으로 수정하지 않는다. 단순 선택과 실제 drag를 구분해 선택만으로 metadata가 생기지 않게 한다. 가상화·새 graph 라이브러리·목업 스타일 이식은 포함하지 않으며 1000node 빌드/스크롤/선택 시간을 인수한다.

- [제한내 이벤트 큐 메모리] → 출력 총량16MiB 제한, UI pause 여부와 무관하게 한도를 검사한다.
- [취소 후 cleanup 불명] → 유한한 응답을 제공하되 강제종료·결과누락을 환경 오류로 남긴다.
- [실제 시스템 환경 차이] → Windows 프로세스 fixture와 실제 Chromium 결과를 구분하고 모바일 실기기/Windows UI automation은 검증했다고 주장하지 않는다.

## Migration Plan

명세 strict·관리 범위 검토 후 기존 Service의 프로세스 코드만 교체한다. 기존 목업·Release·실행 계약은 보존하며 신규 공개 Engine 소비는 별도 설치 기록으로 추적한다.

이번 인수의 alpha.7은 `.local/service-audit/` 안의 version/hash별 독립 설치와 독립 파일 manifest로만 소비한다. 관리자가 전달한 tgz SHA·버전·설치 파일 hash를 검증하고 테스트의 `AQA_TEST_ENGINE_ROOT` / `AQA_TEST_ENGINE_MANIFEST`로 주입한다. 실제 Service PASS/FAIL/cancel·1000node 결과·지연 assertion 회귀를 기록한다. source pin, `.local/engine`, 앱 assets, 기존 Release와 서버/Agent 설정은 alpha.6을 유지한다. 기존 installer가 기본 설치와 source assets를 함께 수정하므로 격리 인수에는 사용하지 않는다. 이번 범위는 installer 경로 개편이나 Windows 재배포를 포함하지 않는다.

향후 운영 승격은 별도 단계다. source 계약·runtime manifest·설치 경로와 관련 테스트/실행 안내를 정합한 뒤 새 Windows Release를 별도 폴더에 빌드해야 한다. 기존 Release는 내장 alpha.6 파일 manifest로 CLI를 확인하므로 기존 설치를 덮으면 실행이 거절된다. 서버의 실행 version 및 Agent runtime/contract/hash도 정확히 일치해야 하므로 서버 manifest/CLI 쌍·활성 lease·queued job·예약 pin을 검토한 뒤 승격한다. alpha.6 앱의 로컬 실행 보존과 alpha.7 서버로의 진행 게시 호환은 별개의 조건이며 다중 버전 서버 지원을 새로 구현하지 않는다.
