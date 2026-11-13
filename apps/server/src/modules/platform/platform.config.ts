import { isAbsolute } from 'node:path';
import type { Role } from './platform.dto.js';
import { roles } from './platform.dto.js';
import { authConfig, oidcIdentities } from '../auth/auth.config.js';

export interface LocalIdentities {
  users: { id: string; token: string; active: boolean }[];
  projects: { id: string; name: string }[];
  memberships: { userId: string; projectId: string; role: Role }[];
}
export interface PlatformConfig {
  mode: 'local' | 'test' | 'oidc' | 'oidc-test'; dataDir: string; identities: LocalIdentities;
  identityStorage?: 'provisioned' | 'managed';
  engineCli: string; engineManifest: string;
}
export function platformConfig(env: NodeJS.ProcessEnv): PlatformConfig | undefined {
  const mode = env.QA_AUTH_MODE;
  if (!mode || mode === 'disabled') return undefined;
  const identityStorage = env.QA_IDENTITY_STORAGE ?? 'provisioned';
  if (!['provisioned', 'managed'].includes(identityStorage)) throw new Error('Unsupported identity storage mode');
  if (!['local', 'test', 'oidc', 'oidc-test'].includes(mode)) throw new Error('Unsupported authentication mode');
  if (['local', 'test'].includes(mode) && !['development', 'test'].includes(env.NODE_ENV ?? '')) throw new Error('Local identity requires explicit development/test NODE_ENV');
  if (mode !== 'oidc' && !['127.0.0.1', '::1'].includes(env.HOST ?? '127.0.0.1')) throw new Error('Local identity requires a loopback HOST');
  const oidc = ['oidc', 'oidc-test'].includes(mode);
  if (oidc) authConfig(env);
  const dataDir = env.QA_DATA_DIR ?? '';
  const engineCli = env.QA_ENGINE_CLI ?? '';
  const engineManifest = env.QA_ENGINE_MANIFEST ?? '';
  if (![dataDir, engineCli, engineManifest].every(isAbsolute)) throw new Error('QA_DATA_DIR, QA_ENGINE_CLI and QA_ENGINE_MANIFEST must be absolute paths');
  let identities: LocalIdentities;
  try { identities = oidc ? oidcIdentities(env) : JSON.parse(env.QA_LOCAL_IDENTITIES_JSON ?? ''); } catch { throw new Error('Invalid identity provisioning'); }
  if (!identities || !Array.isArray(identities.users) || !Array.isArray(identities.projects) || !Array.isArray(identities.memberships)) throw new Error('Invalid local identity configuration');
  const id = (value: unknown) => typeof value === 'string' && /^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$/.test(value);
  if (identities.users.some(user => !id(user.id) || typeof user.token !== 'string' || user.token.length < 24 || user.token.length > 256 || typeof user.active !== 'boolean') ||
      identities.projects.some(project => !id(project.id) || typeof project.name !== 'string' || !project.name || project.name.length > 200) ||
      identities.memberships.some(member => !id(member.userId) || !id(member.projectId) || !roles.includes(member.role))) throw new Error('Invalid local identity configuration');
  if (new Set(identities.users.map(u => u.id)).size !== identities.users.length || new Set(identities.users.map(u => u.token)).size !== identities.users.length) throw new Error('Duplicate local identity');
  return { mode: mode as PlatformConfig['mode'], identityStorage: identityStorage as PlatformConfig['identityStorage'], dataDir, identities, engineCli, engineManifest };
}
