# Tasks

2026-11-13 구현·격리 relocation/Windows UI 및 별도 Release 인수를 완료했다. 서버 alpha.10 gate 이후 생성한 새 배포는 1904파일, 최종 source/tooling 동결은501파일로 관리 전수 대조 PASS다. 기존 배포를 보존한다. 실제 새 물리 PC·외부 모델/기기 인수는 범위 밖 제약으로 남긴다.

- [x] 1.1 Node/Chromium/package 승인 입력과 라이선스·SHA를 확정하고 relative receipt/asset 검증 계약을 관리 검토한다. — 고유 candidate-CfWMbE의 1882파일 및 관리 `portable-candidate-review.json` 전수 대조.
- [x] 1.2 public authoring metadata.artifact 안전 해석과 alpha.9/alpha.10 호환·path escape/hash mismatch 회귀를 구현한다. — `node --test scripts/authoring-artifact.test.mjs` PASS.
- [x] 2.1 executable-relative defaults/설정 우선/비동기 payload 검증과 process browser 환경을 MVVM/Service로 구현하고 오류·취소를 검증한다. — `artifacts/multi-terminal/portable-focused-2.json` 3 PASS, cancel/dispose 대기 후 spawn0 포함.
- [x] 2.2 새 portable package 생성과 전체 파일/의존/license/source inventory를 구현하고 이전 Release를 보존한다. — `scripts/prepare-portable-runtime.mjs`, `record-portable-release.mjs`; 고유 staging과 승인167파일 복사 전후 및 전체1882파일 검증. 최종 앱 Release 자체의 gate는 3.2에 남김.
- [x] 3.1 공백·한글 경로 relocation, 개발 PATH/cache 비의존 실제 web PASS/FAIL/cancel/PNG와 변조·누락 오류를 검증한다. — `artifacts/portable-runtime/{relocation,native-verifier}/verification.json` 각각3runs; `artifacts/multi-terminal/portable-junctions.json` exit0; `native/run-ca202f47` Windows 설정/명시실행/PNG 표시 PASS. 새 물리 PC 인수와 구분.
- [x] 3.2 최종 SDK/runtime 동결 후 analyze/영향 회귀/verify/strict/Windows build·startup과 사용자 절차를 기록한다. — `portable-full-final.json`은87 PASS/3 skip/1 FAIL/exit1 원본 보존, 설정 focus 수정 후 `portable-focus-recovery.json` 2 PASS/exit0; analyze-final exit0. 서버 담당 최종 `artifacts/runtime-alpha10/verify.log` exit0를 공유 checkpoint로 재사용. Windows build exit0/최초pack EEXIST exit1/기록복구 exit0 구분; `artifacts/releases/desktop-portable-alpha10/{manifest,source-freeze,launch}.json`, `portable-native-relative.json` exit0. `docs/portable-desktop-quickstart.md` 및 validation 기록 참조. 단일 verify:all/full 성공 주장 없음.
