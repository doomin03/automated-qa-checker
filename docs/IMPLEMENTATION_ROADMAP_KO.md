# 구현 로드맵

이 문서는 사용자가 대상을 등록하고 바로 테스트할 수 있는 상태까지 가기 위한 구현 순서입니다.

## 현재 완료된 범위

현재 완료된 기능:

- TypeScript 프로젝트 기본 구조
- `AGENTS.md` 프로젝트 지침
- 설정 YAML 스키마
- Target Registry 로더
- Device Profile 로더
- Scenario YAML 스키마
- `qa:list`
- `qa:run`, `qa:scenario` 최소 연결
- JSON 결과 생성
- setup `.sh`, `.bat` helper
- 한글 등록/실행 매뉴얼

현재 `qa:run`은 YAML을 읽고 결과 파일을 생성하지만 실제 앱이나 웹 화면 조작은 아직 수행하지 않습니다. 실제 Runner가 없을 때는 `NOT_IMPLEMENTED`로 보고합니다.

## 1차 목표: 등록 즉시 검증 가능한 로컬 파이프라인

목표:

- 사용자가 YAML을 잘못 등록했을 때 실행 전에 명확한 오류를 받는다.
- 대상, device profile, scenario path, artifact path를 한 번에 검증한다.

구현 작업:

1. `qa:doctor` 구현
2. `configs/integrations.yaml` 로드 및 disabled 검증
3. `scenarioPaths` 전체 존재 여부 검증
4. `artifact.path` 존재 여부 검증
5. IPA + iOS Simulator 차단 검증
6. Secret 환경변수 누락 검증

완료 기준:

```bash
npm run qa:doctor
```

명령으로 설정 문제를 미리 확인할 수 있어야 합니다.

## 2차 목표: Android APK 기본 실행

목표:

- Android APK를 Emulator 또는 실제 기기에 설치하고 앱을 실행한다.
- YAML step 일부를 실제 Appium 명령으로 실행한다.

구현 작업:

1. Android device discovery
2. APK path validation
3. adb install/reinstall/reset 처리
4. Appium UiAutomator2 session 생성
5. `launchApp`, `terminateApp`, `screenshot` step 구현
6. `tapPercent`, `inputText`, `hideKeyboard` step 구현
7. 실패 시 screenshot, logcat 저장
8. 세션 cleanup 보장

완료 기준:

```bash
npm run qa:run -- --target sample-android
```

명령으로 실제 Android 앱이 실행되고 최소 시나리오가 동작해야 합니다.

## 3차 목표: 이미지/좌표 기반 검증

목표:

- 앱 내부에 테스트 ID가 없어도 이미지와 좌표로 주요 화면을 확인한다.

구현 작업:

1. screenshot capture abstraction
2. image match result model
3. `waitForImage`
4. `assertImage`
5. `assertImageNotVisible`
6. `findImageAndTap`
7. `tapRelativeToImage`
8. threshold 실패 시 비교 이미지 저장

완료 기준:

```yaml
- type: waitForImage
  image: tests/images/sample/login/login-title.png
  threshold: 0.88
```

위 step이 실제 화면 기준으로 통과/실패해야 합니다.

## 4차 목표: iOS Simulator APP 실행

목표:

- `.app` 파일을 iOS Simulator에 설치하고 XCUITest로 시나리오를 실행한다.

구현 작업:

1. iOS Simulator discovery
2. simulator boot
3. `.app` artifact validation
4. IPA + Simulator 차단
5. `xcrun simctl install`
6. Appium XCUITest session 생성
7. 공통 YAML step 실행
8. 실패 증적 저장

완료 기준:

```bash
npm run qa:run -- --target sample-ios-simulator
```

명령으로 Simulator APP이 실행되어야 합니다.

## 5차 목표: 실제 iPhone IPA 실행

목표:

- 연결된 실제 iPhone에서 앱 실행 가능 여부를 검증한다.

구현 작업:

1. 연결된 iPhone UDID 확인
2. trust/developer mode 안내
3. WebDriverAgent readiness 확인
4. bundle id launch
5. IPA installer adapter 추상화
6. 자동 설치 미설정 시 `BROKEN` + `IOS_IPA_INSTALLATION_NOT_CONFIGURED`

완료 기준:

```bash
npm run qa:run -- --target sample-ios-device
```

명령으로 실제 iPhone 대상이 명확히 실행되거나 설정 문제를 `BROKEN`으로 반환해야 합니다.

## 6차 목표: 웹 크롤링

목표:

- 운영 웹 URL을 안전하게 탐색하고 기본 장애를 찾는다.

구현 작업:

1. Playwright Chromium crawler
2. same-origin 제한
3. include/exclude 규칙
4. URL normalize
5. maxDepth/maxPages/timeout
6. HTTP status, broken image, console error, page error 검사
7. 실패 screenshot/trace 저장

완료 기준:

```bash
npm run qa:crawl -- --target sample-web
```

명령으로 안전한 크롤링 결과가 생성되어야 합니다.

## 7차 목표: 웹 시나리오 및 Visual Mode

목표:

- 로그인, 메뉴 이동 같은 명시 시나리오와 Flutter Web/Canvas 화면을 검증한다.

구현 작업:

1. role/text/label/css/xpath selector
2. web `clickText`, `clickRole`, `assertText`, `assertUrl`
3. visual scenario에서 image/coordinate step 재사용
4. console/network evidence 저장

완료 기준:

```bash
npm run qa:scenario -- --target sample-web --scenario sample.web.login
```

명령으로 웹 사용자 흐름이 실행되어야 합니다.

## 8차 목표: 리포트 고도화

목표:

- 운영자가 결과를 바로 볼 수 있는 리포트를 만든다.

구현 작업:

1. JUnit XML
2. Markdown report
3. HTML report
4. 실패 증적 링크
5. Secret redaction
6. latest run alias 또는 조회 명령

완료 기준:

```bash
npm run qa:report -- --run latest
```

명령으로 읽기 쉬운 리포트를 재생성할 수 있어야 합니다.

## 9차 목표: webOS

목표:

- IPK 설치와 앱 실행 가능 여부를 검증한다.

구현 작업:

1. ares CLI 확인
2. webOS device discovery
3. IPK path validation
4. `ares-install`
5. `ares-launch`
6. 화면 자동화 미지원 기능은 `NOT_IMPLEMENTED`

완료 기준:

```bash
npm run qa:run -- --target sample-webos
```

명령으로 IPK 설치/실행 결과가 확인되어야 합니다.

## 추천 구현 순서

실제 작업은 아래 순서가 가장 안정적입니다.

1. `qa:doctor`와 설정 검증 강화
2. Android APK 실행
3. 이미지/좌표 엔진
4. iOS Simulator
5. 실제 iPhone
6. 웹 크롤러
7. 웹 시나리오
8. 리포트
9. webOS

이 순서로 가면 사용자는 Android 기준으로 가장 빨리 “등록 후 실제 앱 테스트”를 확인할 수 있습니다.
