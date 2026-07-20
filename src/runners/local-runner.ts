import { createRunId } from "../core/run-id.js";
import type { QaError, RunResult, ScenarioResult, TargetResult, TestStatus } from "../core/results.js";
import { durationMs, nowIso } from "../core/time.js";
import { loadTargets, type LoadedTarget } from "../config/target-registry.js";
import type { Platform } from "../config/schemas.js";
import type { ScenarioConfig } from "../config/scenario-schemas.js";
import { loadTargetScenarios } from "./scenario-loader.js";

export interface RunSelection {
  targetId?: string;
  group?: string;
  platform?: Platform;
  scenarioId?: string;
}

export async function runLocalChecks(rootDir: string, selection: RunSelection): Promise<RunResult> {
  const startedAt = nowIso();
  const targets = await selectTargets(rootDir, selection);
  const targetResults: TargetResult[] = [];

  for (const target of targets) {
    targetResults.push(await runTargetAsNotImplemented(rootDir, target, selection.scenarioId));
  }

  const endedAt = nowIso();
  return {
    runId: createRunId(),
    status: aggregateStatus(targetResults.map((target) => target.status)),
    startedAt,
    endedAt,
    durationMs: durationMs(startedAt, endedAt),
    targets: targetResults,
  };
}

async function selectTargets(rootDir: string, selection: RunSelection): Promise<LoadedTarget[]> {
  const options: {
    rootDir: string;
    group?: string;
    platform?: Platform;
  } = { rootDir };

  if (selection.group !== undefined) {
    options.group = selection.group;
  }

  if (selection.platform !== undefined) {
    options.platform = selection.platform;
  }

  const targets = await loadTargets(options);

  if (selection.targetId === undefined) {
    return targets;
  }

  return targets.filter((target) => target.config.id === selection.targetId);
}

async function runTargetAsNotImplemented(
  rootDir: string,
  target: LoadedTarget,
  scenarioId?: string,
): Promise<TargetResult> {
  const startedAt = nowIso();
  const scenarios = (await loadTargetScenarios(rootDir, target.config)).filter((scenario) =>
    scenarioId === undefined ? true : scenario.id === scenarioId,
  );

  const scenarioResults = scenarios.map((scenario) => createNotImplementedScenarioResult(scenario));
  const endedAt = nowIso();
  const error = createNotImplementedError(target.config.platform);

  return {
    id: target.config.id,
    name: target.config.name,
    platform: target.config.platform,
    status: "NOT_IMPLEMENTED",
    startedAt,
    endedAt,
    durationMs: durationMs(startedAt, endedAt),
    scenarios: scenarioResults,
    error,
  };
}

function createNotImplementedScenarioResult(scenario: ScenarioConfig): ScenarioResult {
  const startedAt = nowIso();
  const endedAt = nowIso();

  return {
    id: scenario.id,
    name: scenario.name,
    riskLevel: scenario.riskLevel,
    status: "NOT_IMPLEMENTED",
    startedAt,
    endedAt,
    durationMs: durationMs(startedAt, endedAt),
    steps: [],
    error: {
      code: "RUNNER_NOT_IMPLEMENTED",
      message: "Scenario YAML was loaded, but the platform runner is not implemented yet.",
      kind: "UNSUPPORTED",
    },
  };
}

function createNotImplementedError(platform: Platform): QaError {
  return {
    code: "RUNNER_NOT_IMPLEMENTED",
    message: `${platform} runner is not implemented yet. YAML loading and result reporting are wired.`,
    kind: "UNSUPPORTED",
  };
}

function aggregateStatus(statuses: TestStatus[]): TestStatus {
  if (statuses.length === 0) {
    return "SKIPPED";
  }

  if (statuses.includes("BROKEN")) {
    return "BROKEN";
  }

  if (statuses.includes("FAILED")) {
    return "FAILED";
  }

  if (statuses.includes("NOT_IMPLEMENTED")) {
    return "NOT_IMPLEMENTED";
  }

  if (statuses.every((status) => status === "SKIPPED")) {
    return "SKIPPED";
  }

  return "PASSED";
}
