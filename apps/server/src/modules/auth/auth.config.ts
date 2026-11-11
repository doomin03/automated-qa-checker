import { randomBytes } from 'node:crypto';
import type { LocalIdentities } from '../platform/platform.config.js';

export interface AuthConfig {
  fixture: boolean; issuer: string; authorizationEndpoint: string; tokenEndpoint: string; jwksUri: string;
  clientId: string; clientSecret: string; callbackUrl: string; webOrigin: string; allowedWorkspaces: string[];
  bindings: { subject: string; workspace: string; userId: string }[];
}
const loopback = (url: URL) => ['127.0.0.1', '[::1]'].includes(url.hostname);
export function authConfig(env: NodeJS.ProcessEnv): AuthConfig | undefined {
  if (!['oidc', 'oidc-test'].includes(env.QA_AUTH_MODE ?? '')) return undefined;
  const fixture = env.QA_AUTH_MODE === 'oidc-test';
  if (fixture && env.NODE_ENV !== 'test') throw new Error('OIDC fixture requires NODE_ENV=test');
  const issuer = fixture ? env.QA_OIDC_TEST_ISSUER ?? '' : 'https://slack.com';
  const base = new URL(issuer);
  if (base.username || base.password || base.search || base.hash || base.pathname !== '/' || (fixture && (!loopback(base) || base.protocol !== 'http:'))) throw new Error('Invalid OIDC issuer');
  const callback = new URL(env.QA_OIDC_CALLBACK_URL ?? '');
  const web = new URL(env.QA_OIDC_WEB_ORIGIN ?? '');
  for (const url of [callback, web]) if (url.username || url.password || url.search || url.hash || (url.protocol !== 'https:' && !(fixture && url.protocol === 'http:' && loopback(url)))) throw new Error('OIDC URLs require HTTPS (or explicit loopback fixture)');
  if (web.pathname !== '/' || callback.pathname !== '/api/v1/auth/callback') throw new Error('OIDC callback and web origin must be exact');
  const clientId = env.QA_OIDC_CLIENT_ID ?? '', clientSecret = env.QA_OIDC_CLIENT_SECRET ?? '';
  if (!clientId || clientId.length > 256 || clientSecret.length < 8 || clientSecret.length > 2048) throw new Error('OIDC client credentials are missing');
  const allowedWorkspaces = (env.QA_OIDC_ALLOWED_WORKSPACES ?? '').split(',').map(s => s.trim()).filter(Boolean);
  if (!allowedWorkspaces.length || allowedWorkspaces.some(s => !/^T[A-Z0-9]{1,64}$/.test(s))) throw new Error('OIDC workspace allowlist is required');
  let bindings: AuthConfig['bindings'];
  try { bindings = JSON.parse(env.QA_OIDC_BINDINGS_JSON ?? ''); } catch { throw new Error('Invalid OIDC bindings'); }
  if (!Array.isArray(bindings) || bindings.length > 10000 || bindings.some(b => !b || typeof b.subject !== 'string' || b.subject.length > 256 || !allowedWorkspaces.includes(b.workspace) || !/^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$/.test(b.userId)) || new Set(bindings.map(b => `${b.workspace}:${b.subject}`)).size !== bindings.length) throw new Error('Invalid OIDC bindings');
  return { fixture, issuer: base.origin, authorizationEndpoint: `${base.origin}/openid/connect/authorize`, tokenEndpoint: `${base.origin}/api/openid.connect.token`, jwksUri: `${base.origin}/openid/connect/keys`, clientId, clientSecret, callbackUrl: callback.href, webOrigin: web.origin, allowedWorkspaces, bindings };
}

/** OIDC principals are explicitly provisioned. No login can add users or roles. */
export function oidcIdentities(env: NodeJS.ProcessEnv): LocalIdentities {
  let value: any;
  try { value = JSON.parse(env.QA_IDENTITY_PROVISION_JSON ?? ''); } catch { throw new Error('Invalid identity provisioning'); }
  if (!value || !Array.isArray(value.users)) throw new Error('Explicit identity provisioning is required');
  return { ...value, users: value.users.map((u: any) => ({ id: u.id, active: u.active, token: randomBytes(32).toString('base64url') })) };
}
