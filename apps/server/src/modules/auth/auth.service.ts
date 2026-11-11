import { BadRequestException, ForbiddenException, Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { createHash, createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import * as oidc from 'openid-client';
import type { AuthConfig } from './auth.config.js';
import { AuthRepository } from './auth.repository.js';
import { PlatformService } from '../platform/platform.service.js';

const random = () => randomBytes(32).toString('base64url');
const equal = (a: string, b: string) => { const x=Buffer.from(a),y=Buffer.from(b);return x.length===y.length&&timingSafeEqual(x,y); };
export function cookieValue(header: string | undefined, name: string): string | undefined {
  const values = (header ?? '').split(';').map(s => s.trim()).filter(s => s.startsWith(name + '='));
  if (values.length !== 1) return undefined;
  const value = values[0].slice(name.length + 1); return /^[A-Za-z0-9_-]{43}$/.test(value) ? value : undefined;
}
@Injectable()
export class AuthService {
  private settings?: AuthConfig;
  private client?: oidc.Configuration;
  constructor(private readonly repo: AuthRepository, private readonly platform: PlatformService) {}
  private get config(): AuthConfig { if (!this.settings) throw new ServiceUnavailableException('Organization authentication is not configured'); return this.settings; }
  start(config: AuthConfig): void {
    this.repo.start(); this.settings = config;
    this.client = new oidc.Configuration({ issuer: config.issuer, authorization_endpoint: config.authorizationEndpoint, token_endpoint: config.tokenEndpoint, jwks_uri: config.jwksUri, response_types_supported: ['code'], id_token_signing_alg_values_supported: ['RS256'] }, config.clientId, { client_secret: config.clientSecret, id_token_signed_response_alg: 'RS256' }, oidc.ClientSecretPost(config.clientSecret));
    if (config.fixture) oidc.allowInsecureRequests(this.client);
    oidc.enableNonRepudiationChecks(this.client); this.client.timeout = 10;
    this.client[oidc.customFetch] = async (url, options) => {
      if (![config.tokenEndpoint, config.jwksUri].includes(url)) throw new Error('OIDC endpoint is not pinned');
      const response = await fetch(url, { ...options, redirect: 'error', signal: AbortSignal.any([AbortSignal.timeout(10000), ...(options.signal ? [options.signal] : [])]) } as RequestInit);
      const reader = response.body?.getReader(), chunks: Uint8Array[] = []; let size = 0;
      if (reader) while (true) { const part = await reader.read(); if (part.done) break; size += part.value.length; if (size > 1024 * 1024) { await reader.cancel(); throw new Error('OIDC response is too large'); } chunks.push(part.value); }
      return new Response(Buffer.concat(chunks), { status: response.status, headers: response.headers });
    };
  }
  cookies(name: 'qa_session' | 'qa_oidc', value: string, seconds: number): string {
    return `${name}=${value}; Path=/api/v1; HttpOnly; SameSite=Lax; Max-Age=${seconds}${this.config.fixture ? '' : '; Secure'}`;
  }
  startLogin(kind: 'web' | 'desktop', redirect?: string, challenge?: string): { url: string; cookie: string } {
    const config = this.config;
    if (kind === 'desktop') {
      let parsed: URL; try { parsed = new URL(redirect ?? ''); } catch { throw new BadRequestException('Invalid Desktop callback'); }
      if (parsed.protocol !== 'http:' || !['127.0.0.1', '[::1]'].includes(parsed.hostname) || !parsed.port || Number(parsed.port) < 1024 || parsed.pathname !== '/qa/callback' || parsed.search || parsed.hash || parsed.username || parsed.password || !/^[A-Za-z0-9_-]{43}$/.test(challenge ?? '')) throw new BadRequestException('Invalid Desktop callback or challenge');
      redirect = parsed.href;
    } else if (redirect || challenge) throw new BadRequestException('Web callback is server configured');
    const state = random(), nonce = random(), browser = random();
    this.repo.state(state, nonce, browser, kind, redirect ?? null, challenge ?? null);
    const url = oidc.buildAuthorizationUrl(this.client!, { response_type: 'code', scope: 'openid profile email', redirect_uri: config.callbackUrl, state, nonce });
    return { url: url.href, cookie: this.cookies('qa_oidc', browser, 300) };
  }
  async callback(state: string, code: string, cookies?: string): Promise<{ redirect: string; cookies: string[] }> {
    const config = this.config;
    const transaction = this.repo.consumeState(state, cookieValue(cookies, 'qa_oidc') ?? '');
    const url = new URL(config.callbackUrl); url.searchParams.set('state', state); url.searchParams.set('code', code);
    let subject: string, workspace: string;
    try {
      const tokens = await oidc.authorizationCodeGrant(this.client!, url, { expectedState: state, expectedNonce: transaction.nonce, idTokenExpected: true });
      const claims = tokens.claims();
      if (!claims || typeof claims.sub !== 'string' || typeof claims['https://slack.com/team_id'] !== 'string') throw new Error('Missing organization claims');
      subject = claims.sub; workspace = claims['https://slack.com/team_id'];
    } catch { this.repo.platform.audit('', '', 'oidc.denied'); throw new UnauthorizedException('OIDC verification failed'); }
    const binding = config.bindings.find(b => b.subject === subject && b.workspace === workspace);
    if (!config.allowedWorkspaces.includes(workspace) || !binding || !this.repo.platform.get('SELECT u.id FROM users u JOIN memberships m ON m.user_id=u.id WHERE u.id=? AND u.active=1 LIMIT 1', binding.userId)) throw new ForbiddenException('Organization membership is not provisioned');
    this.repo.platform.audit('', binding.userId, 'oidc.authenticated');
    if (transaction.kind === 'desktop') {
      const handoff = random(); this.repo.desktop(handoff, binding.userId, transaction.challenge, transaction.redirect_uri);
      const next = new URL(transaction.redirect_uri); next.searchParams.set('code', handoff); next.searchParams.set('state', transaction.challenge);
      return { redirect: next.href, cookies: [this.cookies('qa_oidc', '', 0)] };
    }
    const token = random(); this.repo.session(token, binding.userId, 'web');
    return { redirect: config.webOrigin + '/', cookies: [this.cookies('qa_oidc', '', 0), this.cookies('qa_session', token, 8 * 3600)] };
  }
  private csrf(token: string): string { return createHmac('sha256', token).update('automated-qa-csrf-v1').digest('base64url'); }
  resolveIdentity(header?: string, cookies?: string, csrf?: string, method = 'GET', origin?: string): string | null {
    if (!this.settings) return null;
    const bearer = header?.match(/^Bearer ([A-Za-z0-9_-]{43})$/)?.[1];
    if (header) {
      const user = bearer && this.repo.lookup(bearer, 'desktop'); if (!user) throw new UnauthorizedException('Session is unavailable'); return user;
    }
    const token = cookieValue(cookies, 'qa_session'), user = token && this.repo.lookup(token, 'web');
    if (!user || !token) throw new UnauthorizedException('Session is unavailable');
    if (!['GET', 'HEAD', 'OPTIONS'].includes(method) && (origin !== this.config.webOrigin || !csrf || !equal(this.csrf(token), csrf))) throw new ForbiddenException('CSRF validation failed');
    return user;
  }
  sessionInfo(header?: string, cookies?: string): any {
    const user = this.resolveIdentity(header, cookies)!; const token = cookieValue(cookies, 'qa_session');
    return { ...this.platform.me(user), localMode: false, csrfToken: header ? null : this.csrf(token!) };
  }
  exchange(code: string, verifier: string, redirect: string): { token: string; expiresAt: string } {
    this.config;
    if (!/^[A-Za-z0-9._~-]{43,128}$/.test(verifier) || !/^[A-Za-z0-9_-]{43}$/.test(code)) throw new UnauthorizedException('Invalid Desktop exchange');
    const challenge = createHash('sha256').update(verifier).digest('base64url');
    const user = this.repo.exchange(code, challenge, redirect), token = random(), expires = this.repo.session(token, user, 'desktop');
    return { token, expiresAt: new Date(expires).toISOString() };
  }
  logout(header?: string, cookies?: string, csrf?: string, origin?: string): void {
    const user = this.resolveIdentity(header, cookies, csrf, 'POST', origin)!;
    const token = header?.slice(7) ?? cookieValue(cookies, 'qa_session')!; this.repo.revoke(token); this.repo.platform.audit('', user, 'session.revoked');
  }
}
