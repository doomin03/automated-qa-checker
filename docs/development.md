# 개발 환경

Node 24.18.0, pnpm 10.34.8, Turbo 2.11.10, OpenSpec 1.14.2. apps/web은 React 19.3.1, Vite 8.3.5를 사용한다. Flutter SDK는 이번 웹 관찰 화면에 필요하지 않다.

## 명령

- npx --yes pnpm@10.34.8 install --frozen-lockfile --ignore-scripts
- npx --yes pnpm@10.34.8 run dev: 구현된 JS 앱 개발 task 실행. 현재 웹만 실행한다.
- npx --yes pnpm@10.34.8 run build: 선행 package build 후 JS 앱 build. 현재 웹만 빌드한다.
- npx --yes pnpm@10.34.8 run check:boundaries: 앱·package·FSD 의존 방향 및 회귀 검사.
- npx --yes pnpm@10.34.8 run dev:web: loopback 4318 개발 화면.
- npx --yes pnpm@10.34.8 run build:web: production static build.
- npx --yes pnpm@10.34.8 exec playwright install chromium
- npx --yes pnpm@10.34.8 run verify: foundation/의존 경계/OpenSpec, package tests, JS build, browser UI 인수.

pnpm은 root, apps/web, packages/contract를 현재 package로 인식한다. Dart 경로는 workspace에서 제외한다.
전체 경로·계약·설정 규칙은 [모노레포 정책](architecture/monorepo-policy.md)을 따른다. Flutter/Nest 실행 명령은 실제 앱 생성 시 추가하며 현재 명령이 성공해도 두 앱의 인수를 뜻하지 않는다.

## 외부 엔진 계약

scripts/import-engine-contract.mjs BUNDLE_PATH RELEASE_METADATA_PATH는 두 파일의 version/SHA-256을 검사하고 public schema/예제 데이터만 generated에 저장한다. engine source/로컬 file dependency를 추가하지 않는다.
현재 bundle은 local-preview이며 원격 publish가 아니다. 재생 UI만 활성화되어 runtimeIntegrationEnabled=false다.

## 로컬 파일 진행

사용자가 engine run 폴더의 blueprint.json을 가져오고 events.jsonl을 선택한다. 파일 따라가기는 브라우저 File System Access 지원과 사용자 파일 선택 권한이 필요하다. 미지원 브라우저는 수동 재업로드를 사용한다.
마지막 JSONL record가 쓰는 중이면 완료된 줄까지만 읽는다. 한 run/attempt만 선택하며 파일 크기는 16 MiB까지다.

## 검증의 한계

UI E2E는 실제 Chromium에서 import/replay/오류/따라가기 갱신을 검사한다. 파일 선택 OS dialog 자체는 자동화하지 않고 FileSystemHandle substitute로 파일 변화 경로를 검증한다. Flutter MVVM/Provider shell의 별도 실행·검증은 [Flutter 안내](architecture/flutter-mvvm.md)를 따른다. Flutter 엔진 연결/서버/OIDC/원격 Agent는 아직 없다.

