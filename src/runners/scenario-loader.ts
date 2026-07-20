import { existsSync } from "node:fs";
import { join } from "node:path";

import { loadScenario } from "../config/scenarios.js";
import type { TargetConfig } from "../config/schemas.js";
import type { ScenarioConfig } from "../config/scenario-schemas.js";

export async function loadTargetScenarios(rootDir: string, target: TargetConfig): Promise<ScenarioConfig[]> {
  const scenarios: ScenarioConfig[] = [];

  for (const scenarioPath of target.scenarioPaths) {
    const fullPath = join(rootDir, scenarioPath);
    if (!existsSync(fullPath)) {
      throw new Error(`Scenario file does not exist: ${scenarioPath}`);
    }

    scenarios.push(await loadScenario(rootDir, scenarioPath));
  }

  return scenarios;
}
