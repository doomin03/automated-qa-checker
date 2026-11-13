# Tasks

## 1. 소비 호환 harness 준비

- [x] 1.1 관리 승인 후 격리 설치와 테스트의 alpha.7 하드코딩을 명시 기대 버전/contract/hash 입력으로 확장하고 잘못된 버전·hash 거부, 기존폴더 overwrite 거부 및 Dart analyze로 확인한다. 실제 소비 경계와 명령을 문서화한다.
- [x] 1.2 기존 후보 Service 회귀에 XML export/import/plan 의미동등·XML 실행을 추가하고 alpha.7 증거와 구분되는 후보별 출력 경로를 확인한다. 후보가 없을 때 인수 미실행을 명시한다.

## 2. 승인 후보의 독립 인수

- [x] 2.1 Engine 전체 verify·관리 hash 게이트 후 alpha.8을 격리 설치하고 모든 package 파일 SHA, 공개 bin/path/schema/bundle 및 package exports/타입 해석을 실제 외부 consumer로 검증한다. version/hash/file count와 명령을 기록한다.
- [x] 2.2 실제 Service PASS/FAIL/지연 assertion/paused-cancel/XML/1000node visited·unvisited 결과를 검사하고 terminal·exit·snapshot·artifact 정합과 소요시간을 별도 증거에 기록한다.
- [x] 2.3 관련 analyze·OpenSpec strict·foundation·diff 및 alpha.6 설치/Release/기본 pin·alpha.7 설치/증거 불변을 확인하고 호환 인수와 운영 승격 미수행을 구분해 보고한다.
