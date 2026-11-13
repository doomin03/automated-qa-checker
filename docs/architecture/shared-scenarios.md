# 공용 XML과 실행 공유

2026-11-11 현재 진입은 [프로젝트·받은 QA 홈](../project-home.md)이다. 조직 로그인과 기본 cache를 사용하고, 게시 QA/Suite case를 새 로컬 QA로 수신한다. 원본 귀속은 local project+QA owner/origin/project/snapshot을 함께 검사한다. 아래 공용 패널·alpha5 공유 인수 설명은 과거 기능 이력이며 현재 제품의 기본 진입이나 alpha8→기본alpha6 게시 호환을 뜻하지 않는다. Suite/예약/업무는 이후 구현되어 [시스템 설계](system-design.md)와 [조직 업무](organization-auth-workflow.md)에 기록했다. Engine 판정과 별도인 업무는 현재 todo/in_progress/done이다. 외부 Slack 발송과 개인 QA 배정 inbox는 여전히 미완료다.

초기 공용 XML 변경은 공개 Engine로 검증한 self-contained Blueprint XML의 초안·독립 검수·불변 버전·dependency manifest·개인 pin·upgrade diff·감사를 구현했다. 당시 인수는 단일 XML Registry였으며 후속 Suite 게시/예약 전체 인수와 구분한다. 웹은 권한별 작성·검수·발행·조회 사용자 앱이고 Desktop은 수신한 로컬 사본의 개별 편집·명시 실행 앱이다.

Flutter 공용 XML 패널에서 주소, 메모리에만 유지할 token, 프로젝트, 절대 캐시 폴더를 입력한다. 버전을 선택해 hash와 변경 내용을 확인한 뒤 명시적으로 고정·수신한다. 수신 자체는 실행하지 않는다. 캐시의 고정 XML은 서버 없이도 열 수 있다. 이전 버전 bytes를 보존하고 새 pin은 임시 파일 flush/rename으로 교체한다. 다른 서버/프로젝트의 캐시를 현재 연결로 고정할 수 없다.

수신 버전의 snapshot hash가 실제 검증 plan과 같을 때만 실행에 versionId를 연결한다. 편집 후 달라진 snapshot은 별도 사용자 실행으로 게시하며 원본 출처 표시는 유지한다. 연결 변경은 자동 게시 동의를 해제한다. 현재 실행/게시 중 연결 교체는 금지한다.

진행 공유 checkbox는 현재·다음 실행의 게시를 명시 요청한다. CLI stdout은 서버 응답을 기다리지 않고 계속 읽는다. 서버 run ID와 Engine runId/attempt/snapshot은 별개로 고정하며 event sequence별 동일 내용 재전송은 멱등이다. 게시 실패는 로컬 QA outcome을 바꾸지 않는다. 미게시 실행은 최대 10개를 메모리에서 관리하고 로컬 report는 먼저 Engine가 보관한다. 앱 재시작 뒤 실제 run 폴더의 blueprint.json/events.jsonl/result.json을 선택해 재게시할 수 있다. 사용자 credentials는 outbox/report에 기록하지 않는다.

웹은 인증 cursor polling으로 진행을 자동 수신한다. 실행 당시 고정 snapshot을 공개 bundle로 검증하고 hash/identity/sequence를 대조한 뒤 기존 Blueprint 화면에 표시한다. 중지·재연결은 마지막 cursor를 유지한다. 원래 작성 중인 문서와 다른 실행 snapshot을 혼합하지 않는다. 서버의 reportedOutcome, evidenceStatus, workStatus를 구분하며 현재 workStatus는 todo 초기값뿐이다.

이미지는 서버가 발급한 opaque artifact ID로 받으며 반환 bytes/size/SHA-256을 다시 검사한 PNG만 표시한다. Desktop 업로드는 로컬 report의 realpath 하위 파일만 읽는다. 파일당10MiB, 실행당64MiB, 서버 JSON body16MiB다. evidenceStatus verified는 자료 정합성 확인이며 외부 실행 신뢰나 실제 모바일 기기 검증 보증이 아니다.

실행 방법은 [서버 안내](../../apps/server/PLATFORM.md), [로컬 Engine](local-engine.md), [검증 기록](../validation.md)을 따른다. 현재 local/test identity는 loopback 개발·테스트 모드에 한정되며 운영 OIDC·예약·Agent·업무 전이는 별도 단계다.
