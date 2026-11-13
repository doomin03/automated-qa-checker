# 프로젝트 문서와 다중 터미널 기획

2026-11-12. [통합 D08 화면설계](../../design/mockups/product-planning/index.html#spec/D08) · [조작 화면](../../design/mockups/product-planning/index.html#prototype/D08) · [OpenSpec](../../openspec/changes/qa-multi-terminal-planning/design.md).

프로젝트 홈 → QA → 위 Blueprint/XML, 아래 터미널·출력·문제·결과 도크로 연결한다. 기존 받은 QA와 직접 XML/파일 조합을 유지한다. 단독 목업에서도 하단 터미널 탭을 눌러 시작한다.

## 화면과 동작

도크는 기본 280px이며 접기는 탭만 남긴다. 확대 후 복원은 이전 높이로 돌아간다. 경계 드래그 또는 키보드 위/아래·Home/End로 높이를 바꾼다. 두 세션의 좌우 분할은 1200px 미만에서 세션 탭으로 전환하고 넓어지면 복원한다. XML 입력/선택/스크롤과 캔버스 선택·배율을 도크 조작 때문에 다시 만들지 않는다. 메뉴의 Esc는 종료가 아니며 이름 Enter는 한글 조합 완료 후에만 저장한다.

새 세션에서 Claude Code/Codex/PowerShell/명령 프롬프트를 선택한다. 같은 provider의 여러 세션도 각각 이름·입력·출력을 갖는다. 준비 상태는 고정된 화면 예시다. 일반 셸에 AI 스킬 상태를 붙이지 않는다. 이름의 작성/검토는 OS 권한 격리를 의미하지 않는다.

세션은 생성 당시 프로젝트/QA, 시작 경로, 작성 대상, revision/hash, Engine pin에 묶인다. 셸 내부 cd 이후 현재 경로는 관측하지 않는다. 다른 문서로 이동해도 세션의 대상은 바뀌지 않는다. 홈으로 나가면 남아 있는 세션과 돌아가기 경로를 보여 준다. 현재 목업은 페이지 수명 안에서 세션을 유지하며 새로고침을 실제 프로세스 복구로 표시하지 않는다.

## 작성·검증·실행의 구분

QA당 자동 반영 작성자는 하나다. 세션 메뉴에서 지정/양도하며 정리 미확인 작성자를 다른 세션으로 몰래 대체하지 않는다. 후보 준비 후 검증 결과를 전달하는 두 단계 예시를 사용한다. 중간에 GUI 수정, 다른 QA 선택, pin 변경, 실행 중 상태가 생기면 검증 결과가 유효해도 자동 반영하지 않는다. 일반 검토 세션의 후보는 사본으로 남는다.

목업은 고정된 공개 XML 예시를 후보로 사용한다. 임의 입력 XML을 검사했다고 주장하지 않는다. 통과 예시는 직접 XML draft만 변경하고 블록 조합 원문을 덮지 않는다. 검증 오류는 마지막 정상 문서를 보존한다. 문서 반영 뒤 저장과 실제 QA 실행은 별도다. 터미널 프로세스 상태와 Engine run outcome·업무 상태를 혼합하지 않는다.

## 현재 제품과 후속 구현

현재 앱은 QA별 작업 사본, 단일 Codex PTY, QA-CONTEXT.md/engine-contract.json, 파일 감지·Engine prepare·revision 보호 기반이다. Claude·다중 세션/provider·프로젝트 스킬 자동 설치는 제품 구현/인수가 아니다. 기존 [터미널 검증](../validation-terminal-blueprint.md)의 인수 범위를 그대로 유지한다.

Engine은 공개 schema/examples/template/preset과 검증·실행 의미, Checker는 프로젝트/QA CRUD·작성 사본·provider 준비·세션 수명·충돌·UI를 소유한다. plugin은 XML 작성의 필수 전제가 아니며 provider마다 문맥/실행 인자가 다르다. cwd 설정은 프로세스 권한 격리를 보증하지 않는다.

## 담당 교차 검토

[검증 기록과 제한](../validation-multi-terminal-planning.md)에서 전용 상호작용·기존 회귀·담당 검토·대표 화면을 확인한다.

Engine의 늦은 후보·pin 변경·cwd 의미 반례를 수용해 기준 재검사와 시작 경로 표기를 넣었다. 웹 담당의 도크 overflow·hidden override·이름 입력 DOM 재생성·홈 이동 세션 소실 반례를 수용했다. 관리 검토에서 문서별 split 복원, IME Enter, 확대 separator 범위를 추가했다. 실제 조작 검토 결과는 전용 검증 기록으로 연결한다.
