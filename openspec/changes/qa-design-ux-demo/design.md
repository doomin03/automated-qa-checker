# Design

## Context

[proposal](proposal.md)의 목표를 따른다. 현재 웹은 JSON 편집·graph·JSONL 재생/파일 추적, Desktop은 XML/JSON 파일 편집 MVVM/Provider shell까지 검증되었다. Desktop CLI·시각 비교·기본 UX 팩·서버는 미구현이다. 웹 XML export 중간 변경도 아직 미검증이다. 이번 명세 작성은 기존 코드나 pin을 변경하지 않는다.

기존 [플랫폼 설계](../../../docs/architecture/platform-design.md)의 ReportBaseline은 비교 가능한 이전 PASS→현재 FAIL 집계이며 디자인 정답 이미지가 아니다. P4 전체를 앞당기지 않고 동일 Run/Artifact 개념과 버전 원칙만 재사용한다.

## Goals / Non-Goals

**Goals:** 서버 없이 로컬 PNG+명시 수치 JSON 및 웹 URL/profile을 바인딩하고 실제 Engine 측정·비교 결과를 Flutter에서 확인한다. 기본 입력·버튼·텍스트 출력이면 충분하다. 독립 CLI 데모와 Desktop 제품 인수를 분리한다.

**Non-Goals:** Figma 직접 API/OAuth, 디자인 작업·복잡한 이미지 오버레이 편집기, 서버 업로드/Registry/자동 진행 동기화, Appium/실제 OS 키보드, 전체 drag/drop builder. React 사용자 웹의 공용 XML 전달·진행 역할은 유지하며 이번 데모의 실행 주체는 Desktop이다.

## Decisions

### D1. Engine draft를 소비하고 공개 release 이후에 연결한다

Counterpart는 `automated-qa-engine/openspec/changes/qa-design-ux-demo`다. Engine 담당 초안의 `qa.designReference/v1`, `qa.checkPreset/v1`, `qa.checkReport/v1`은 현재 제안 이름이며 여기서 필드/schema를 재정의하지 않는다. optional references/target.profile, assertImage/assertLayout/assertInViewport/assertHitTarget/assertFocused/assertUrl/browserBack도 초안이다. 기존 Blueprint/XML 노드 구조를 유지하고 공개 Engine validate/plan 경로를 사용한다. Checker 안에 parser·측정·diff 실행기를 복제하는 대안은 소유권 충돌 때문에 제외한다.

현재 Checker는 engine alpha.1/contract draft.1을 소비한다. Engine alpha.2 독립 패키지 증거는 새 디자인/UX 기능 인수가 아니며 새 runtime/contract version/hash는 pending이다. 계약 필드·preset ID·오류/경로·capability의 정본은 Engine의 reviewed draft→구현/contract test→공개 release 순서로 받는다. 소비 가능 release 없이는 신규 실행을 활성화하지 않는다.

### D2. 명시적 기준·매핑과 작은 프리셋

PNG·JSON 경로와 resource root, 기준 version/hash, 화면/상태/selector, URL/profile을 입력한다. 규칙의 단위·좌표계·허용 오차는 공개 계약으로 검증하며 이미지에서 없는 수치를 역산해 기준으로 확정하지 않는다. 기준 PNG는 Figma export 또는 목업일 수 있으나 Figma 원본 접근은 요구하지 않는다. 픽셀 비교와 명시 수치 검사를 개별 결과로 보여준다.

Engine 기본 팩에서 back/focus/input/overlay 경로를 선택하고 필요한 입력을 채운다. back의 기대 목적지·상태, focus의 대상/복귀, input의 값과 기대 결과, overlay의 열기/닫기/가림 기대를 명시한다. 키보드 가림은 실제 OS 검사를 후속으로 두고, 브라우저 합성 overlay fixture를 사용하면 그 한계를 이름·결과에 표시한다. 완전 자동 추측 대신 필수 입력 오류를 제공한다.

`aqa preset list`, `aqa preset expand ID --bindings FILE --out FILE`, `--reference-root`는 Engine 제안이며 고정 CLI 계약으로 오인하지 않는다. 확정 후 팩 전개 결과를 기존 XML 편집 경로에 연결한다. 임의 스크립트·shell 입력은 제공하지 않는다.

### D3. 기존 MVVM 기능 경계를 확장한다

[기존 Flutter 구조](../../../docs/architecture/flutter-mvvm.md)를 유지한다. `features/design_baselines`는 로컬 기준·매핑, `scenario_editor`는 팩 선택/바인딩/XML 초안, `features/run_review`는 진행/검사/증거 상태를 맡는다. 각 기능의 immutable Model은 편집·표시 상태이며 Engine schema 원본이 아니다. View→ChangeNotifier ViewModel→Repository→파일/CLI Service를 사용하고 `app/providers` MultiProvider에서 구성한다. 필요 없는 빈 계층은 만들지 않는다.

CLI Service는 기존 bridge 하나를 재사용하며 executable/args, runInShell=false, stdout JSONL/stderr 분리, version/capability 확인을 따른다. secret은 secretRef로 전달하고 UI/로그에 원문을 누적하지 않는다. VM은 busy 중 중복 실행을 거부하고 dispose 후 notify를 막는다. 화면 종료·취소 시 프로세스/구독 lifecycle을 명확하게 정리하고 종료 증거 없이 성공을 만들지 않는다.

### D4. 기준과 결과를 snapshot으로 묶는다

사용자가 실행한 정의·기준·profile/version/hash를 snapshot으로 연결한다. baseline 원본을 실제 이미지로 자동 교체하지 않는다. 새 기준 선택은 명시적 새 버전이며 기존 실행·검토 기록을 보존한다. 로컬 데모는 새 기준 등록/승인 workflow를 필요로 하지 않는다.

Engine가 제공한 baseline/actual/diff 참조를 run/attempt/snapshot과 대조한다. 실행 보고서 artifact는 허용 report root 안에서 경로를 해석하고 traversal/외부 경로·누락을 거부한다. 원본 baseline 파일은 사용자가 선택한 reference root 내 hash 검증된 리소스만 읽는다. baseline이 report에 복사되는지 여부는 Engine 공개 경로 계약을 따른다. UI는 없는 artifact나 비교값을 합성하지 않는다.

비교 불가/미지원은 원인(reason)을 표시하고 Engine의 blocked/infra_error 등 실제 outcome과 함께 보여준다. expected와 actual이 비교 가능하면서 규칙을 어긴 failed와 구분한다. 검토 메모/확인 상태는 실행 outcome을 바꾸지 않는다.

### D5. 공유 작업의 단일 소유와 인수

| 작업 | 기존 소유 | 이 change의 추가 인수 |
| --- | --- | --- |
| Flutter shell/Provider | monorepo6.1, flow-editor2.1, handoff3.1 완료 증거 | 새 shell을 만들거나 기존 완료를 확대하지 않음 |
| Engine pin/schema | flow-editor2.2, handoff1.2 | 신규 디자인/UX 공개 계약의 별도 version/hash·capability 검증. alpha.2 XML 인수 대체 불가 |
| XML validate/plan | handoff3.2 | 기준·팩 매핑이 포함된 XML의 비실행 검증 |
| CLI/capability/cancel | flow-editor2.4, handoff3.3 | 동일 bridge로 디자인/UX 실제 실행·취소 인수 |
| JSONL/Run evidence | flow-editor2.5, handoff3.3 | 동일 Run view에 검사별 참조/측정값/비교 불가 표시 |
| 실제 Windows 제품 | handoff3.4, flow-editor2.6 | 이 데모의 사용자 입력→실행→결과 증거 별도 |
| 공용 서버·보고 baseline | platform2.3/2.6/3.1/3.2 | 이번 로컬 데모에서 구현·완료 주장하지 않음 |

코드는 기존 bridge/Run 경계를 확장하고 동일 테스트 증거를 task별 인수 문장과 매핑한다. 기존 change의 전체 조건을 충족하지 않은 task를 일괄 체크하지 않는다. XML만 완성해도 full block builder는 미완료다.

## Risks / Trade-offs

- [폰트·viewport·DPR·테마 차이] → profile과 기준 조건을 명시하고 맞지 않으면 비교 불가 사유 표시.
- [초안 CLI/schema 변경] → Engine 정본을 소비하고 release gate 전 제품 활성화 금지.
- [Windows 취소와 결과 누락] → 요청/종료 확인 분리, 실제 실행으로 인수.
- [데모를 전체 플랫폼 인수로 오해] → 로컬/웹 대상·합성 가림 한계와 미완료 Appium/서버 명시.

## Migration Plan

관리 명세 검토 후 Engine 계약/fixture·고정 release를 먼저 수신한다. 공유 bridge 기반을 구현하고 로컬 팩과 결과 표시를 붙인 뒤 실제 PASS/FAIL/미지원/취소를 검증한다. 독립 CLI 증거 이후 Flutter 사용자 경로와 Windows build를 검증한다. 기존 XML/JSON 파일 기능은 유지하고 새 계약 불일치 시 기능을 비활성화하며 기존 pin으로 자동 의미 변환하지 않는다.

## Open Questions

정본의 정확한 schema/runtime version/hash, preset ID와 CLI 옵션명, reference/report 경로 표기는 Engine 초안 검토 뒤 고정한다. 필드명은 변경 가능하지만 명시 입력·비실행 검증·결과 진실성·별도 Desktop 인수 원칙은 유지한다. 이 항목들은 구현 task1.1/1.2의 선행조건이다.
