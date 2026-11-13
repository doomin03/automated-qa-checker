# Tasks

2026-11-13 readiness 구현과 alpha.10 portable 통합 Release 인수를 마쳤으며 이 change는 4/7 전체 조건 완료다. 기존 D08 구현·Release는 보존한다. 실제 Codex 복구 1회는 사용량 한도로 XML 원문 변경 없이 종료하여 2.1은 미완료다. Claude 미설치·실제 OS IME 인수도 구분해 남긴다. 전체 완료/자동 archive로 표시하지 않는다.

## 1. Preparation and implementation

- [x] 1.1 provider 설정 Model/Repository/VM을 기존 DI에 연결하고 실행 파일 선택·로컬 경로 기억·공식 설치 안내/재진단 UI 및 잘못된 설정·지연 응답·저장 실패 회귀를 구현한다. — `artifacts/multi-terminal/readiness-focused.json` exit0/10 PASS 및 `readiness-analyze-2.json` exit0; 새 전용 회귀 4개 포함.
- [x] 1.2 세션별 가이드/계약/문맥 상태와 호출 안내 복사·미제출 입력을 연결하고 session/epoch stale 및 준비≠발견≠모델 사용 구분을 검증한다. — guide bytes/hash 변조 회귀 `readiness-focused`와 실제 TerminalDock dialog를 사용한 `readiness-environment-ui-2.json` actual exit0/1 PASS. exact 복사/newline0, A dialog 중 B 선택 시 A에만 미제출 입력, 열린 dialog 및 guide IO 대기 중 epoch 변경의 write0/오류·disabled, 원문보존/run0 확인. 첫 fixture fake/real zone Completer timeout 로그는 보존. PTY/모델은 명시 fixture이며 실제 AI 활용 증거와 구분.

## 2. Actual user-path acceptance

- [ ] 2.1 Windows의 격리 세션에서 실제 Codex skill 발견/문맥 사용·XML 및 JSON 편집→GUI 자동 반영→명시 PASS/FAIL·PNG를 인수하고 자동 run0/충돌/stale 및 원 QA/hash 귀속을 기록한다.
- [ ] 2.2 설치·인증 가능한 Claude 환경에서 동일 실제 편집 경로를 인수한다. 미설치/미인증/계정 부재이면 명시 제한으로 남기며 task 완료로 표시하지 않는다.
- [ ] 2.3 800×600/text1.5의 setup 복구 접근 및 실제 Windows 한글 IME·붙여넣기·Ctrl+C/Delete focus 격리를 인수한다. fixture 키 이벤트와 OS IME 증거를 분리한다.

## 3. Documentation and release

- [x] 3.1 gap-mapping의 옛 terminal 항목을 전체 조건별 증거와 연결해 정합하고 README/AGENTS/시스템설계 현재 버전 문구와 과거 인수 기록을 구분한다. archive는 별도 완료 조건을 따른다. — gap-mapping 후속표, 앱README/portable 시작안내 및 서버 담당 공용 문서 현재 alpha.10/legacy 분리.
- [x] 3.2 영향 회귀/analyze/verify/strict와 portable/runtime 정합 change의 alpha.10 통합 Release·source/SDK/vendor/config·startup manifest 및 기존 배포/dirty 보존을 인수한다. 실제 모델/계정 미인수는 남긴다. — `qa-desktop-portable-runtime` 3.2 및 `docs/validation-desktop-readiness-portable.md`의 원본 full 실패/targeted 복구, analyze/verify 재사용, 실제1904파일 배포/501파일freeze/native-relative/launch 근거. 준비 기능 구현과 외부 모델 성공은 분리.
