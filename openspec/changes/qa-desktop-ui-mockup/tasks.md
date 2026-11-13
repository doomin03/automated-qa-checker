## 1. Review mockup

- [x] 1.1 시나리오 목록·Flow/XML 편집과 밝은 단색 작업 화면을 구현한다.
- [x] 1.2 검증 무효화·한 번의 명시 실행·상태별 진행/결과·공유 초안 데모를 연결한다.
- [x] 1.3 실제 Chromium 상호작용·레이아웃 인수 및 화면 캡처를 저장한다.
- [x] 1.4 한국어 UX 설계·실행 방법·현재 기능/제안 범위·검증 근거를 문서화하고 strict 검증한다.

## Acceptance

`node design/mockups/desktop/verify.mjs`: Chromium 상호작용 18항목 PASS, 1440×1000/1024×900 가로 넘침 없음, 캡처 12개, 외부 HTTP 요청/페이지 오류 0개. 실제 제품이나 Engine 실행이 아닌 로컬 목업 인수다. 실행 명령·공개 fixture 출처·한계는 `design/mockups/desktop/README.md`와 `UX.md`, 결과는 같은 폴더 `verification.json`에 기록했다. 검토용 산출물이며 Flutter 이식·원격 게시·commit/push는 수행하지 않았다.
