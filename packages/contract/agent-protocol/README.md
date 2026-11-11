# Agent HTTP 계약

`v0.1.0-draft.1/openapi.json`은 관리 검토된 HTTP baseline이며 현재 서버 구현 완료를 뜻하지 않는다. Engine 실행 DSL은 이 파일에서 정의하지 않는다. engineEventJson/resultJson/blueprintJson은 고정 공개 Engine schema로 별도 검증한다.

현재 검토 SHA-256: `8c25e3c853f3b8d24003464d2ddc55a20675b7ac3f741a46c238a50ce4149490`. 이전 `754b35b51db3c75584d1d01343cdcecfa5c2c27674f86b60fac54a53d356f9de`는 recovered 상태와 nullable required operatorRecovery 추가로 superseded됐다. alpha.6 candidate1 실제 Nest checkpoint는 이전 hash의 독립 증거로 보존하며 새 wire 인수와 혼합하지 않는다. 이전 `f3cf367e6f19f03e0020945bdd84c5781b8b08ae2e9e0533f7eb60874c94d5c8`은 reconcile completion receipt 복구와 reporting/owner instance 분리로 superseded됐다.
이전 검토 hash `7797f040c5279b72c7216fbfcd9082a421eaba12c2df6a43693db4528b8db96d`는 allowProduction 필수 boolean/default false 추가로 superseded됐다. 최초 b0156ab 초안은 scope/byte paging 보완 전이며 소비하지 않는다.

`node packages/contract/agent-protocol/validate-draft.mjs`는 hash/ref/operationId, 예시8개 및 unknown/missing/traversal/음수 cursor를 검증한다. 예시는 공개 alpha.5 plan으로 만든 snapshot이며 실제 실행 기록은 아니다. 예시 engineContractSha256은 공개 `qa-contract-0.1.0-alpha.5.json` bytes의 `b183b90e0a8d93ab531b10ca409a4e657003fd85812a131f97479695283a5370`이다.

실행 규칙·cleanup/reconcile/history/receipt semantics는 [설계](../../../openspec/changes/qa-agent-protocol/design.md), 완료 기준은 [tasks](../../../openspec/changes/qa-agent-protocol/tasks.md)를 따른다. DTO 구현 후 실제 offline OpenAPI slice와 이 baseline의 의미적 동등성을 검증한다. 변경은 관리 검토·새 hash 전달 후 반영한다.
