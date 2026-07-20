import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";

import type { RunResult, TargetResult } from "../core/results.js";

export async function writeRunJsonReport(rootDir: string, result: RunResult): Promise<string> {
  const runDir = join(rootDir, "outputs", "runs", result.runId);
  await mkdir(join(runDir, "targets"), { recursive: true });

  await writeFile(join(runDir, "run-summary.json"), `${JSON.stringify(result, null, 2)}\n`, "utf8");

  for (const target of result.targets) {
    await writeTargetJsonReport(runDir, target);
  }

  return runDir;
}

async function writeTargetJsonReport(runDir: string, target: TargetResult): Promise<void> {
  const targetDir = join(runDir, "targets", target.id);
  await mkdir(targetDir, { recursive: true });
  await writeFile(join(targetDir, "summary.json"), `${JSON.stringify(target, null, 2)}\n`, "utf8");
}
