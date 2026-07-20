export const TEST_STATUSES = [
  "PASSED",
  "FAILED",
  "BROKEN",
  "SKIPPED",
  "NOT_IMPLEMENTED",
] as const;

export type TestStatus = (typeof TEST_STATUSES)[number];

export type FailureKind = "PRODUCT" | "AUTOMATION" | "CONFIG" | "DEVICE" | "BINARY" | "UNSUPPORTED";

export interface EvidenceRef {
  type: "screenshot" | "trace" | "video" | "log" | "network" | "console" | "report";
  path: string;
  label?: string;
}

export interface QaError {
  code: string;
  message: string;
  kind: FailureKind;
  cause?: unknown;
}

export interface StepResult {
  id: string;
  type: string;
  status: TestStatus;
  startedAt: string;
  endedAt: string;
  durationMs: number;
  error?: QaError;
  evidence?: EvidenceRef[];
}

export interface ScenarioResult {
  id: string;
  name: string;
  status: TestStatus;
  riskLevel: "READ_ONLY" | "SAFE_WRITE" | "DESTRUCTIVE";
  startedAt: string;
  endedAt: string;
  durationMs: number;
  steps: StepResult[];
  error?: QaError;
  evidence?: EvidenceRef[];
}

export interface TargetResult {
  id: string;
  name: string;
  platform: "web" | "android" | "ios" | "webos";
  status: TestStatus;
  startedAt: string;
  endedAt: string;
  durationMs: number;
  scenarios: ScenarioResult[];
  error?: QaError;
  evidence?: EvidenceRef[];
}

export interface RunResult {
  runId: string;
  status: TestStatus;
  startedAt: string;
  endedAt: string;
  durationMs: number;
  targets: TargetResult[];
  error?: QaError;
}

export function isInfrastructureStatus(status: TestStatus): boolean {
  return status === "BROKEN" || status === "NOT_IMPLEMENTED";
}

export function statusFromError(error: QaError): TestStatus {
  if (error.kind === "PRODUCT") {
    return "FAILED";
  }

  if (error.kind === "UNSUPPORTED") {
    return "NOT_IMPLEMENTED";
  }

  return "BROKEN";
}
