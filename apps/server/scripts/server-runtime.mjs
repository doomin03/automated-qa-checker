import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { DatabaseSync } from 'node:sqlite';
import { resolve, join } from 'node:path';

export const root = resolve(import.meta.dirname, '../../..');
export function runtimePaths(env = process.env) {
  const hasCli = !!env.QA_ENGINE_CLI, hasManifest = !!env.QA_ENGINE_MANIFEST;
  if (hasCli !== hasManifest) throw new Error('Set QA_ENGINE_CLI and QA_ENGINE_MANIFEST together');
  return {
    engineCli: env.QA_ENGINE_CLI ?? resolve(root, '.local/engine-server-alpha10/node_modules/automated-qa-engine/packages/cli/aqa.mjs'),
    engineManifest: env.QA_ENGINE_MANIFEST ?? resolve(root, 'packages/contract/runtime/engine-runtime.json'),
  };
}

// Inspect before Platform/Agent startup can reconcile identities or recover leases.
export async function guardRegisteredRuntime(dataDir, manifestPath) {
  const file = join(dataDir, 'platform.sqlite');
  if (!existsSync(file)) return;
  const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
  const contractHash = manifest.files?.[`contracts/releases/qa-contract-${manifest.engineVersion}.json`];
  if (!contractHash) throw new Error('Runtime manifest has no exact contract hash');
  const db = new DatabaseSync(file, { readOnly: true });
  try {
    if (!db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='agents'").get()) return;
    const mismatch = db.prepare('SELECT 1 FROM agents WHERE engine_version<>? OR contract_hash<>? OR (? IS NOT NULL AND contract_version<>?) LIMIT 1').get(manifest.engineVersion, contractHash, manifest.contractVersion ?? null, manifest.contractVersion ?? null);
    if (mismatch) throw new Error('Demo contains Agent registrations for another runtime; use a separate demo identity/state directory');
  } finally { db.close(); }
}
