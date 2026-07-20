import { join } from "node:path";

import { DeviceProfileSchema, type DeviceProfile, type Platform } from "./schemas.js";
import { readYamlFile } from "./read-yaml.js";

export async function loadDeviceProfile(rootDir: string, id: string): Promise<DeviceProfile> {
  const profilePath = join(rootDir, "configs", "devices", `${id}.yaml`);
  return DeviceProfileSchema.parse(await readYamlFile(profilePath));
}

export async function loadTargetDeviceProfile(
  rootDir: string,
  id: string,
  expectedPlatform: Platform,
): Promise<DeviceProfile> {
  const profile = await loadDeviceProfile(rootDir, id);

  if (profile.platform !== expectedPlatform) {
    throw new Error(
      `Device profile '${id}' uses platform '${profile.platform}', expected '${expectedPlatform}'.`,
    );
  }

  return profile;
}
