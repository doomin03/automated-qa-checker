# Tasks

## 1. 정책과 구조
- [x] 1.1 참조 checkout과 기존 정책을 확인하고 구현/계획 상태를 모노레포 정책에 정리한다.
- [x] 1.2 root dev/build task graph와 JS/TS 의존 경계 검사를 추가한다.

## 2. 검증
- [x] 2.1 경계 위반 회귀 검사와 고정 lockfile 설치를 검증한다.
- [x] 2.2 전체 verify 및 실제 root dev 화면 응답을 확인하고 증거·한계를 문서화한다.

근거: docs/validation.md, docs/architecture/manager-handoff.md. Flutter/서버 인수는 이 change의 완료 범위에 포함하지 않는다.
