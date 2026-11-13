# Tasks

## 1. 소비자 재현과 수명 보완

- [x] 1.1 실제 child의 UI pause/대량 stderr와 inherited pipe 시도를 기록하고 재현·미재현을 구분한다. 공통 transport의 전체기한/출력한도/즉시 drain을 구현해 focused Flutter 회귀로 검증한다.
- [x] 1.2 기존 command/export/run을 공통 transport로 연결하고 취소1회·10초 fallback·구독취소/dispose·잘못된 UTF8/JSONL·누락 결과를 실제 child 회귀로 검증한다. 운영 기한과 제한을 문서화한다.
- [x] 1.3 실제40/1000node 잘림을 재현한 뒤 동적 canvas범위를 적용하고 마지막node스크롤/선택·단순선택원문불변·기존좌표/이동undo와 build/선택 시간을 widget으로 검증한다.

## 2. 서비스 적용 평가

- [x] 2.1 서버 비실행 command bridge의 큰 응답·오류·기한을 실제 process fixture로 검증하고 발견된 Checker 결함만 보완한다. Agent 실행 소유권과 입력/설치/지원 플랫폼 제약을 기록한다.
- [x] 2.2 고정 공개 Engine 패키지의 실제 Flutter PASS/FAIL/cancel·Provider 관련 회귀와 analyze를 통과하고 시간·artifact를 기록한다. 관리 승인 alpha.7은 별도 설치 version/tgz SHA/파일 manifest를 검증하고 주입 Service PASS/FAIL/cancel·1000node 결과·지연 assertion을 인수한다. 기본 pin·기존 설치/Release·서버/Agent 설정은 alpha.6을 유지한다.
- [x] 2.3 최종 OpenSpec strict/foundation/diff 검사 및 기존 UI·Release·계약 pin 보존을 확인하고 실서비스 적용 가능 범위·남은 외부환경 인수를 보고한다.
