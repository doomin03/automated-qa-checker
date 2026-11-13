# Desktop Blueprint 작업 공간 목업

[새 목업 열기](index.html) · [UX 설계](UX.md) · [검증 결과](verification.json) · [이전 밝은 목업](../index.html)

프로젝트 → QA 목록 → Blueprint 편집을 차콜 Desktop 도킹 화면으로 제안한다. `index.html`을 Chrome/Edge에서 직접 열 수 있다. 실제 AI·Engine 실행·장치·서버 연결은 없다. 제품 Flutter는 변경하지 않았다.

## 검토 순서

1. **커머스 품질 검증** 프로젝트 → **로컬 로그인 QA**를 연다.
2. 중앙 캔버스의 블록을 선택한다. 빈 공간 드래그로 이동하고 휠/+/−로 줌, **전체 보기**로 화면을 맞춘다. **탐색**, **속성·AI** 버튼으로 패널을 접고 펼친다.
3. XML 탭의 node 구간을 선택하면 동일 블록이 속성·AI에 선택된다. 원문을 수정하고 **원문 반영**을 누르면 현재 모델이 바뀐다. 미반영 입력도 QA별 메모리에 남는다.
4. 오른쪽 AI의 **설정**에서 가짜 키를 채우거나 가짜 값으로 폼을 검토하고 **연결 시연**을 누른다. 입력은 password 마스킹되며 실제 연결·영속 저장·전송은 없다. 실제 키를 입력할 필요가 없다.
5. **선택 수정 / 앞 삽입 / 뒤 삽입 / 전체 흐름 변경**을 고른 뒤 **제안받기**를 누른다. 자유 요청은 대화에 표시하지만 범위별 고정 예시 변환을 사용한다. 변경 node·삽입 edge·결과 XML을 확인하고 적용 또는 취소한다.
6. **되돌리기**는 직전 XML을 정확히 복원한다. 문서/선택/QA가 바뀐 제안은 적용되지 않는다. 변경·undo 후에는 다시 검증한다.
7. **검증 → 테스트 실행**으로 snapshot의 node 진행·하단 타임라인/로그를 확인한다. 하단 결과 선택기는 데모 전용이다. 실행 중에는 편집/QA 이동이 잠기며 **중단**할 수 있다.

모든 편집·실행·키 입력은 현재 창 메모리에서만 유지한다. 새로고침하면 초기화된다. 공유·실제 provider 인증·키 영속 저장·제품 스타일 이식은 구현하지 않았다.

## 화면 캡처

| 화면 | 캡처 |
| --- | --- |
| 프로젝트 목록 | [01-projects](screenshots/01-projects.png) |
| 프로젝트의 QA 목록 | [02-qa-list](screenshots/02-qa-list.png) |
| Blueprint 작업 공간 | [03-workspace](screenshots/03-workspace.png) |
| 공급자 키 등록 폼 · 가짜 값 마스킹 | [04-provider-settings](screenshots/04-provider-settings.png) |
| XML node 선택 | [05-xml-selection](screenshots/05-xml-selection.png) |
| 선택 수정 제안 | [06-ai-modify](screenshots/06-ai-modify.png) |
| 앞 삽입 제안 | [06-ai-before](screenshots/06-ai-before.png) |
| 뒤 삽입 제안 | [06-ai-after](screenshots/06-ai-after.png) |
| 전체 흐름 변경 제안 | [06-ai-whole](screenshots/06-ai-whole.png) |
| 미지원 XML 원문 보존 | [07-unsupported](screenshots/07-unsupported.png) |
| 실행 중 snapshot | [08-running](screenshots/08-running.png) |
| FAIL과 후속 미실행 | [09-failed](screenshots/09-failed.png) |
| 1024×768 · 탐색 접기 | [10-compact](screenshots/10-compact.png) |
| 1024×768 · 패널 펼치기 | [10-compact-expanded](screenshots/10-compact-expanded.png) |

## 검증

Checker 저장소 루트에서 기존 설치된 Playwright와 공개 Engine을 사용한다. 새 dependency는 없다.

```powershell
node design/mockups/desktop/blueprint-workspace/verify.mjs
corepack pnpm exec openspec validate qa-desktop-blueprint-workspace --strict --no-interactive
```

- Chromium 검사 30개 PASS. 네 AI 범위·취소·undo·stale, unsupported·잘못된 참조, JSON 구역의 XML 자식 거부, pending 원문 보존, snapshot 분리, 공급자 등록·해제·새로고침 초기화를 포함한다.
- 설치된 공개 CLI의 `validate`와 `plan`을 초기 원문 및 네 범위 결과에 각각 호출: **10회 PASS, run 호출 0회**. [evidence](evidence/)에 5개 XML이 있다. 브라우저의 목업 검사는 public CLI 전체 validator를 대체하지 않는다.
- 1440×900와 1024×768에서 page overflow와 패널 bounding box 비중첩, canvas 최소 너비, 접기/펼치기 및 전체 보기 node 가시성을 검사했다.
- 처음에는 1024 접기에서 grid 자동 배치가 center를 0px 열에 놓아 오른쪽 패널과 겹쳤다. 명시적 grid 열/행으로 고쳤으며 페이지 overflow만 검사하던 회귀에 실제 패널 geometry 검사를 추가했다. 현재 캡처와 결과는 수정 후 자료다.
- 외부 HTTP 요청·영속 저장 API 호출·페이지 오류 0. CSP `connect-src 'none'`. 인수 키는 가짜 값이며 캡처에서 마스킹했다.
- 이전 목업 원문/검증/캡처 19개를 [checksum 기록](previous-mockup-manifest.json)과 대조했다. 이전 README의 새 진입 링크 외 과거 자료는 변경하지 않는다.

관리자가 1440 작업 공간·AI 제안·프로젝트/QA·키·실행 및 수정 후 1024 접기/펼치기 캡처를 직접 검토해 인수했다. 이 결과는 실제 AI 응답이나 제품 QA 실행의 증거가 아니다.
