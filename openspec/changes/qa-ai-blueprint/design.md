# Design

## Context
사용자는 AI CLI에서 만든 문서를 GUI에서 가져와 Blueprint로 진행을 확인하려 한다. apps/web의 첫 관찰 기능은 사용자 QA 웹의 일부이며 Flutter Desktop의 테스트 개발·실행을 대체하지 않는다. 기존 관리자 전용 표현은 2026-10-29 사용자 역할 보충에 따라 정정했다.

## Goals / Non-Goals
기능 우선으로 JSON Blueprint 검사/편집/내보내기, 노드·edge 보기, JSONL event 재생과 로컬 파일 따라가기를 구현한다. 스타일 디자인, 모델 인증/CLI 자동 호출, 서버/Flutter 실행은 별도 단계다.

## Decisions
엔진의 버전/hash가 고정된 public contract JSON artifact만 소비한다. 엔진 소스는 복사하지 않는다. 가져오기만으로 실행하지 않으며 실제 실행은 별도 aqa CLI에서 요청한다. GUI는 실행 event와 blueprint hash, run/attempt/sequence를 확인하고 미방문 노드를 미실행으로 표시한다.

## Risks / Trade-offs
브라우저의 파일 따라가기는 사용자가 파일 선택 권한을 부여해야 한다. 지원하지 않는 브라우저는 수동 event 파일 불러오기를 제공한다. 현재는 loopback 개발 화면이며 조직 인증/배포 제품이 아니다.

