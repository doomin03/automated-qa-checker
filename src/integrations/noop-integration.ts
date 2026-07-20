import type { RunResult, TargetResult } from "../core/results.js";

export interface RunContext {
  runId: string;
  startedAt: string;
  mode: "local";
}

export interface TestResultIntegration {
  publishRunStarted(context: RunContext): Promise<void>;
  publishRunCompleted(result: RunResult): Promise<void>;
  publishTargetCompleted(result: TargetResult): Promise<void>;
}

export class NoopIntegration implements TestResultIntegration {
  async publishRunStarted(_context: RunContext): Promise<void> {
    return Promise.resolve();
  }

  async publishRunCompleted(_result: RunResult): Promise<void> {
    return Promise.resolve();
  }

  async publishTargetCompleted(_result: TargetResult): Promise<void> {
    return Promise.resolve();
  }
}
