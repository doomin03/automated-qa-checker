import { cwd } from "node:process";

import { z } from "zod";

import { formatTargetList, loadTargets } from "../config/target-registry.js";
import { PlatformSchema, type Platform } from "../config/schemas.js";

const command = process.argv[2] ?? "help";
const args = process.argv.slice(3);

const supportedCommands = new Set([
  "list",
  "doctor",
  "devices",
  "crawl",
  "discover",
  "scenario",
  "run",
  "capture",
  "coordinate",
  "report",
]);

if (command === "help" || command === "--help" || command === "-h") {
  printHelp();
  process.exit(0);
}

if (!supportedCommands.has(command)) {
  console.error(`[qa] unknown command: ${command}`);
  printHelp();
  process.exit(1);
}

try {
  await runCommand(command, args);
} catch (error) {
  if (error instanceof z.ZodError) {
    console.error("[qa] configuration validation failed");
    for (const issue of error.issues) {
      console.error(`- ${issue.path.join(".") || "(root)"}: ${issue.message}`);
    }
    process.exit(1);
  }

  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}

async function runCommand(name: string, rawArgs: string[]): Promise<void> {
  if (name === "list") {
    const platform = parseOption(rawArgs, "--platform");
    const group = parseOption(rawArgs, "--group");
    const parsedPlatform = platform === undefined ? undefined : PlatformSchema.parse(platform);
    const options: {
      rootDir: string;
      platform?: Platform;
      group?: string;
    } = { rootDir: cwd() };

    if (parsedPlatform !== undefined) {
      options.platform = parsedPlatform;
    }

    if (group !== undefined) {
      options.group = group;
    }

    const targets = await loadTargets(options);

    console.log(formatTargetList(targets));
    return;
  }

  if (name === "doctor") {
    console.log("[qa] doctor is partially scaffolded.");
    console.log("[qa] Android helper: scripts/android/setup-adb.sh or scripts/android/setup-adb.bat");
    console.log("[qa] iOS helper: scripts/ios/setup-simulator.sh (macOS only)");
    return;
  }

  console.log(`[qa] ${name} is not implemented yet.`);
  console.log("[qa] This CLI surface is scaffolded for the OpenSpec implementation.");
}

function parseOption(rawArgs: string[], name: string): string | undefined {
  const index = rawArgs.indexOf(name);
  if (index === -1) {
    return undefined;
  }

  return rawArgs[index + 1];
}

function printHelp(): void {
  console.log(`Usage: pnpm qa:<command> [options]

Commands:
  qa:list        List configured targets
  qa:doctor      Check local tooling and configuration
  qa:devices     List connected or configured devices
  qa:crawl       Run safe web crawler checks
  qa:discover    Discover web URLs for a target
  qa:scenario    Run explicit scenarios
  qa:run         Run target, group, or all checks
  qa:capture     Capture screen evidence
  qa:coordinate  Convert coordinates for a target profile
  qa:report      Regenerate a local report
`);
}
