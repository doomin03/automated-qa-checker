import { join } from "node:path";

import { ScenarioSchema, validateScenarioHasStepsAfterActions, type ScenarioConfig } from "./scenario-schemas.js";
import { readYamlFile } from "./read-yaml.js";

export async function loadScenario(rootDir: string, scenarioPath: string): Promise<ScenarioConfig> {
  const fullPath = join(rootDir, scenarioPath);
  const scenario = ScenarioSchema.parse(await readYamlFile(fullPath));
  validateScenarioHasStepsAfterActions(scenario);
  return scenario;
}
