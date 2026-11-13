# Tasks

## 1. 작업 공간 저장과 문서 수명

- [x] 1.1 프로젝트/QA immutable 모델·저장소·파일 서비스를 추가하고 재시작 복원, 크기/형식 오류, 실제 두 OS process 잠금·revision 충돌, Windows 기존 파일 교체 실패·중간 종료 시 원본 보존 테스트와 저장 안내를 작성한다.
- [x] 1.2 Workspace VM과 Provider 소유권을 연결하고 프로젝트/QA 생성·이름 변경·열기·명시 저장·프롬프트 저장 및 XML 무변경/프롬프트만 dirty인 전환·재시작/수명 해제 회귀로 인수한다.

## 2. 실제 Desktop 작업 공간

- [x] 2.1 프로젝트 → QA 목록 → 도킹 XML/Flow/속성/AI/결과 View를 구현하고 1440×900·1024×768 패널 접근/겹침 방지와 실제 View 탐색을 테스트한다.
- [x] 2.2 선택 ID/revision·문서 정본·실행 snapshot을 연결하고 QA 전환/실행 중 편집 경계, 완료 후 다른 QA에서 원래 결과 소속 표시, 기존 Flow undo/실행 진행/PNG 표시 회귀를 검증한다.

## 3. AI CLI 작성과 승인

- [x] 3.1 고정 Codex adapter·경로/version 진단과 설정 저장을 구현하고 인자 배열·사용자 config 격리·키 미저장·미설치 Claude·인증 실패의 fixture를 검증하며 지원 CLI 안내를 작성한다.
- [x] 3.2 고유 세션/stdin/JSONL 생성·progress·취소를 구현하고 timeout/출력 초과/비정상 종료/늦은 출력/Windows 자식 정리 회귀로 유한 종료를 인수한다.
- [x] 3.3 프로젝트/QA 지침과 네 편집 범위를 연결하고 공개 Engine 후보 전체 검증·XML/graph/root diff·명시 적용·undo를 구현한다. invalid XML/참조·범위 밖 변경·ABA/QA/선택/설정 stale·적용 후 수동편집에 대한 이전 undo 거부·자동 run 0을 테스트한다.
- [x] 3.4 설치된 실제 Codex로 QA 후보를 생성해 정상 종료·검증·미리보기 증거를 남긴다. fixture 결과와 실제 모델/인증 실패를 구분하며 실제 미인수면 이 항목을 완료하지 않는다.

## 4. 앱 전용 Engine와 통합 인수

- [x] 4.1 앱 전용 alpha.8 pin/설치/manifest+bundle asset을 조립하고 정확 version·전체 package file SHA·Chromium 설치·공개 CLI 소비를 검사한다. 기존 alpha.6 pin/설치/서버·Agent·Release 보존과 실행 안내를 기록한다.
- [x] 4.2 실제 Flutter 사용자 경로에서 프로젝트/QA 저장→AI 후보→검증/명시 적용→실제 Engine PASS·의도 FAIL·취소·단계·PNG/디자인 보고를 인수하고 재시작 저장 복원을 확인한다.
- [x] 4.3 Flutter analyze/관련 전체 회귀/Windows integration·Release build를 수행하고 별도 desktop-ai-alpha8 폴더의 전체파일 manifest·app.so·runtime asset hash·native 실행/화면 증거를 기록한다.
- [x] 4.4 새 앱 재현 절차와 실제 인수/제약을 README·local-demo·validation에 정합하고 OpenSpec strict/foundation/boundaries/diff 및 기존 목업·Release·서버 pin 보존을 확인한다.

## Workflow follow-up

- 관리 검토를 거쳐 실제 인수한 항목만 완료로 표시한다. 이전 mockup change와 실제 제품 인수를 섞지 않는다.
- 외부 모바일/Slack 인수와 서버 runtime 승격은 이번 change 완료 주장에 포함하지 않는다.

## 2026-11-10 인수 근거

12/12 완료. 세부 명령·원본 실패/회복 로그·실제 Windows UI/Codex/Engine 및 Release hash는 docs/validation-desktop-ai.md를 따른다. Flutter 전체+영향 회귀47개 통과/승인후보1개 skip을 구분하고 verify:all 단일 성공으로 보고하지 않는다.

3.2는 소유 child 종료 fixture와 별도로 **부모가 먼저 종료한 뒤 남은 자식의 강제 종료를 보장하지 못하는 한계**를 보존한다. 이 경우 cleanup_unknown 표시와 후속 생성 거절을 인수했으며 모든 자식이 종료됐다고 주장하지 않는다. 4.2 저장 복원은 기존 Provider scope 해제 후 새 scope에서 읽은 증거이며 OS 프로세스 재실행 검사와 구분한다. 디자인 보고는 설치된 alpha.8 actual design_engine/design_ui 회귀, 2.1 크기 인수는1440×900/1024×768 WidgetTester 경로다.
