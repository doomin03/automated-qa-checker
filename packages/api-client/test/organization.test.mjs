import { test } from 'node:test';
import assert from 'node:assert/strict';
import { OrganizationClient, PlatformClient, ContractFailure } from '../dist/index.js';
test('organization facade uses generated login path, cookie session, CSRF and bearer Desktop exchange', async () => {
  const calls = [];
  const fetch = async (url, init) => {
    calls.push({ url, init });
    if (String(url).endsWith('/session')) return Response.json({ userId: 'one', localMode: false, projects: [], csrfToken: 'csrf-token' });
    if (String(url).endsWith('/logout')) return Response.json({ loggedOut: true });
    return Response.json({ token: 'desktop-token', expiresAt: '2026-10-31T00:00:00.000Z' });
  };
  const client = new OrganizationClient('http://127.0.0.1:4319', { fetch, csrfToken: 'csrf-token' });
  const login = new URL(client.loginUrl('desktop', 'http://127.0.0.1:5000/callback', 'challenge'));
  assert.equal(login.pathname, '/api/v1/auth/start'); assert.equal(login.searchParams.get('challenge'), 'challenge');
  assert.equal((await client.getSession()).csrfToken, 'csrf-token'); assert.equal(calls[0].init.credentials, 'include');
  assert.equal((await client.logout()).loggedOut, true); assert.equal(new Headers(calls[1].init.headers).get('X-CSRF-Token'), 'csrf-token');
  assert.equal((await client.desktopExchange({ code: 'code', verifier: 'verifier', redirectUri: 'http://127.0.0.1:5000/callback' })).token, 'desktop-token');
  assert.throws(() => new PlatformClient('http://127.0.0.1', ''), TypeError);
  await assert.rejects(new OrganizationClient('http://127.0.0.1', { fetch: async () => Response.json({ userId: 'one', localMode: false, projects: [] }) }).getSession(), ContractFailure);
});
