# Design

## Context

Checker에는 React web과 공개 엔진 계약 package가 있고 Flutter/Nest는 README만 있다. 참조 monorepo-setup은 engine/web npm workspace를 구현했으며 더 넓은 Flutter/Nest 설계는 계획이다.

## Goals / Non-Goals

앱의 배치와 의존 규칙을 문서·검증으로 고정한다. 이번 변경에서 Flutter/Nest 제품 구현과 toolchain 인수를 완료했다고 취급하지 않는다.

## Decisions

pnpm 명시적 package 목록과 독립 엔진을 유지한다. root dev는 persistent/non-cached task, build는 ^build 선행 의존과 dist 산출물을 사용한다. TypeScript AST로 JS/TS import를 검사하고 manifest 그래프로 앱 의존·순환을 거부한다. 검사는 기존 verify/CI에 연결한다.

## Risks / Trade-offs

JS 정적 검사는 Dart나 실행 시 파일 접근을 검증하지 않는다. exact export와 명시적 import만 지원하고 alias/computed import는 정책 확장 전 거부한다. 누락된 Flutter/서버 빌드를 성공으로 집계하지 않는다.
