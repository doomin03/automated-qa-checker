# Proposal

## Why

현재 Desktop receipt는 개발 PC의 Node/Engine 절대 경로와 사용자 Playwright browser cache를 사용한다. Release 폴더만 다른 경로/PC로 복사하면 내장 runtime pin은 있어도 실제 실행 환경이 없다. 사용자 전체 구현 요청의 실제 배포 갭으로, 기존 배포를 보존하면서 경로 이동 가능한 별도 Windows 배포를 준비한다.

## What Changes

- 실행 파일 기준 상대 runtime receipt와 hash 검증된 Node/Engine·전이 의존성/Chromium payload를 조립한다.
- 사용자 명시 설정 우선, 새 사용자 기본 경로 자동 해결, 손상/누락/경로 이탈의 명시 실패를 제공한다.
- 공백·한글 포함 다른 절대 경로로 복사하고 개발 PATH/browser cache를 사용하지 않는 실제 로컬 웹 실행을 인수한다.
- alpha.10 검증 artifact가 전달되면 앱/서버 계약 정합 작업과 최종 배포 시점을 조율한다. 현재 alpha.9와 이전 Release는 수정하지 않는다.

## Capabilities

### New Capabilities

- `desktop-portable-runtime`: 고정 실행 환경의 상대 경로 배포/검증/이동 인수.

### Modified Capabilities

없음. Engine 공개 계약과 서버 schema는 변경하지 않는다.

## Impact

Checker 앱 DesktopDefaultsService/Engine bridge process environment, 앱 패키징 scripts/문서/테스트만 소유한다. counterpart: Engine 검증 alpha.10 archive/manifest 및 metadata.artifact 인계 대기; execution draft.2/authoring draft.1은 유지 예정이나 hash는 승인 후 고정한다. dependsOn: qa-desktop-ai-terminal-readiness, qa-multi-terminal-workbench. Node/Chromium 라이선스·출처/정확 hash를 배포 inventory에 포함한다. 새 소프트웨어를 사용자 PC 전역 설치하거나 기존 설정을 덮지 않는다. 별도 새 PC 실물 인수와 같은 PC의 격리 relocation 인수를 구분한다.
