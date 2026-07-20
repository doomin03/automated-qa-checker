# 프로젝트 구조 및 YAML 작성 가이드

이 문서는 현재 생성된 프로젝트 구조와 YAML 파일에 무엇을 지정해야 하는지 설명합니다.

## 1. 루트 구조

```text
automated-qa-checker/
  configs/
  binaries/
  tests/
  src/
  scripts/
  docs/
  outputs/
  openspec/
  package.json
  tsconfig.json
  setup.sh
  setup.bat
```

| 경로 | 역할 |
| --- | --- |
| `configs/` | 주간 체크 대상, 기기, 크롤러, 통합 설정 YAML |
| `binaries/` | APK, APP, IPA, IPK 같은 배포 산출물 |
| `tests/` | 시나리오 YAML, 기준 이미지, 테스트 fixture |
| `src/` | TypeScript 구현 코드 |
| `scripts/` | 로컬 세팅 및 도구 확인 스크립트 |
| `docs/` | 사용법/등록법/운영 매뉴얼 |
| `outputs/` | 실행 결과 저장 위치 |
| `openspec/` | 요구사항, 설계, 작업 목록 |

## 2. configs 구조

```text
configs/
  targets/
    index.yaml
    web/
    android/
    ios/
    webos/
  crawlers/
  devices/
  defaults.yaml
  integrations.yaml
```

## 3. configs/targets/index.yaml

주간 체크 대상 목록을 등록하는 파일입니다.

```yaml
targets:
  - web/sample-web.yaml
  - android/sample-android.yaml
  - ios/sample-ios-simulator.yaml
  - webos/sample-webos.yaml
```

주의:

- 경로 기준은 `configs/targets/`입니다.
- 대상 YAML을 만들어도 여기에 등록하지 않으면 `qa:list`에 나오지 않습니다.

## 4. 웹 대상 YAML

위치:

```text
configs/targets/web/{target-id}.yaml
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
group:
  - weekly
  - web
evidence:
  screenshotOnFailure: true
  traceOnFailure: true
  saveConsoleLogs: true
  saveNetworkErrors: true
```

필드 설명:

| 필드 | 설명 |
| --- | --- |
| `id` | CLI에서 사용하는 고유 ID |
| `name` | 사람이 보는 이름 |
| `enabled` | true면 기본 조회/실행 대상 |
| `platform` | `web` |
| `executionMode` | 현재는 `local`만 사용 |
| `targetEnvironment` | 운영 체크 기준이라 `production` |
| `baseUrl` | 시작 URL |
| `crawlerConfig` | 웹 크롤링 정책 파일 경로 |
| `deviceProfile` | 사용할 브라우저/viewport 설정 ID |
| `scenarioPaths` | 실행할 시나리오 YAML 목록 |
| `group` | `weekly`, `web` 같은 실행 그룹 |
| `evidence` | 실패 시 저장할 증적 옵션 |

## 5. Android 대상 YAML

위치:

```text
configs/targets/android/{target-id}.yaml
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
group:
  - weekly
  - mobile
```

핵심 필드:

- `artifact.type`: Android는 `apk`
- `artifact.path`: APK 파일 경로
- `app.packageName`: Android 앱 패키지명
- `resetBeforeRun`: 실행 전 앱 데이터 초기화 여부
- `reinstallBeforeRun`: 실행 전 재설치 여부

## 6. iOS 대상 YAML

iOS는 `.app`과 `.ipa`를 구분해야 합니다.

| 파일 | 실행 대상 |
| --- | --- |
| `.app` | iOS Simulator |
| `.ipa` | 실제 iPhone |

### iOS Simulator APP

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

### 실제 iPhone IPA

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

주의:

- `artifact.type: ipa` + iOS Simulator 조합은 차단 대상입니다.
- Simulator에서는 `artifact.type: app`을 사용해야 합니다.

## 7. webOS 대상 YAML

위치:

```text
configs/targets/webos/{target-id}.yaml
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

## 8. Device Profile YAML

위치:

```text
configs/devices/{deviceProfile}.yaml
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

Android 예시:

```yaml
id: android-pixel
platform: android
avdName: Pixel_8_API_35
locale: ko-KR
timezone: Asia/Seoul
```

iOS Simulator 예시:

```yaml
id: ios-simulator
platform: ios
osVersion: "17.5"
locale: ko-KR
timezone: Asia/Seoul
```

실제 iPhone 예시:

```yaml
id: ios-device
platform: ios
udid: "00000000-0000000000000000"
locale: ko-KR
timezone: Asia/Seoul
```

webOS 예시:

```yaml
id: webos-tv
platform: webos
webosDeviceName: dev-tv
locale: ko-KR
timezone: Asia/Seoul
```

## 9. 시나리오 YAML

위치:

```text
tests/scenarios/{platform}/{project}/{scenario}.yaml
```

예시:

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
```

필드 설명:

| 필드 | 설명 |
| --- | --- |
| `id` | 시나리오 고유 ID |
| `name` | 사람이 보는 이름 |
| `tags` | 검색/분류용 태그 |
| `riskLevel` | `READ_ONLY`, `SAFE_WRITE`, `DESTRUCTIVE` |
| `variables` | 환경변수 또는 고정값 |
| `steps` | 실제 실행 단계 |

주의:

- 클릭/입력 뒤에는 검증 step을 두는 것을 기본으로 합니다.
- 계정/비밀번호는 YAML에 직접 쓰지 말고 `fromEnv`를 사용합니다.

## 10. 기준 이미지

위치:

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

시나리오에서는 루트 기준 경로로 지정합니다.

```yaml
image: tests/images/sample/login/login-button.png
```

## 11. 실행 명령

대상 조회:

```bash
pnpm qa:list
```

플랫폼별 조회:

```bash
pnpm qa:list --platform web
pnpm qa:list --platform android
pnpm qa:list --platform ios
pnpm qa:list --platform webos
```

그룹 조회:

```bash
pnpm qa:list --group weekly
```

실행 명령은 구현 진행 후 아래 형태로 사용합니다.

```bash
pnpm qa:run --target sample-web
pnpm qa:run --group weekly
pnpm qa:run --target sample-web --scenario sample.web.login
```
