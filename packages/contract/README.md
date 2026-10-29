# 계약 경계

향후 Checker HTTP OpenAPI의 원본은 apps/server DTO/controller다. 현재는 engine-dependency.json으로 고정한 engine public contract JSON artifact를 generated에 저장하고 src/index.mjs의 schema validator로 소비한다. 엔진 실행 코드를 포함하지 않는다.

