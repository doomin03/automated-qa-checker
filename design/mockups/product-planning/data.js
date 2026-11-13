window.WEB_SCREENS = [
  {
    "id": "W01",
    "title": "조직 연결·프로젝트",
    "actor": "viewer",
    "role": "viewer",
    "currentRoute": "/qa/shared",
    "currentComponent": "SharedScenarios",
    "proposedRoute": "/qa/projects",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "소속 프로젝트를 선택해 공용 QA 작업을 시작한다.",
    "inputs": [
      "서버 주소",
      "조직 로그인"
    ],
    "actions": [
      "조직 로그인",
      "프로젝트 선택",
      "로그아웃"
    ],
    "states": [
      "연결 전",
      "로그인 중",
      "목록 로딩",
      "프로젝트 없음",
      "연결됨"
    ],
    "exceptions": [
      "세션 만료",
      "403 권한 없음",
      "서버 오프라인"
    ],
    "api": [
      "GET auth/start",
      "GET auth/session",
      "POST auth/logout",
      "GET me",
      "GET projects"
    ],
    "links": [
      "W02",
      "W05",
      "D01"
    ],
    "acceptance": [
      "프로젝트 변경 시 이전 응답/선택 무효화",
      "소속 없음과 로딩 분리",
      "로그인이 실행을 유발하지 않음"
    ],
    "evidence": "artifacts/organization-web-verification.json: localProvider=true, realSlack=false; PlatformController.projects",
    "evidenceLevel": "코드 및 fixture/요청 UI 검증",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "W02",
    "title": "공용 QA 목록",
    "actor": "viewer",
    "role": "viewer",
    "currentRoute": "/qa/shared",
    "currentComponent": "SharedScenarios / SuiteExecutions",
    "proposedRoute": "/qa/projects/:projectId/library",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "프로젝트에 게시된 QA와 Suite를 찾아 상세로 이동한다.",
    "inputs": [
      "QA/Suite 탭",
      "불러온 목록 검색",
      "packageId 필터"
    ],
    "actions": [
      "상세 열기",
      "다음 페이지",
      "새로고침"
    ],
    "states": [
      "불러오는 중",
      "게시 항목 없음",
      "검색 결과 없음",
      "목록"
    ],
    "exceptions": [
      "401/403",
      "조회 실패"
    ],
    "api": [
      "GET projects/P/registry/versions",
      "GET projects/P/suites/versions"
    ],
    "links": [
      "W03",
      "W04",
      "D03",
      "A01"
    ],
    "acceptance": [
      "게시 QA를 개인 할당 inbox로 표시하지 않음",
      "전역 검색 API가 없는 범위를 명시"
    ],
    "evidence": "PlatformController.versions, SuiteController.versions; artifacts/shared-web-verification.json",
    "evidenceLevel": "코드 및 기존 인수 기록",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "W03",
    "title": "QA 버전 상세·전달",
    "actor": "viewer / pin: qa_tester",
    "role": "viewer / pin: qa_tester",
    "currentRoute": "/qa/shared",
    "currentComponent": "SharedScenarios",
    "proposedRoute": "/qa/projects/:projectId/library/:versionId",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "고정 원문과 이전 pin 차이를 확인하고 명시 전달한다.",
    "inputs": [
      "선택 버전",
      "이전 pin"
    ],
    "actions": [
      "고정 XML 다운로드",
      "변경 확인 후 버전 고정",
      "Desktop 수신 안내"
    ],
    "states": [
      "상세 로딩",
      "선택됨",
      "고정됨"
    ],
    "exceptions": [
      "hash 불일치",
      "409 버전 충돌",
      "pin 권한 없음"
    ],
    "api": [
      "GET projects/P/registry/versions/V",
      "GET projects/P/registry/pins",
      "GET projects/P/registry/upgrade-diff",
      "PUT projects/P/registry/pins"
    ],
    "links": [
      "W02",
      "D03",
      "D06"
    ],
    "acceptance": [
      "다운로드/pin은 실행 횟수0",
      "딥링크 자동열기 표시 금지",
      "기존 원문 유지"
    ],
    "evidence": "SharedScenarios.chooseVersion/download; artifacts/shared-web-verification.json",
    "evidenceLevel": "코드 및 기존 인수 기록",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "W04",
    "title": "Suite 상세",
    "actor": "viewer / pin: qa_tester",
    "role": "viewer / pin: qa_tester",
    "currentRoute": "/qa/shared",
    "currentComponent": "SuiteExecutions",
    "proposedRoute": "/qa/projects/:projectId/suites/:versionId",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "고정 case 순서와 실행 정책을 확인한다.",
    "inputs": [
      "Suite 버전",
      "case 선택"
    ],
    "actions": [
      "Suite 버전 고정",
      "case 상세",
      "Agent 실행 요청"
    ],
    "states": [
      "case 목록",
      "고정됨"
    ],
    "exceptions": [
      "case hash 불일치",
      "Engine pin 불일치"
    ],
    "api": [
      "GET projects/P/suites/versions/V",
      "PUT projects/P/suites/pins"
    ],
    "links": [
      "W03",
      "W08",
      "A04",
      "D03"
    ],
    "acceptance": [
      "Desktop은 case 하나 신규 수신",
      "전체 Suite Desktop 실행 표시 금지",
      "RegistrySuite와 rawSuiteXML 구분"
    ],
    "evidence": "SuiteService.inputs/pin; artifacts/suite-web-verification.json: pinDidNotExecute=true",
    "evidenceLevel": "코드 및 fixture/요청 UI 검증",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "W05",
    "title": "실행 목록·진행",
    "actor": "viewer",
    "role": "viewer",
    "currentRoute": "/qa/shared",
    "currentComponent": "SharedScenarios",
    "proposedRoute": "/qa/projects/:projectId/runs",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "서버가 수신한 실행과 각 상태를 확인한다.",
    "inputs": [
      "프로젝트",
      "실행 선택"
    ],
    "actions": [
      "새로고침",
      "실행 상세",
      "다음 페이지"
    ],
    "states": [
      "로딩",
      "실행 없음",
      "진행 중",
      "terminal"
    ],
    "exceptions": [
      "접속 끊김",
      "403"
    ],
    "api": [
      "GET projects/P/runs"
    ],
    "links": [
      "W06",
      "A03",
      "A05"
    ],
    "acceptance": [
      "판정/증거/업무 별도 열",
      "로컬 alpha8결과가 자동 공유된 듯 표시 금지"
    ],
    "evidence": "PlatformController.runs; artifacts/shared-web-verification.json",
    "evidenceLevel": "코드 및 기존 인수 기록",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "W06",
    "title": "실행 상세·증거",
    "actor": "viewer",
    "role": "viewer",
    "currentRoute": "/qa/shared",
    "currentComponent": "SharedScenarios / Blueprint",
    "proposedRoute": "/qa/projects/:projectId/runs/:runId",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "실행 snapshot의 단계·판정·검증된 증거를 관찰한다.",
    "inputs": [
      "서버 Run ID",
      "진행 cursor"
    ],
    "actions": [
      "수신 중지/재연결",
      "검증된 PNG 보기",
      "업무·비교 열기"
    ],
    "states": [
      "진행 중",
      "passed",
      "failed",
      "infra_error",
      "cancelled",
      "증거 pending/verified"
    ],
    "exceptions": [
      "sequence/identity 불일치",
      "증거 미수집",
      "이미지 hash 불일치"
    ],
    "api": [
      "GET projects/P/runs/R",
      "GET projects/P/runs/R/events",
      "GET projects/P/runs/R/artifacts/id"
    ],
    "links": [
      "W05",
      "A03",
      "D07"
    ],
    "acceptance": [
      "실행 당시 snapshot만 표시",
      "증거 verified를 성공으로 해석하지 않음",
      "없는 PNG는 미수집 이유"
    ],
    "evidence": "artifacts/shared-web-verification.json: alpha5 실제 기록/PNG; alpha8 공유 인수 아님",
    "evidenceLevel": "코드 및 기존 인수 기록",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "W07",
    "title": "XML 전달 도구",
    "actor": "로컬 사용자",
    "role": "로컬 사용자",
    "currentRoute": "/qa/blueprints",
    "currentComponent": "BlueprintPage",
    "proposedRoute": "/qa/blueprints",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "사용자 XML 전달과 파일 기반 실행 관찰을 제공한다.",
    "inputs": [
      "Blueprint JSON/XML",
      "events JSONL"
    ],
    "actions": [
      "가져오기",
      "검사",
      "XML 내보내기",
      "이벤트 파일 관찰"
    ],
    "states": [
      "문서 없음",
      "문서 검사됨",
      "오류",
      "snapshot 관찰"
    ],
    "exceptions": [
      "잘못된 XML/JSON",
      "다른 snapshot 이벤트"
    ],
    "api": [
      "파일 기반; 직접 실행 API 없음"
    ],
    "links": [
      "W03",
      "D06",
      "W06"
    ],
    "acceptance": [
      "내보내기 자동 실행 없음",
      "초안과 관찰snapshot 구분"
    ],
    "evidence": "tests/xml.test.mjs; tests/ui.test.mjs; BlueprintPage",
    "evidenceLevel": "코드 및 기존 인수 기록",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "W08",
    "title": "Agent 실행 요청",
    "actor": "qa_tester",
    "role": "qa_tester",
    "currentRoute": "/qa/shared",
    "currentComponent": "SuiteExecutions",
    "proposedRoute": "/qa/projects/:projectId/executions/new",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "고정 QA/Suite와 실행 범위를 명시해 요청한다.",
    "inputs": [
      "고정 QA 또는 Suite",
      "SHA",
      "resource key",
      "platform/origin/native app",
      "secretRef",
      "production opt-in"
    ],
    "actions": [
      "Agent 실행 요청"
    ],
    "states": [
      "입력",
      "검증 오류",
      "요청 중",
      "queued"
    ],
    "exceptions": [
      "resource 미등록",
      "범위 초과",
      "pin 불일치",
      "적격 Agent 없음"
    ],
    "api": [
      "POST projects/P/executions"
    ],
    "links": [
      "W04",
      "A05",
      "A04"
    ],
    "acceptance": [
      "queued는 실행 성공 아님",
      "secret 값 입력 금지",
      "사용자/운영자 scope 교집합"
    ],
    "evidence": "SchedulerService.createExecution; suite-web-verification agentActuallyExecuted=false",
    "evidenceLevel": "코드 및 fixture/요청 UI 검증",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "A01",
    "title": "초안·검수 목록",
    "actor": "viewer 조회 / qa_editor 작성 / qa_manager 검수",
    "role": "viewer 조회 / qa_editor 작성 / qa_manager 검수",
    "currentRoute": "/qa/shared",
    "currentComponent": "SharedScenarios / SuiteExecutions",
    "proposedRoute": "/qa/projects/:projectId/manage/reviews",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "QA/Suite의 검수 대상을 찾는다.",
    "inputs": [
      "QA/Suite 탭",
      "초안 선택"
    ],
    "actions": [
      "초안 작성",
      "상세 열기"
    ],
    "states": [
      "draft",
      "reviewed",
      "published",
      "목록 없음"
    ],
    "exceptions": [
      "권한 없음",
      "조회 실패"
    ],
    "api": [
      "GET projects/P/registry/drafts",
      "GET projects/P/suites/drafts"
    ],
    "links": [
      "A02",
      "W02"
    ],
    "acceptance": [
      "서버 state 사용",
      "작성자와 검수자 표시"
    ],
    "evidence": "PlatformService.listDrafts; SuiteService.drafts",
    "evidenceLevel": "코드 및 기존 인수 기록",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "A02",
    "title": "QA·Suite 작성·게시",
    "actor": "qa_editor 작성 / qa_manager 독립 검수·게시",
    "role": "qa_editor 작성 / qa_manager 독립 검수·게시",
    "currentRoute": "/qa/shared",
    "currentComponent": "SharedScenarios / SuiteExecutions",
    "proposedRoute": "/qa/projects/:projectId/manage/reviews/:id",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "검사된 초안을 다른 검수자 승인 후 불변 버전으로 게시한다.",
    "inputs": [
      "packageId/title",
      "XML/dependencies 또는 cases",
      "게시 version"
    ],
    "actions": [
      "초안 저장",
      "독립 검수 승인",
      "버전 게시"
    ],
    "states": [
      "draft",
      "reviewed",
      "published",
      "저장 중"
    ],
    "exceptions": [
      "본인 검수 금지",
      "검수 권한 상실",
      "중복 version",
      "case/hash 오류"
    ],
    "api": [
      "POST projects/P/registry/drafts",
      "POST projects/P/registry/drafts/id/review",
      "POST projects/P/registry/drafts/id/publish",
      "POST projects/P/suites/drafts",
      "POST projects/P/suites/drafts/id/review",
      "POST projects/P/suites/drafts/id/publish"
    ],
    "links": [
      "A01",
      "W02",
      "W04"
    ],
    "acceptance": [
      "수신·게시 자체 실행0",
      "멱등 게시 재전송",
      "수정/반려/폐기 미구현 표시"
    ],
    "evidence": "PlatformService.review/publish; SuiteService.review/publish; shared/suite web artifacts",
    "evidenceLevel": "코드 및 기존 인수 기록",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "A03",
    "title": "업무·비교",
    "actor": "viewer 조회 / qa_tester 변경",
    "role": "viewer 조회 / qa_tester 변경",
    "currentRoute": "/qa/shared",
    "currentComponent": "RunWork",
    "proposedRoute": "/qa/projects/:projectId/manage/work",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "Run의 담당 업무와 비교 가능한 이전 결과를 관리한다.",
    "inputs": [
      "status",
      "활성 프로젝트 담당 ID",
      "revision",
      "baseline Run"
    ],
    "actions": [
      "업무 저장",
      "새로고침",
      "결과 비교",
      "기준 실행 선택"
    ],
    "states": [
      "todo",
      "in_progress",
      "done",
      "비교 가능/불가"
    ],
    "exceptions": [
      "409 revision 충돌",
      "비활성 담당자",
      "환경 증거 없음"
    ],
    "api": [
      "GET/PUT projects/P/runs/R/work",
      "GET projects/P/runs/R/comparison",
      "PUT projects/P/runs/R/baseline"
    ],
    "links": [
      "W06",
      "A06"
    ],
    "acceptance": [
      "done과failed 동시 표시",
      "Run담당과 QA배포assignment 구분",
      "비교불가 사유 보존"
    ],
    "evidence": "artifacts/workflow-web-verification.json: workStatus done/outcome failed",
    "evidenceLevel": "코드 및 기존 인수 기록",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "A04",
    "title": "예약·발생 이력",
    "actor": "viewer 조회 / qa_tester 생성·활성 변경",
    "role": "viewer 조회 / qa_tester 생성·활성 변경",
    "currentRoute": "/qa/shared",
    "currentComponent": "SuiteExecutions",
    "proposedRoute": "/qa/projects/:projectId/schedules",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "Desktop 종료와 무관한 서버 주간 QA를 관리한다.",
    "inputs": [
      "고정 QA/Suite",
      "대상 scope",
      "요일",
      "현지시간",
      "IANA TZ",
      "허용지연",
      "활성"
    ],
    "actions": [
      "예약 저장",
      "활성/중지",
      "occurrence 보기"
    ],
    "states": [
      "활성",
      "중지",
      "queued",
      "missed"
    ],
    "exceptions": [
      "DST없는시각",
      "scheduler지연",
      "권한철회",
      "pin불일치"
    ],
    "api": [
      "GET/POST projects/P/schedules",
      "PUT projects/P/schedules/id/enabled",
      "GET projects/P/schedules/id/occurrences"
    ],
    "links": [
      "W04",
      "W08",
      "A05",
      "W06"
    ],
    "acceptance": [
      "tester도 작성 가능",
      "occurrence와 Run판정 분리",
      "삭제/전체수정API 없음 명시"
    ],
    "evidence": "SchedulerService.create/row/tick; suite-web-verification scheduleCreatedEnabledDisabled=true",
    "evidenceLevel": "코드 및 기존 인수 기록",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "A05",
    "title": "Agent 실행·운영 복구",
    "actor": "viewer 조회 / qa_tester 취소 / qa_manager 복구",
    "role": "viewer 조회 / qa_tester 취소 / qa_manager 복구",
    "currentRoute": "/qa/shared",
    "currentComponent": "SuiteExecutions",
    "proposedRoute": "/qa/projects/:projectId/executions/:id",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "실행 요청·case Run·불확실 종료를 확인한다.",
    "inputs": [
      "execution ID",
      "복구 사유",
      "프로세스·외부 세션 종료 확인"
    ],
    "actions": [
      "상태 수신",
      "취소 요청",
      "case 결과",
      "격리 해제 요청"
    ],
    "states": [
      "queued",
      "claimed",
      "reporting",
      "completed",
      "cancelled",
      "missed",
      "expired",
      "quarantined",
      "recovered"
    ],
    "exceptions": [
      "cleanup 미확인",
      "stale fence",
      "권한 없음"
    ],
    "api": [
      "GET projects/P/executions",
      "GET projects/P/executions/id",
      "POST projects/P/executions/id/cancel",
      "POST projects/P/executions/id/recovery"
    ],
    "links": [
      "W08",
      "A04",
      "W06",
      "A08"
    ],
    "acceptance": [
      "취소 요청과종료 분리",
      "TTL만으로 종료확인 금지",
      "복구는기존outcome불변"
    ],
    "evidence": "SchedulerService.execution; suite-web-verification operatorRecovery fixtureOnly=true",
    "evidenceLevel": "코드 및 fixture/요청 UI 검증",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "A06",
    "title": "감사·알림",
    "actor": "qa_manager 감사·요청 / viewer 알림 조회",
    "role": "qa_manager 감사·요청 / viewer 알림 조회",
    "currentRoute": "/qa/shared",
    "currentComponent": "SharedScenarios / RunWork",
    "proposedRoute": "/qa/projects/:projectId/manage/audit",
    "status": "현재 기능 존재 / 화면 분리는 설계 제안",
    "purpose": "변경 이력과 결과 알림 전달 상태를 확인한다.",
    "inputs": [
      "프로젝트",
      "Run"
    ],
    "actions": [
      "감사 새로고침",
      "다음 페이지",
      "알림 요청",
      "알림 조회"
    ],
    "states": [
      "감사 목록",
      "전송 대기",
      "delivered",
      "delivery_failed"
    ],
    "exceptions": [
      "권한 없음",
      "전송 실패"
    ],
    "api": [
      "GET projects/P/audit",
      "POST/GET projects/P/runs/R/notifications"
    ],
    "links": [
      "A03",
      "A05",
      "W06"
    ],
    "acceptance": [
      "전송 실패가 Run을 바꾸지 않음",
      "실제 Slack 발송 완료 표시 금지"
    ],
    "evidence": "WorkflowService; workflow-web-verification localNotification=true/externalNotification=false",
    "evidenceLevel": "코드 및 기존 인수 기록",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "A07",
    "title": "사용자·팀·권한",
    "actor": "계획: 관리자",
    "role": "계획: 관리자",
    "currentRoute": "없음",
    "currentComponent": "없음",
    "proposedRoute": "/qa/projects/:projectId/manage/members",
    "status": "계획 기능 / API·제품 UI 미구현",
    "purpose": "원본 요구의 사용자·팀·프로젝트 권한 관리 후속 범위를 정의한다.",
    "inputs": [
      "계획: 사용자/팀/역할/초대/활성"
    ],
    "actions": [
      "계획 보기"
    ],
    "states": [
      "미구현"
    ],
    "exceptions": [
      "API 없음"
    ],
    "api": [
      "미구현; 현재 환경 provisioning"
    ],
    "links": [
      "W01",
      "A03"
    ],
    "acceptance": [
      "가짜CRUD 성공 금지",
      "계약→OpenSpec→구현→인수 순서"
    ],
    "evidence": "platform.config.ts/Auth config 사전 identities; 공개 CRUD controller 없음",
    "evidenceLevel": "계획",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  },
  {
    "id": "A08",
    "title": "Agent·리소스 관리",
    "actor": "계획: 운영 관리자",
    "role": "계획: 운영 관리자",
    "currentRoute": "없음",
    "currentComponent": "없음",
    "proposedRoute": "/qa/projects/:projectId/manage/resources",
    "status": "계획 기능 / API·제품 UI 미구현",
    "purpose": "Agent/기기 재고와 등록 UI의 후속 계약 범위를 정의한다.",
    "inputs": [
      "계획: agent/resource/capability/lease"
    ],
    "actions": [
      "계획 보기",
      "실행 운영 열기"
    ],
    "states": [
      "미구현"
    ],
    "exceptions": [
      "공개 목록/등록 HTTP 없음"
    ],
    "api": [
      "미구현; AgentService.provision은 trusted local management"
    ],
    "links": [
      "A05",
      "W08",
      "A04"
    ],
    "acceptance": [
      "Agent프로토콜을 사용자 fleet API로 오인 금지",
      "live device 연결 상태 발명 금지"
    ],
    "evidence": "AgentController claims/leases protocol; AgentService.provision local boundary",
    "evidenceLevel": "계획",
    "reviewNote": "목업은 예시 데이터. 제안 경로는 실제 새 웹 라우트 구현 완료를 뜻하지 않음."
  }
];
window.ENGINE_MAP = {
  "schema": "planning-relationship-map/v1",
  "date": "2026-11-11",
  "purpose": "목업·화면설계서 관계도용 기획 metadata. Engine 실행 schema가 아님",
  "nodes": [
    {
      "id": "user_web",
      "label": "사용자 웹",
      "owner": "Checker",
      "kind": "user-surface",
      "support": "현재 웹 기반 + 역할별 정보구조는 기획",
      "role": "공용 QA 탐색·전달·진행 확인"
    },
    {
      "id": "management_web",
      "label": "관리 역할 웹",
      "owner": "Checker",
      "kind": "user-surface",
      "support": "현재 권한 기능 + 별도 workspace 정보구조는 기획",
      "role": "검토·게시·일정·운영·업무 관리; 사용자 웹과 동일 서버/RBAC"
    },
    {
      "id": "registry",
      "label": "게시 QA·Suite registry",
      "owner": "Checker server",
      "kind": "service",
      "support": "구현",
      "role": "고정 버전/XML/hash 및 Suite case 버전 목록"
    },
    {
      "id": "desktop_home",
      "label": "Desktop 프로젝트 홈",
      "owner": "Checker",
      "kind": "user-surface",
      "support": "현재 구현/별도 native 인수 근거 확인",
      "role": "내 프로젝트·서버에서 받기·가져온 QA"
    },
    {
      "id": "local_qa",
      "label": "로컬 QA 문서",
      "owner": "Checker",
      "kind": "document",
      "support": "구현",
      "role": "project+qa identity, 원문 출처 receipt, 직접 모드"
    },
    {
      "id": "composer",
      "label": "XML 파일 블록 작업실",
      "owner": "Checker",
      "kind": "user-surface",
      "support": "제한 조합 구현·공개 CLI 교차검증",
      "role": "파일 instance 편집·순차 조합; sourceMap/layout는 Checker metadata"
    },
    {
      "id": "external_consumer",
      "label": "다른 Node 프로젝트·CLI 사용자",
      "owner": "consumer",
      "kind": "external",
      "support": "독립 설치 인수",
      "role": "Checker 없이 package API/aqa 소비"
    },
    {
      "id": "engine_prepare",
      "label": "Engine import·validate·plan",
      "owner": "Engine",
      "kind": "package-cli",
      "support": "alpha.8 / contract 0.3.0-draft.2",
      "role": "정본 파싱·검증·immutable plan; 브라우저 시작 없음"
    },
    {
      "id": "local_engine_run",
      "label": "명시 Engine 실행",
      "owner": "Engine",
      "kind": "package-cli",
      "support": "Desktop alpha.8 / contract 0.3.0-draft.2",
      "role": "단일 Blueprint·단일 target/session"
    },
    {
      "id": "adapter",
      "label": "Playwright·Appium adapter",
      "owner": "Engine",
      "kind": "runtime",
      "support": "Chromium 실제 인수; Appium protocol fixture; native 실기기 미검증",
      "role": "대상 조작·단언·증거·정리"
    },
    {
      "id": "local_artifacts",
      "label": "로컬 실행 결과·증거",
      "owner": "Engine produces; Checker presents",
      "kind": "artifact",
      "support": "구현",
      "role": "blueprint.json/events.jsonl/result.json/evidence.json 및 실제 PNG"
    },
    {
      "id": "scheduler",
      "label": "서버 요청·일정·lease",
      "owner": "Checker server",
      "kind": "service",
      "support": "기본 alpha.6 호환",
      "role": "권한·occurrence·queue·lease/fence"
    },
    {
      "id": "agent",
      "label": "선택 독립 Agent",
      "owner": "Engine transport + Checker protocol",
      "kind": "background-process",
      "support": "실제 서버 교차 인수 alpha.6; alpha.8은 별도 HTTP fixture",
      "role": "승인 정책 교집합·ordered cases·child 실행·outbox/reconcile"
    },
    {
      "id": "server_runs",
      "label": "서버 실행·증거 보관",
      "owner": "Checker server",
      "kind": "service",
      "support": "기본 alpha.6; alpha.8 명시 격리 서버 인수 별도",
      "role": "원본 event/result identity·증거 정합/전송 상태"
    },
    {
      "id": "work_state",
      "label": "업무 처리 상태",
      "owner": "Checker",
      "kind": "business-state",
      "support": "실제 세부 기능은 웹 담당 근거",
      "role": "Engine 판정과 별도 triage/work 상태; 개인 배정 구현으로 추정 금지"
    }
  ],
  "edges": [
    {
      "id": "e01",
      "from": "management_web",
      "to": "registry",
      "payload": "검토·게시 요청 → 고정 version/XML/SHA",
      "contract": "Checker API/RBAC",
      "support": "웹 담당 확인",
      "boundary": "UI 검증과 실제 Engine 실행 인수는 구분"
    },
    {
      "id": "e02",
      "from": "registry",
      "to": "user_web",
      "payload": "권한 있는 게시 QA/Suite 목록·상세",
      "contract": "Checker registry API",
      "support": "구현",
      "boundary": "개인배정 inbox 의미 아님"
    },
    {
      "id": "e03",
      "from": "registry",
      "to": "desktop_home",
      "payload": "고정 version/hash/XML; Suite는 고정 case 목록",
      "contract": "기본 서버 alpha.6 registry",
      "support": "수신 구현",
      "boundary": "Suite 전체 Desktop 실행 아님"
    },
    {
      "id": "e04",
      "from": "desktop_home",
      "to": "local_qa",
      "payload": "case 하나의 원문 + local project/qa + immutable receipt + direct sidecar",
      "contract": "Checker workspace v1/sidecars",
      "support": "구현·저장/경합 독립검토",
      "boundary": "receipt 선저장→workspace commit; orphan 미노출; 자동 run 없음"
    },
    {
      "id": "e05",
      "from": "local_qa",
      "to": "composer",
      "payload": "직접 XML 또는 공개prepare한 파일 asset/instance",
      "contract": "Checker 편집 metadata",
      "support": "제한 조합 구현",
      "boundary": "직접 XML 보존; 미지원 조합 명시"
    },
    {
      "id": "e06",
      "from": "composer",
      "to": "engine_prepare",
      "payload": "단일 합성 Blueprint XML",
      "contract": "qa.blueprint/v1; alpha.8 draft.2",
      "support": "공개 CLI validation/plan 교차검증",
      "boundary": "동일 target·single start/end·순차 outer; namespacing; secret.ref 보존"
    },
    {
      "id": "e07",
      "from": "local_qa",
      "to": "engine_prepare",
      "payload": "직접 XML/JSON 문서",
      "contract": "공개 import/validate/plan",
      "support": "구현",
      "boundary": "검증 실패=미실행; 임의 XML runnable 주장 금지"
    },
    {
      "id": "e08",
      "from": "external_consumer",
      "to": "engine_prepare",
      "payload": "공개 입력+compileBlueprint/loadBlueprint 또는 aqa 명령",
      "contract": "automated-qa-engine public API/bin",
      "support": "sibling 없는 설치 인수",
      "boundary": "Flutter/서버/Slack 필수 아님"
    },
    {
      "id": "e09",
      "from": "engine_prepare",
      "to": "local_engine_run",
      "payload": "검증된 immutable plan/snapshot + 사용자의 명시 실행 + 실행설정",
      "contract": "executeBlueprint 또는 aqa run",
      "support": "alpha.8 실제 Chromium 인수",
      "boundary": "검증/AI생성 완료가 실행승인 또는 PASS 아님"
    },
    {
      "id": "e10",
      "from": "local_engine_run",
      "to": "adapter",
      "payload": "허용 action/selector/target; signal/deadline; 외부 secret resolution",
      "contract": "Runner public port",
      "support": "플랫폼별 capability",
      "boundary": "TV/일반 whitebox 미지원; 임의 shell 없음"
    },
    {
      "id": "e11",
      "from": "adapter",
      "to": "local_artifacts",
      "payload": "step 관측→Engine events/result/evidence",
      "contract": "runId/attempt/sequence; 실행 snapshot; 실제 artifact SHA",
      "support": "구현",
      "boundary": "infra_error/cancelled도 실제 수집분만; missing 이유 표시"
    },
    {
      "id": "e12",
      "from": "local_artifacts",
      "to": "composer",
      "payload": "실행 진행·terminal·증거; snapshot-bound sourceMap",
      "contract": "Checker presentation",
      "support": "구현",
      "boundary": "과거 실행 map을 새 문서 instance에 귀속 금지"
    },
    {
      "id": "e13",
      "from": "management_web",
      "to": "scheduler",
      "payload": "권한 있는 고정 QA/Suite 실행 요청·예약",
      "contract": "Checker scheduling API",
      "support": "구현; 웹 요청 UI 인수와 실제 Agent 인수 별도",
      "boundary": "실제 사용자 역할별 허용은 RBAC 확인"
    },
    {
      "id": "e14",
      "from": "scheduler",
      "to": "agent",
      "payload": "execution/jobAttempt/lease/fence + ordered cases + server policy",
      "contract": "Agent HTTP pin 8c25e3c853f3b8d24003464d2ddc55a20675b7ac3f741a46c238a50ce4149490",
      "support": "기본 alpha.6 실제 서버 인수",
      "boundary": "로컬 allowlist와 교집합; Desktop 종료와 Agent 종료 분리"
    },
    {
      "id": "e15",
      "from": "agent",
      "to": "adapter",
      "payload": "설치된 Engine child run으로 case별 단일 Blueprint 실행",
      "contract": "고정 runtime CLI; 기본 alpha.6",
      "support": "ordered Suite 실제 서버/Chromium 인수",
      "boundary": "불명확한 이전 실행 자동 재실행 금지; quarantine/reconcile"
    },
    {
      "id": "e16",
      "from": "agent",
      "to": "server_runs",
      "payload": "durable deliverySequence + 원본 Engine events/result/artifact + ACK",
      "contract": "Agent reporting; Engine identity 보존",
      "support": "alpha.6 실제 인수; alpha.8 HTTP fixture",
      "boundary": "Engine 판정과 전송/증거정합 구분"
    },
    {
      "id": "e17",
      "from": "local_artifacts",
      "to": "server_runs",
      "payload": "공유 요청: runtime/version/snapshot/events/result",
      "contract": "server engineVersion equality",
      "support": "조건부; 기본 alpha.6 서버는 alpha.8 결과 거부",
      "boundary": "공유 호환성 불일치; local outcome 불변; alpha.8 격리 서버 근거 별도"
    },
    {
      "id": "e18",
      "from": "server_runs",
      "to": "user_web",
      "payload": "진행·원본 판정·증거정합·전송 상태",
      "contract": "Checker result API/RBAC",
      "support": "구현",
      "boundary": "run 판정/업무/lease/occurrence/전송 상태 6축 구분"
    },
    {
      "id": "e19",
      "from": "server_runs",
      "to": "work_state",
      "payload": "실행 결과를 근거로 별도 업무 처리",
      "contract": "Checker business API",
      "support": "웹 담당 세부 인수 확인",
      "boundary": "Engine passed가 업무 done 의미 아님"
    },
    {
      "id": "e20",
      "from": "user_web",
      "to": "scheduler",
      "payload": "고정 QA/Suite 즉시 Agent 실행 요청·예약·취소",
      "contract": "Checker API/RBAC qa_tester 이상",
      "support": "웹 담당 SchedulerService createExecution/create/setEnabled 및 AgentService preparePublished/cancel 직접 확인",
      "boundary": "사용자·관리 workspace 동일API; 관리자전용으로 축소하지 않음; 실행은 별도 Agent 준비 필요"
    }
  ],
  "mockupRecommendation": "Engine 그래픽 관리 앱을 새 제품처럼 만들지 않는다. 기획 검토 화면에서 설치 package/CLI 명령, 입력 XML, validation diagnostics, plan snapshot, event timeline, result/evidence artifacts를 탐색한다. 사용자 웹/관리 역할/Desktop과 Engine package-runtime의 형태를 시각적으로 구분한다.",
  "references": [
    "engine-planning-evidence.md",
    "../checker-xml-composition-review-20261111/review.json",
    "../checker-received-home-review-20261111/final-closure-review.json"
  ],
  "notNewAcceptance": "이번 문서는 읽기 조사와 담당 간 합의. 새로운 native/서버/Engine 전체 실행 인수 아님"
};
