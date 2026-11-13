# Portable Desktop 실행 안내

2026-11-13: 새 portable Release의 파일 전수 대조·기동과 상대 runtime Windows 인수를 마쳤다. 기존 alpha.9 배포는 보존하며 이 문서의 새 배포와 구분한다.

## 실행 폴더

새 배포 경로는 `artifacts/releases/desktop-portable-alpha10/Release`다. `automated_qa_desktop.exe`만 옮기지 말고 `runtime`, `portable-runtime.json`, `data`, DLL을 포함한 폴더 전체를 복사한다. Node 24.18.0, 공개 Engine alpha.10, 정확한 Playwright 의존성과 Chromium이 함께 들어간다. 사용자 작업/결과는 AppData에 저장하며 설치 폴더에 QA를 저장하지 않는다.

앱을 열면 `실행 환경 확인 중`이 표시된다. 새 복사본의 최초 전수 검증에서 약 40초가 관측됐다. 이후 같은 경로의 새 Service는 약 5초, 캐시는 약 0.65초였으며 시간 보장은 아니다. 검증 실패는 오류로 표시하며 개발 PC 경로로 자동 우회하지 않는다. `portable-runtime.json`이나 runtime 파일을 따로 수정하지 않는다.

새 작업 공간에서는 검증한 Node/CLI가 자동 선택된다. 기존 사용자의 명시 경로는 보존한다. 과거 설정을 새 배포로 전환하려면 `파일 → 실행 환경 / 연결 → 이 앱의 기본 실행 환경 사용`을 선택하고 `설정·작업 저장`을 누른다. 서버와 앱의 runtime이 다르면 공유 오류만 표시하며 로컬 결과는 그대로 보존한다.

## QA와 터미널

프로젝트를 만들고 `템플릿으로 새 QA`에서 입력·생성·검증·미리보기 후 저장한다. 가져온 XML/JSON이나 템플릿을 여는 것만으로 실행되지 않는다. 문서에서 검증한 뒤 `실행`을 눌러야 한다. 결과의 `PNG N개` 버튼으로 실제 증거 이미지를 열 수 있다.

AI 터미널은 별도 설치된 Codex/Claude의 기존 인증을 사용한다. 앱에 API 키를 넣지 않는다. `새 터미널`에서 공급자와 실행 파일을 선택하고 진단한다. 경로 기억은 프로그램 위치만 저장하며 인증정보는 저장하지 않는다. `작성 환경`에서 준비한 가이드/문맥을 확인할 수 있지만 파일 준비가 CLI의 실제 발견·모델 사용을 뜻하지 않는다. PowerShell/cmd는 일반 셸이며 AI 준비 상태를 표시하지 않는다.

현재 Codex 실제 모델 시험은 사용량 제한으로 파일 편집에 도달하지 못했다. Claude는 로컬 미설치다. 다른 프로그램·계정을 설치/로그인 완료한 것처럼 표시하지 않는다. 터미널을 닫는 UI와 세션 종료를 구분하고, `정리 미확인`이면 작성자 재지정을 막는다.

## 배포 검증 범위

같은 PC에서 한글·공백이 있는 다른 절대 경로로 복사하고 child PATH를 Windows/System32로 제한하여 실제 웹 PASS/FAIL/cancel 및 PNG를 확인했다. 앱의 초기 설정과 명시 실행·PNG 표시도 Windows native에서 확인했다. 새 물리 PC, 별도 Windows/VC runtime 설치 상태, 조직 보안 정책, 실제 Android/iOS 기기 인수는 별도다. 누락된 OS DLL이 있다면 운영체제에 맞는 공식 prerequisite를 관리자가 준비해야 하며 앱이 전역 설치를 임의 실행하지 않는다.

재현 근거와 실패 기록은 [준비 진단/portable 인수 기록](validation-desktop-readiness-portable.md)을 따른다. 저장소 재빌드는 `node scripts/prepare-portable-runtime.mjs` 후 관리 동결된 소스에서 `node scripts/build-portable-desktop.mjs`, `node scripts/record-portable-tooling.mjs`, `powershell -NoProfile -File scripts/smoke-portable-release.ps1` 순서다. 새 Release 경로가 이미 존재하면 덮어쓰지 않으므로 후속 배포는 별도 승인된 이름을 정해야 한다. 기존 배포와 개발용 installation receipt는 보존한다.
