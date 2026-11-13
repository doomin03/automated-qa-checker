# 다중 터미널 기획·목업 검증

2026-11-12, Checker main `3e73cd1f14b0aab658748e9c9b5c1be4a87794ad`. [사용 방법](planning/multi-terminal-workbench.md), [D08](../design/mockups/product-planning/index.html#prototype/D08), [OpenSpec](../openspec/changes/qa-multi-terminal-planning/tasks.md).

## 범위

기존 홈/수신·XML 파일 조합/직접 XML을 유지하고 아래의 다중 터미널 도크와 화면설계를 확장했다. 실제 Flutter/서버/Engine 계약·pin·Release는 수정하지 않았다. 실제 CLI/PTY/네트워크/Engine 실행 없이 로컬 예시 상태만 변경한다. 현재 제품의 단일 Codex 및 미완료 Claude/AI 편집 전체 인수는 [이전 검증](validation-terminal-blueprint.md)과 구분한다.

## 검사와 산출물

| 검사 | 결과와 근거 |
| --- | --- |
| 전용 브라우저 상호작용 | `node design/mockups/xml-block-studio/verify-terminal.mjs`: 43 PASS, pageerror 0. [JSON](../design/mockups/xml-block-studio/verification-terminal.json) |
| 기존 목업 회귀 | `node design/mockups/xml-block-studio/verify-terminal-regressions.mjs`: 홈 14 / 편집기 16 / portal 94 PASS. 기존 assertion을 유지하고 출력 경로만 새로 지정. [결과](../design/mockups/xml-block-studio/verification-terminal-regressions.json) |
| 최종 화면 | 1440×900/1024×768 Blueprint+도크, XML+도크 [캡처](../design/mockups/xml-block-studio/screenshots/multi-terminal). 가로/세로 page overflow 0 |
| 웹 담당 독립 UX | controls 46/46 및 writer UI 5/5 PASS. coordination/multi-terminal-planning-20261112/ux-acceptance.json, ux-browser-second 및 writer-ui-review |
| Engine 의미 감사 | 공개 계약 소유, 세션/QA/cwd/pin/revision, invalid/nonwriter/run/cleanup 및 writer A→B→A·해제/재지정 포함 12경로 PASS. 실제 Engine 실행이 아닌 소스 기반 모델 반례 검사 |
| 관리 독립 검토 | 8캡처, 25화면/72근거 링크, localStorage 보존·review session 분리 PASS. Engine 151/Checker 822 product/config baseline 파일 byte 불변 확인 |

전용 검사는 입력·선택 범위·스크롤·동일 editor DOM, 이름 Enter/IME 이벤트, Escape 포커스, 메뉴와 종료 구별, split fallback/복원, 포인터·키보드 resize, 확대 bounds/ARIA, reduced-motion, QA 소속 고정, 작성자 양도, 늦은 후보·pin 변경·실행 중 보호, 검증 오류, 종료 정리 중/미확인을 실제 Chromium으로 조작한다. 실제 Windows IME 또는 프로세스 수명 인수는 아니다.

## 발견과 수정

- 첫 도크 높이 transition이 초기 레이아웃 계산과 충돌했다. 높이를 즉시 바꾸는 방식으로 변경해 입력/드래그 지연과 페이지 밀림을 제거했다.
- 분리된 pane의 scroll=0이 세션 기록을 덮는 문제를 연결된 pane만 기록하도록 수정했다. 접힌 도크에서 터미널 탭으로 복귀할 때도 pane 부착 전에 표시를 복구한다.
- 작성자 A→B→A 또는 해제→재지정 뒤 오래된 후보가 반영되는 반례를 writerEpoch로 차단했다. 문서 충돌과 작성권 변경의 안내 이유도 구분한다.
- 확대 bounds/ARIA·hidden override·키보드 세션 선택 포커스·문서별 split 복원·한글 조합 중 Enter를 보완했다. D06 숨겨진 canvas를 fit해 0%가 표시되는 문제는 Blueprint 표시 상태에서만 fit하도록 수정했다.
- 전용 검사 초기 fit/resize 프레임 대기 누락은 렌더 완료 후 확인하도록 수정했다. 마지막 재열기 스크롤 반례는 [실패 기록](../design/mockups/xml-block-studio/verification-terminal-failure.json)에 남겼고 최종 43개 결과와 구분한다.

## 저장소 검사

OpenSpec strict와 **이번 목업·기획·OpenSpec 범위의 diff check** PASS. 실행한 명령은 다음과 같다.

```powershell
git diff --check -- design/mockups docs/planning/multi-terminal-workbench.md docs/validation-multi-terminal-planning.md openspec/changes/qa-multi-terminal-planning
```

저장소 전체 `git diff --check`는 기존 미커밋 생성 파일 `packages/api-client/src/generated/apis/PlatformApi.ts`, `SuiteApi.ts`의 trailing whitespace 때문에 exit 1이다. 관리자의 제품 파일 SHA 비교로 이번 작업에서 해당 파일 byte가 바뀌지 않았음을 확인했으며, 기존 변경을 보존하기 위해 수정하지 않았다. 범위 지정 PASS를 전체 dirty tree의 PASS로 해석하지 않는다.

저장소 `pnpm run verify`는 기존 `.local/toolbin`을 해당 프로세스 PATH에만 추가해 실행하여 **최종 exit 0**으로 완료했다. foundation/lint/boundaries/types/packages, OpenSpec 24개 strict, build, 실제 browser UI/routes가 통과했다. 초기 foundation은 문서 링크의 query string을 경로로 취급해 실패했다. 검토 진입을 portal hash 링크로 정정했으며 [초회 로그](../artifacts/multi-terminal-planning/repository-verify-initial.log)와 [최종 로그](../artifacts/multi-terminal-planning/repository-verify-final.log)를 구분한다. 마감 문서 이후 foundation/변경 strict/위 범위 diff를 추가 확인했다.

새로고침은 실제 터미널 프로세스 복원이 아니다. 목업 세션은 페이지 수명에 한정되고 문서 저장은 기존 브라우저 예시 저장 경로를 사용한다. Engine 검증 예시는 고정 fixture에만 적용하며 사용자가 입력한 임의 XML의 실행 가능성을 판정하지 않는다.
