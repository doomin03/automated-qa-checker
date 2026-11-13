# Desktop UX 검토 목업

최신 검토안은 **[차콜 Blueprint 작업 공간](blueprint-workspace/index.html)**이며 [설계·캡처·검증 안내](blueprint-workspace/README.md)를 함께 확인한다. 아래 밝은 목업과 기존 캡처는 이전 인수 자료로 보존했다.

[목업 열기](index.html) · [UX 설계](UX.md) · [브라우저 인수 결과](verification.json)

`index.html`을 Chrome 또는 Edge에서 직접 연다. 서버나 별도 설치가 필요 없다. 모든 값과 진행은 **예시 데이터**이며 실제 Engine 실행·장치 연결·로그인·공유 전송은 없다. Flutter 제품에는 이 스타일을 이식하지 않았다.

## 살펴보는 순서

1. 시나리오 목록에서 **로컬 로그인 QA**를 연다. 다른 두 행은 목록 구성 예시다.
2. Flow 단계를 선택해 오른쪽 속성을 확인하거나 XML 탭에서 원문을 편집한다.
3. **검증**을 누른다. XML 문법·blueprint 루트만 확인하는 목업 검사다. XML을 수정하면 검증이 무효화된다.
4. 화면에 표시된 현재 초안·대상을 보고 **테스트 실행**을 누른다. 기본 예시는 환영 문구 확인에서 FAIL이며 다음 단계는 미실행이다.
5. 편집 화면 아래 **환경 정보 및 목업 상태 설정**을 열면 PASS/FAIL/환경 오류/미실행 데모를 바꿀 수 있다. 진행 중에는 **실행 중단**을 사용할 수 있다.
6. **공유 초안**에서 제출 흐름을 확인한다. QA 결과와 별도이며 실제 전송하지 않는다.

입력·결과는 현재 브라우저 창의 메모리에만 있다. 새로고침하면 초기화된다. 토큰이나 비밀값을 입력하지 않는다.

## 주요 화면

| 화면 | 캡처 |
| --- | --- |
| 시나리오 목록 | [01-scenarios.png](screenshots/01-scenarios.png) |
| 기본 Flow / 검증 전 | [02-flow-unrun.png](screenshots/02-flow-unrun.png) |
| XML 편집 | [03-xml.png](screenshots/03-xml.png) |
| 검증 오류 | [04-validation-error.png](screenshots/04-validation-error.png) |
| 실행 중 | [05-running.png](screenshots/05-running.png) |
| FAIL / 후속 단계 미실행 | [06-failed.png](screenshots/06-failed.png) |
| PASS | [07-passed.png](screenshots/07-passed.png) |
| 환경 오류 | [08-environment-error.png](screenshots/08-environment-error.png) |
| 시작 전 취소 / 미실행 | [09-unrun.png](screenshots/09-unrun.png) |
| 공유 초안 입력 | [10-share-draft.png](screenshots/10-share-draft.png) |
| 공유 초안 제출 데모 | [11-sharing.png](screenshots/11-sharing.png) |
| 1024px 너비 | [12-compact.png](screenshots/12-compact.png) |

## 재현과 출처

Checker 의존성을 설치한 환경에서 저장소 루트를 cwd로 사용한다. 기존 고정 Playwright만 사용하며 새 패키지를 추가하지 않았다.

```powershell
node design/mockups/desktop/verify.mjs
corepack pnpm exec openspec validate qa-desktop-ui-mockup --strict --no-interactive
```

Chromium 상호작용 18항목 PASS, 캡처 12개, 페이지 오류 0개, 외부 HTTP 요청 0개. 1440×1000 및 1024×900에서 가로 넘침이 없다. 캡처는 전체 문서이므로 좁은 화면은 세로로 길어질 수 있다. 이 인수는 실제 제품/Engine 인수를 대체하지 않는다.

`fixture.js`는 설치된 공개 Engine alpha.6의 `contracts/releases/qa-blueprint-0.1.0-alpha.6.xml` 내용을 JavaScript 문자열로 담았다. XML 의미나 노드를 새로 만들지 않았으며 원문 대조를 테스트한다. Flow 표시는 그 예시의 시작·종료를 제외한 다섯 동작을 읽기 좋게 나타낸 고정 시각화다. XML 변경을 Flow로 자동 변환하지 않는다.

변경 범위: 이 폴더와 [qa-desktop-ui-mockup 명세](../../../openspec/changes/qa-desktop-ui-mockup/proposal.md). 제품 소스·SDK·계약·lockfile 변경, 원격 게시, Figma 연결, commit/push는 없다.
