# 사용자 등록 및 실행 워크플로우

이 문서는 사용자가 주간 체크 대상을 등록하고 바로 테스트까지 실행하는 표준 흐름입니다.

현재 구현 상태에서는 YAML 로드, 대상 조회, 시나리오 로드, JSON 결과 생성까지 연결되어 있습니다. 실제 Appium/Playwright 기반 화면 조작 Runner는 로드맵에 따라 추가 구현됩니다.

## 빠른 시작

처음 세팅:

```bash
npm install
```

등록 대상 확인:

```bash
npm run qa:list
```

대상 실행:

```bash
npm run qa:run -- --target sample-android
```

주의: `npm run` 뒤에 CLI 옵션을 넘길 때는 `--`를 한 번 넣어야 합니다.

```bash
npm run qa:run -- --target sample-android --scenario sample.android.login
```

pnpm을 사용하는 경우:

```bash
pnpm qa:list
pnpm qa:run --target sample-android
```

## 전체 워크플로우

```text
1. 앱 또는 웹 대상 준비
   ↓
2. configs/devices/에 실행 환경 등록
   ↓
3. configs/targets/{platform}/에 대상 YAML 작성
   ↓
4. tests/scenarios/{platform}/에 시나리오 YAML 작성
   ↓
5. tests/images/에 기준 이미지 추가
   ↓
6. configs/targets/index.yaml에 대상 등록
   ↓
7. npm run qa:list 로 등록 확인
   ↓
8. npm run qa:run 으로 실행
   ↓
9. outputs/runs/{runId}/에서 결과 확인
```

## 1단계: 앱 또는 웹 대상 준비

웹은 운영 URL을 준비합니다.

```text
https://example.com
```

앱 산출물은 플랫폼별 폴더에 둡니다.

```text
binaries/android/sample-app.apk
binaries/ios/Sample.app
binaries/ios/Sample.ipa
binaries/webos/sample.ipk
```

파일 타입별 실행 환경:

| 파일 | 실행 환경 |
| --- | --- |
| APK | Android Emulator 또는 실제 Android |
| APP | iOS Simulator |
| IPA | 실제 iPhone |
| IPK | webOS Emulator 또는 실제 webOS TV |

## 2단계: Device Profile 등록

실행 환경은 `configs/devices/`에 YAML로 등록합니다.

```text
configs/devices/android-pixel.yaml
```

```yaml
id: android-pixel
platform: android
avdName: Pixel_8_API_35
locale: ko-KR
timezone: Asia/Seoul
```

대상 YAML의 `deviceProfile` 값은 여기 있는 `id`와 맞아야 합니다.

```yaml
deviceProfile: android-pixel
```

## 3단계: 대상 YAML 작성

대상 파일은 플랫폼별 폴더에 작성합니다.

```text
configs/targets/web/
configs/targets/android/
configs/targets/ios/
configs/targets/webos/
```

Android 예시:

```text
configs/targets/android/sample-android.yaml
```

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

필수로 신경 쓸 값:

| 필드 | 설명 |
| --- | --- |
| `id` | 실행할 때 쓰는 대상 ID |
| `enabled` | true여야 기본 조회/실행 대상 |
| `platform` | 파일이 있는 폴더와 같아야 함 |
| `artifact.path` | 실제 앱 파일 경로 |
| `deviceProfile` | `configs/devices/`의 profile id |
| `scenarioPaths` | 실행할 시나리오 YAML 경로 |
| `group` | `weekly`, `mobile` 같은 묶음 실행 태그 |

## 4단계: 시나리오 YAML 작성

앱 테스트 스크립트는 `tests/scenarios/` 아래 YAML로 작성합니다.

```text
tests/scenarios/android/sample/login.yaml
```

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

중요한 규칙:

- 클릭, 입력만 작성하면 성공으로 보지 않습니다.
- 주요 액션 뒤에는 `assertImage`, `assertText`, `assertUrl`, `waitForImage` 같은 검증 step을 추가합니다.
- 계정/비밀번호는 직접 쓰지 않고 `fromEnv`로 연결합니다.

## 5단계: 기준 이미지 등록

이미지 검증용 파일은 `tests/images/` 아래에 둡니다.

```text
tests/images/sample/login/login-title.png
tests/images/sample/login/email-filled.png
tests/images/sample/login/login-button.png
tests/images/sample/home/home-header.png
```

시나리오에서는 프로젝트 루트 기준 경로로 씁니다.

```yaml
image: tests/images/sample/login/login-title.png
```

## 6단계: index.yaml에 대상 연결

대상 YAML을 만들었다면 반드시 `configs/targets/index.yaml`에 추가해야 합니다.

```yaml
targets:
  - android/sample-android.yaml
```

여기에 없으면 `qa:list`에 나오지 않습니다.

## 7단계: 등록 확인

npm:

```bash
npm run qa:list
npm run qa:list -- --platform android
npm run qa:list -- --group weekly
```

pnpm:

```bash
pnpm qa:list
pnpm qa:list --platform android
pnpm qa:list --group weekly
```

## 8단계: 실행

대상 단위 실행:

```bash
npm run qa:run -- --target sample-android
```

그룹 단위 실행:

```bash
npm run qa:run -- --group weekly
```

시나리오 단위 실행:

```bash
npm run qa:run -- --target sample-android --scenario sample.android.login
```

현재 구현 상태에서는 실제 앱 조작 Runner가 없으므로 실행 결과가 `NOT_IMPLEMENTED`로 나옵니다. 이는 YAML 로드와 결과 생성 파이프라인이 연결되었고, 실제 플랫폼 Runner가 아직 구현되지 않았다는 뜻입니다.

## 9단계: 결과 확인

실행 후 결과는 아래에 생성됩니다.

```text
outputs/runs/{runId}/
  run-summary.json
  targets/
    {targetId}/
      summary.json
```

상태 의미:

| 상태 | 의미 |
| --- | --- |
| `PASSED` | 기대한 동작 정상 |
| `FAILED` | 서비스/앱 기능이 기대와 다름 |
| `BROKEN` | 환경, 설정, 기기, 바이너리 문제 |
| `SKIPPED` | 조건상 실행 제외 |
| `NOT_IMPLEMENTED` | YAML은 로드됐지만 Runner가 아직 없음 |

## 자주 막히는 지점

### qa:list에 대상이 안 나오는 경우

확인할 것:

- `configs/targets/index.yaml`에 대상 경로를 넣었는지
- 대상 YAML의 `enabled`가 `true`인지
- `platform` 값과 폴더가 맞는지

### qa:run에서 scenario file does not exist가 나오는 경우

대상 YAML의 `scenarioPaths` 경로가 실제 파일과 일치하는지 확인합니다.

### iOS Simulator에서 IPA를 실행하려는 경우

불가능한 조합입니다.

- Simulator: `.app`
- 실제 iPhone: `.ipa`

### 실제 앱 클릭이 안 되는 경우

현재 단계에서는 실제 Appium Runner가 아직 구현되지 않았습니다. 다음 로드맵에서 Android/iOS Runner가 구현되면 YAML step이 실제 앱 조작으로 연결됩니다.
