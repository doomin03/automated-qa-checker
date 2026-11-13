# 프로젝트·QA·AI 작성 앱 시작

현재 PC에서는 새 앱의 **Release 전체 폴더**를 사용한다. 최종 경로는 `artifacts/releases/desktop-ai-alpha8/Release/automated_qa_desktop.exe`이며 DLL/data가 함께 필요하다. 이전 `alpha6-mvvm` 폴더와 서버/Agent 환경은 그대로 보존한다. 현재 작업의 실제 검증·hash는 [인수 기록](validation-desktop-ai.md)을 따른다.

## 내일 로컬 테스트 순서

1. Checker 루트 터미널에서 `node scripts/desktop-demo.mjs`를 실행한다. `http://127.0.0.1:4339` 테스트 페이지와 가져올 `login.xml` 절대 경로가 출력된다. 실행 중에는 터미널을 열어 둔다. 포트가 사용 중이면 명시 오류가 나며 다른 서버를 종료하지 않는다.
2. 새 앱에서 **프로젝트 만들기 → QA 만들기 → 가져오기**를 누르고 위 XML 경로를 입력한다. **검증 → 실행**으로 브라우저 테스트를 수행한다. 가져오기는 원본 파일을 덮거나 테스트를 실행하지 않는다.
3. **프로젝트 지침 · QA 요청**에서 공통 지침과 이 QA의 지속 요청을 입력하고 **저장**한다. **이번 변경 요청**은 일회성이고 QA를 바꾸면 초기화된다.
4. 변경 요청 예: `기존 동작은 유지하고 end 앞에 required:true인 screenshot 노드를 추가해 주세요.` 전체/선택/앞/뒤 범위와 XML 또는 Flow 블록을 선택한 뒤 **후보 생성**을 누른다.
5. AI가 반환한 전체 XML을 Engine이 검증한다. **변경 미리보기**에서 노드·연결·대상 변경과 원문을 확인하고 **적용**한다. 좁은 범위 요청도 전체 문서 변경일 수 있으므로 확인이 필요하다. 거절은 닫기/제안 버리기, 적용 직후 되돌리기도 가능하다. 이후 수동 편집이 있으면 오래된 undo는 거절된다.
6. 적용 후 다시 **검증 → 실행**한다. 자동 실행은 없다. **블록 / Flow**에서 진행 상태를 보고 하단 결과에서 단계/실패 이유와 검증된 PNG를 펼친다. 실행 취소는 실제 Engine 종료 결과와 정리 미확인을 구분한다.
7. 저장된 QA와 지침은 앱을 다시 열어 선택하면 복원된다. QA의 마지막 실행 결과·보고서 위치도 보존한다. 과거 보고서 전체를 자동 재생하는 기능은 이번 범위가 아니다.

## 설치 또는 checkout 경로 변경

Windows C++ toolchain, Node24.18와 고정 Flutter3.47.5/Dart3.13.4를 사용한다. 다른 checkout에는 `FLUTTER_SDK`를 지정할 수 있다. package 설치는 `corepack pnpm install --frozen-lockfile`이다.

```powershell
node scripts/install-desktop-engine.mjs <alpha.8-tgz-절대경로> <검증된-verification.json-절대경로>
node scripts/flutter.mjs run -d windows
```

공개 archive의 정확한 SHA는 `apps/app/engine-runtime-pin.json`이다. 다른 Engine checkout은 실행에 필요하지 않으며 검증된 tgz와 verification.json 배포 파일만 받으면 된다. 설치기는 패키지148파일·version·bundle을 검사하고 해당 Playwright의 Chromium을 설치한다. 종속 node_modules 전체 무결성 또는 새 OS 설치까지 보증하는 검사는 아니다.

설치는 `.local/desktop-engine/<version>/<sha>`로 격리한다. `desktop-installation.json`은 Node/CLI의 현재 PC 경로를 가진 ignored 생성 asset이며 `desktop-engine-runtime.json`/`desktop-engine-contract.json`은 새 앱 전용이다. 기존 alpha.6 asset/설치와 서버 pin은 바꾸지 않는다. checkout을 이동했거나 Node가 달라졌다면 설치를 다시 하고 앱을 다시 빌드한다. 저장한 실행 설정이 기본 경로보다 우선하므로 **실행 환경 · AI CLI**에서 경로를 확인할 수 있다. 기본 보고서 경로는 `%LOCALAPPDATA%/AutomatedQA/reports`다.

## AI 인증·저장·한계

현재 인수한 CLI는 Codex0.162.1의 기존 ChatGPT 로그인이다. 설정에서 설치·로그인 진단을 수행한다. 앱이 API 키를 받거나 저장하지 않는다. 로그인은 설치된 CLI의 정상 절차에서 수행한다. Claude는 현재 실제 adapter/인수가 없으며 선택하면 지원 제한을 표시한다.

AI에는 프로젝트 지침, QA 지속 요청, 이번 요청, 전체 XML과 공개 실행 스키마가 전달된다. 로컬 CLI도 모델 서비스를 사용하므로 입력할 내용을 확인한다. `read-only`, 사용자 config/rules 비상속과 확인된 기능 비활성 옵션을 사용하지만 모든 도구/OS 접근을 완전히 막는다고 보장하지 않는다. 도구 이벤트, 잘못된 XML, 비정상 종료·출력 제한·stale 결과는 거절하고 권한 확대 fallback은 하지 않는다.

작업 공간은 `%APPDATA%/AutomatedQA/workspace-v1/workspace.json`, 후보 세션은 그 아래 `sessions/<projectId>`다. 명시 저장, OS 잠금과 revision 검사로 충돌을 거절하며 훼손/미지원 파일은 자동 초기화하지 않는다. 작업 공간16MiB, 개별 문서1MiB, 지침/지속 요청각64KiB 한도가 있다. 파일을 직접 수정하거나 교체하기 전 앱을 닫고 백업한다. AI 정리 미확인이 표시되면 해당 CLI 작업의 종료를 확인한 후 앱을 다시 연다.

새 앱은 alpha.8, 기존 서버는 alpha.6이다. 서버 게시 버전 불일치는 로컬 실행 결과와 별도 오류다. 실 Slack 로그인, 모바일 실기기, AI의 이미지 해석, 범용 임의 shell 자동화는 이번 앱 인수에 포함하지 않는다.
