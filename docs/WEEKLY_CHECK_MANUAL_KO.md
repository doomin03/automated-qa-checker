# 주간 체크 등록 및 실행 매뉴얼

이 문서는 운영 웹사이트, Android APK, iOS APP/IPA, webOS IPK를 주간 체크 대상으로 등록하고 실행하는 방법을 정리한 실무용 가이드입니다.

현재 프로젝트는 로컬 실행 기준입니다. n8n, GitLab, Slack, PostgreSQL 연동은 아직 사용하지 않습니다.

## 1. 전체 등록 흐름

새로운 주간 체크 대상을 추가할 때는 아래 순서로 진행합니다.

1. 대상 YAML 파일을 `configs/targets/{platform}/` 아래에 추가합니다.
2. `configs/targets/index.yaml`에 대상 YAML 경로를 등록합니다.
3. 필요한 시나리오 YAML을 `tests/scenarios/{platform}/` 아래에 추가합니다.
4. 이미지 기반 검증이 필요하면 기준 이미지를 `tests/images/{project}/` 아래에 추가합니다.
5. 대상 YAML의 `scenarioPaths`에 시나리오 경로를 연결합니다.
6. `pnpm qa:list`로 대상이 노출되는지 확인합니다.
7. `pnpm qa:run --target {targetId}`로 실행합니다.

## 2. 대상 등록 위치

대상 등록 파일은 플랫폼별로 나눠서 관리합니다.

```text
configs/
  targets/
    index.yaml
    web/
    android/
    ios/
    webos/
```

역할은 다음과 같습니다.

| 위치 | 설명 |
| --- | --- |
| `configs/targets/index.yaml` | 실행 가능한 대상 YAML 목록을 등록하는 진입점 |
| `configs/targets/web/` | 운영 웹 URL 대상 |
| `configs/targets/android/` | Android APK 대상 |
| `configs/targets/ios/` | iOS Simulator APP 또는 실제 iPhone IPA 대상 |
| `configs/targets/webos/` | LG webOS IPK 대상 |

## 3. index.yaml 등록 방법

`configs/targets/index.yaml`에 실행할 대상 파일 경로를 추가합니다.

```yaml
targets:
  - web/sample-web.yaml
  - android/sample-android.yaml
  - ios/sample-ios-simulator.yaml
  - webos/sample-webos.yaml
```

경로는 `configs/targets/`를 기준으로 작성합니다.

## 4. 웹 대상 등록 예시

파일 위치 예시:

```text
configs/targets/web/sample-web.yaml
```

예시:

```yaml
id: sample-web
name: Sample 운영 웹
enabled: true

platform: web
executionMode: local
targetEnvironment: production

baseUrl: https://example.com
crawlerConfig: configs/crawlers/sample-web.yaml
deviceProfile: web-desktop

scenarioPaths:
  - tests/scenarios/web/sample/login.yaml
  - tests/scenarios/web/sample/main-navigation.yaml

group:
  - weekly
  - web

evidence:
  screenshotOnFailure: true
  traceOnFailure: true
  saveConsoleLogs: true
  saveNetworkErrors: true
```

웹 크롤링 설정은 별도 파일로 둡니다.

파일 위치 예시:

```text
configs/crawlers/sample-web.yaml
```

예시:

```yaml
startUrls:
  - https://example.com

scope:
  sameOriginOnly: true
  maxDepth: 3
  maxPages: 100

include:
  - /**

exclude:
  - /logout
  - /admin/**
  - /api/**
  - /**?delete=*
  - /**?remove=*
  - /**?logout=*
```

## 5. Android APK 대상 등록 예시

파일 위치 예시:

```text
configs/targets/android/sample-android.yaml
```

예시:

```yaml
id: sample-android
name: Sample Android 운영 APK
enabled: true

platform: android
executionMode: local
targetEnvironment: production

artifact:
  type: apk
  path: binaries/android/sample-app.apk

app:
  packageName: com.company.sample
  resetBeforeRun: true
  reinstallBeforeRun: true

deviceProfile: android-pixel

scenarioPaths:
  - tests/scenarios/android/sample/login.yaml
  - tests/scenarios/android/sample/home.yaml

group:
  - weekly
  - mobile
```

APK 파일은 아래 위치에 두는 것을 기본으로 합니다.

```text
binaries/android/
```

## 6. iOS 대상 등록 예시

iOS는 artifact 종류에 따라 실행 가능한 환경이 다릅니다.

| artifact | 실행 환경 |
| --- | --- |
| `.app` | iOS Simulator |
| `.ipa` | 실제 iPhone |

중요: 일반 배포용 `.ipa`는 iOS Simulator에서 실행할 수 없습니다.

### iOS Simulator APP 예시

```text
configs/targets/ios/sample-ios-simulator.yaml
```

```yaml
id: sample-ios-simulator
name: Sample iOS Simulator APP
enabled: true

platform: ios
executionMode: local
targetEnvironment: production

artifact:
  type: app
  path: binaries/ios/Sample.app

app:
  bundleId: com.company.sample
  resetBeforeRun: true
  reinstallBeforeRun: true

deviceProfile: ios-simulator

scenarioPaths:
  - tests/scenarios/ios/sample/login.yaml

group:
  - weekly
  - mobile
```

### 실제 iPhone IPA 예시

```text
configs/targets/ios/sample-ios-device.yaml
```

```yaml
id: sample-ios-device
name: Sample iOS 운영 IPA
enabled: false

platform: ios
executionMode: local
targetEnvironment: production

artifact:
  type: ipa
  path: binaries/ios/Sample.ipa

app:
  bundleId: com.company.sample
  resetBeforeRun: true
  reinstallBeforeRun: false

deviceProfile: ios-device

scenarioPaths:
  - tests/scenarios/ios/sample/login.yaml

group:
  - weekly
  - mobile
```

## 7. webOS IPK 대상 등록 예시

파일 위치 예시:

```text
configs/targets/webos/sample-webos.yaml
```

예시:

```yaml
id: sample-webos
name: Sample webOS 운영 IPK
enabled: true

platform: webos
executionMode: local
targetEnvironment: production

artifact:
  type: ipk
  path: binaries/webos/sample.ipk

app:
  appId: com.company.sample
  reinstallBeforeRun: true

deviceProfile: webos-tv

scenarioPaths:
  - tests/scenarios/webos/sample/launch.yaml

group:
  - weekly
  - tv
```

IPK 파일은 아래 위치에 두는 것을 기본으로 합니다.

```text
binaries/webos/
```

## 8. Device Profile 등록 위치

기기 설정은 `configs/devices/` 아래에 둡니다.

예시:

```text
configs/devices/web-desktop.yaml
configs/devices/android-pixel.yaml
configs/devices/ios-simulator.yaml
configs/devices/ios-device.yaml
configs/devices/webos-tv.yaml
```

웹 예시:

```yaml
id: web-desktop
platform: web

viewport:
  width: 1440
  height: 900

locale: ko-KR
timezone: Asia/Seoul
deviceScaleFactor: 1
colorScheme: light
```

## 9. 시나리오 등록 위치

시나리오는 플랫폼별로 아래 위치에 작성합니다.

```text
tests/
  scenarios/
    shared/
    web/
    android/
    ios/
    webos/
```

예시:

```text
tests/scenarios/web/sample/login.yaml
tests/scenarios/android/sample/login.yaml
tests/scenarios/ios/sample/login.yaml
tests/scenarios/webos/sample/launch.yaml
```

시나리오 파일은 대상 YAML의 `scenarioPaths`에 연결해야 실행됩니다.

## 10. 시나리오 YAML 예시

```yaml
id: sample.android.login
name: Sample Android 로그인 확인

tags:
  - weekly
  - login
  - smoke

riskLevel: READ_ONLY

variables:
  email:
    fromEnv: SAMPLE_TEST_EMAIL
  password:
    fromEnv: SAMPLE_TEST_PASSWORD

steps:
  - id: launch
    type: launchApp

  - id: wait-login-screen
    type: waitForImage
    image: tests/images/sample/login/login-title.png
    threshold: 0.88
    timeoutMs: 20000

  - id: tap-email
    type: tapPercent
    x: 50
    y: 62

  - id: input-email
    type: inputText
    valueFromVariable: email

  - id: wait-email-input
    type: assertImage
    image: tests/images/sample/login/email-filled.png
    threshold: 0.80
    timeoutMs: 5000

  - id: tap-password
    type: tapPercent
    x: 50
    y: 71

  - id: input-password
    type: inputText
    valueFromVariable: password

  - id: tap-login
    type: findImageAndTap
    image: tests/images/sample/login/login-button.png
    threshold: 0.90
    timeoutMs: 15000

  - id: wait-home
    type: assertImage
    image: tests/images/sample/home/home-header.png
    threshold: 0.85
    timeoutMs: 30000
```

주의: 클릭이나 입력만으로 성공 처리하지 않습니다. 주요 액션 뒤에는 `assertImage`, `assertText`, `assertUrl`, `waitForImage` 같은 검증 step을 추가해야 합니다.

## 11. 기준 이미지 등록 위치

이미지 기반 검증에 사용하는 기준 이미지는 아래 위치에 둡니다.

```text
tests/images/{project}/
tests/images/shared/
```

예시:

```text
tests/images/sample/login/login-title.png
tests/images/sample/login/login-button.png
tests/images/sample/home/home-header.png
```

시나리오에서는 프로젝트 루트 기준 경로로 참조합니다.

```yaml
image: tests/images/sample/login/login-button.png
```

## 12. 환경변수 등록

테스트 계정, 비밀번호 같은 값은 YAML에 직접 쓰지 않습니다.

`.env.example`을 참고해서 로컬 환경변수로 등록합니다.

```bash
export SAMPLE_TEST_EMAIL="test@example.com"
export SAMPLE_TEST_PASSWORD="password"
```

Windows PowerShell:

```powershell
$env:SAMPLE_TEST_EMAIL="test@example.com"
$env:SAMPLE_TEST_PASSWORD="password"
```

Secret 값은 로그와 리포트에 출력되면 안 됩니다.

## 13. 대상 조회 및 실행 명령

등록된 대상 조회:

```bash
pnpm qa:list
```

웹 대상만 조회:

```bash
pnpm qa:list --platform web
```

주간 체크 그룹 조회:

```bash
pnpm qa:list --group weekly
```

특정 대상 실행:

```bash
pnpm qa:run --target sample-web
```

주간 체크 그룹 실행:

```bash
pnpm qa:run --group weekly
```

특정 시나리오만 실행:

```bash
pnpm qa:run --target sample-web --scenario sample.web.login
```

환경 점검:

```bash
pnpm qa:doctor
```

연결 기기 조회:

```bash
pnpm qa:devices
```

## 14. 안전 정책

운영 서버 대상이므로 기본 실행은 `READ_ONLY` 시나리오만 허용합니다.

시나리오 위험도:

| riskLevel | 설명 |
| --- | --- |
| `READ_ONLY` | 조회, 이동, 화면 확인 중심 |
| `SAFE_WRITE` | 제한적인 쓰기 동작. 명시 옵션 필요 |
| `DESTRUCTIVE` | 결제, 주문, 탈퇴, 삭제 등. 기본 차단 |

`SAFE_WRITE` 실행이 필요할 때:

```bash
pnpm qa:run --target sample --allow-safe-write
```

다음 작업은 기본적으로 자동 실행하지 않습니다.

- 실제 결제
- 실제 주문
- 회원 탈퇴
- 운영 데이터 삭제
- 실제 문자/메일/푸시 발송
- 로그아웃 유도 크롤링
- 외부 도메인 무단 이동

## 15. 결과 파일 위치

실행 결과는 로컬에만 저장합니다.

```text
outputs/runs/{runId}/
  run-summary.json
  junit.xml
  report.html
  report.md
  targets/
```

실패 시 스크린샷, 로그, trace, video, console error, network error 등을 함께 저장합니다.

## 16. 자주 나는 실수

### index.yaml에 대상 경로를 안 넣은 경우

대상 YAML을 만들어도 `configs/targets/index.yaml`에 등록하지 않으면 `qa:list`에 나오지 않습니다.

### platform과 폴더 위치가 다른 경우

`platform: android`인 파일은 `configs/targets/android/` 아래에 있어야 합니다.

### IPA를 iOS Simulator에 연결한 경우

`.ipa`는 실제 iPhone 대상입니다. iOS Simulator에는 `.app`을 사용해야 합니다.

### 클릭 뒤 검증 step이 없는 경우

클릭 성공은 테스트 성공이 아닙니다. 클릭 뒤에 화면 변화, 텍스트, 이미지, URL 등 검증 step을 넣어야 합니다.

### Secret을 YAML에 직접 쓴 경우

계정과 비밀번호는 `variables.fromEnv`로 환경변수에서 읽어야 합니다.
