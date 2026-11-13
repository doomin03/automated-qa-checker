# 디자인·UX와 모바일 실행

현재 소비는 Engine alpha.5 / contract0.3.0-draft.1 공개 배포본이다. 실행 schema·preset·비교 알고리즘은 Engine 소유이며 Checker는 공개 bundle과 CLI를 소비한다. 정확한 pin은 packages/contract/engine-runtime.json 및 engine-dependency.json에 있다. alpha.4의 늦은 screenshot 수집 경쟁은 alpha.5에서 수정됐고 관리자의 별도 probe로 검증했다. 최종 Checker 제품 검증은 docs/validation.md를 따른다.

## 로컬 기준 입력

먼저 XML 또는 Flow에서 대상 URL과 selector 별칭을 작성한다. 실행 패널의 기준 폴더에 절대 경로를 입력하고 PNG·수치 기준 연결을 선택한다. PNG 상대 경로, 명시 수치 JSON 상대 경로, 새 기준 ID, viewport/DPR/browserVersion/OS/locale/theme/readiness를 직접 지정한다. 기본 폼은 end가 정확히 하나인 Flow의 end 진입 직전에 검사 노드를 연결한다. 여러 end는 임의 선택하지 않고 명시 XML/블록 연결을 안내한다.

PNG는10MiB, 수치 JSON은1MiB, 규칙128개까지다. 수치 파일은 다음처럼 Engine measurementRules에서 source를 제외한 배열이다. source 문서와 SHA-256은 선택한 파일 bytes에서 기록한다. 이미지에 없는 수치를 추정하지 않는다.

```json
[{"id":"entry-width","selectorId":"entry","metric":"bbox.width","expected":100,"tolerance":0}]
```

metric은 공개 계약의 bbox.x/y/width/height, gap.horizontal/vertical, font-size이며 단위 CSS px다. gap에는 otherSelectorId가 필요하다. 폰트 고급 입력은 공개 profile.fonts 배열이다. 빈 배열은 명시 웹폰트 byte 검증을 요구하지 않는다는 뜻이고 시스템 fallback까지 동일함을 보장하지 않는다. Engine가 profile/PNG/hash/font/좌표 의미를 최종 검증한다. 폴더 밖·symlink 탈출·잘못된 JSON/PNG는 거부한다.

같은 기준 ID는 자동 덮어쓰지 않는다. 새 ID/version으로 명시 선택해야 하며 기존 report·PNG 원본을 수정하지 않는다. 실행에 사용되는 reference snapshot과 파일 hash는 엔진에서 고정·검증한다. 검토 화면에 다른 파일을 입력해도 이미 실행 중인 snapshot은 바뀌지 않는다.

## 공개 UX 팩

현재 검증한 문서의 target/selectors에 공개 bundle.presets를 바인딩한다. web-input과 web-history-back의1.0.0 version/hash/requiredCapabilities를 표시하고 실제 공개 CLI `preset expand ID --preset-version VERSION --bindings FILE --out FILE`로 XML을 생성한다. 전개만으로 실행하지 않는다. back 기대 URL/selector와 입력값을 사용자가 지정한다. hit-test는 매핑한 웹 요소의 합성 overlay/클릭 가능성 검사이며 OS 키보드나 앱 전체 UX 인수가 아니다.

secretRef는 실제값을 XML에 넣지 않는다. 실행 프로세스는 앱 시작 환경을 상속한다. Engine은 참조를 영숫자 외 문자를 밑줄로 바꾸고 대문자로 만든 `AQA_SECRET_` 환경 변수에서 읽는다. 예를 들어 login.password는 AQA_SECRET_LOGIN_PASSWORD다. 비밀 환경값을 소스·UI 원문·로그에 붙여넣지 않는다. 이 설정이 없는 참조는 실행 시 실패하며 생성 성공을 실행 성공으로 표시하지 않는다.

## 결과 표시

공유 bridge에서 run/attempt/snapshot/sequence/terminal/exit code와 결과를 대조하고 artifact realpath·size·SHA-256을 확인한다. 검증된 PNG bytes만 Image.memory로 표시한다. check-report의 node/kind/verdict/reason, expected/actual/tolerance 및 baseline/actual/diff 참조를 보여주며 제공되지 않은 diff를 만들지 않는다. baseline mismatch와 미지원은 blocked, 실제 비교 차이는 failed, 실행/수집 장애는 infra_error로 구분한다. 단순 창 초기화 smoke는 이 사용자 경로 인수가 아니다.

## Appium

target.platform android/ios, launchTargets 앱 ID, 플랫폼별 selector는 Blueprint다. endpoint/udid/deviceName은 별도 로컬 Appium 설정 JSON에 두고 실행 패널에 절대 경로만 입력한다. 공개 `devices --target android|ios --appium-config FILE`는 정적 configured 검사이며 targets가 빈 배열이어도 실제 기기 부재를 확정하지 않는다. connectionVerified=false를 실제 성공으로 바꾸지 않는다. 명시 run에서만 session을 시작한다.

로컬 W3C fixture로 CLI→adapter 요청과 cleanup을 검증한 것은 실기기 인수가 아니다. 현재 실제 Appium 서버·Android/iOS 기기는 미검증이다. TV/WebView/실제 OS 키보드 표시 assertion도 지원 완료로 표시하지 않는다.

## 재현과 범위

Flutter test/design_engine_test.dart는 실제 브라우저 PNG/수치 PASS·시각 FAIL·UX 및 기준 불변을, design_ui_test.dart는 실제 폼→CLI→PNG 표시를 검증한다. appium_bridge_test.dart는 실제 설치 CLI와 로컬 W3C protocol fixture만 검증한다. 개별 결과는 artifacts/flutter-design, flutter-design-ui, flutter-appium에 기록한다. [최신 검증 기록](../validation.md)의 성공/미완료 상태와 별도 최종 Windows build를 확인한다.
