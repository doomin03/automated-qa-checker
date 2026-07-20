import { dirname, join, normalize, sep } from "node:path";

import { z } from "zod";

import { readYamlFile } from "./read-yaml.js";
import { TargetConfigSchema, TargetIndexSchema, type Platform, type TargetConfig } from "./schemas.js";

export interface LoadTargetsOptions {
  rootDir: string;
  includeDisabled?: boolean;
  platform?: Platform;
  group?: string;
}

export interface LoadedTarget {
  config: TargetConfig;
  path: string;
}

export async function loadTargets(options: LoadTargetsOptions): Promise<LoadedTarget[]> {
  const indexPath = join(options.rootDir, "configs", "targets", "index.yaml");
  const index = TargetIndexSchema.parse(await readYamlFile(indexPath));
  const indexDir = dirname(indexPath);
  const loaded: LoadedTarget[] = [];

  for (const targetRef of index.targets) {
    const targetPath = normalize(join(indexDir, targetRef));
    const parsed = TargetConfigSchema.parse(await readYamlFile(targetPath));
    assertTargetPathMatchesPlatform(targetPath, parsed.platform);

    if (!options.includeDisabled && !parsed.enabled) {
      continue;
    }

    if (options.platform !== undefined && parsed.platform !== options.platform) {
      continue;
    }

    if (options.group !== undefined && !parsed.group.includes(options.group)) {
      continue;
    }

    loaded.push({ config: parsed, path: targetPath });
  }

  return loaded;
}

function assertTargetPathMatchesPlatform(path: string, platform: Platform): void {
  const marker = `${sep}${platform}${sep}`;

  if (!path.includes(marker)) {
    throw new z.ZodError([
      {
        code: z.ZodIssueCode.custom,
        message: `Target platform '${platform}' must be stored under configs/targets/${platform}/`,
        path: ["platform"],
      },
    ]);
  }
}

export function formatTargetList(targets: LoadedTarget[]): string {
  if (targets.length === 0) {
    return "No enabled targets found.";
  }

  return targets
    .map(({ config }) => {
      const groups = config.group.length > 0 ? config.group.join(",") : "-";
      return `${config.id}\t${config.platform}\t${config.enabled ? "enabled" : "disabled"}\t${groups}\t${config.name}`;
    })
    .join("\n");
}
