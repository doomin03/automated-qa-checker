# 공개 Engine 비교 보고서 fixture

alpha6-ux-profile-report.json은 Engine alpha.6 candidate-1의 독립 설치 소비자 실제 Chromium PASS run `run_6e24b1f8-e114-4985-966c-9300b4198410/check-0.json`의 원문 bytes다. SHA256 `407707b9e2ab7673b65a63cf65930a32b4f049dc7de693815cdf1b22b0b50b49`.

출처는 Engine candidate-1 verification의 installed-preset이며 관리자가 원본을 대조했다. profileHash가 있고 referenceHash가 없는 정상 UX 계약을 소비하는 비교 정책 회귀에 사용한다. 동일 run을 실제 두 번 실행한 증거로 사용하지 않으며 테스트 DB의 별도 run rows는 정책 fixture다. Checker runtime pin을 이 candidate로 승격하지 않는다.
