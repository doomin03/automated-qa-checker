import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { createInterface } from 'node:readline';
import { mkdtemp } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';
import { root } from './contract-tools.mjs';
import { AdministrationApi, Configuration } from '../../api-client/dist/index.js';

const token = randomBytes(32).toString('base64url');
const dataDir = await mkdtemp(resolve(tmpdir(), 'qa-administration-sdk-'));
const identities = { users: [{ id: 'admin', token, active: true }], projects: [{ id: 'sdk', name: 'SDK fixture' }], memberships: [{ userId: 'admin', projectId: 'sdk', role: 'system_admin' }] };
const entry = pathToFileURL(resolve(root, 'apps/server/dist/src/main.js')).href;
const server = spawn(process.execPath, ['--input-type=module', '-e', `import {bootstrap} from ${JSON.stringify(entry)}; await bootstrap();`], {
  cwd: root, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'],
  env: { ...process.env, NODE_ENV: 'test', HOST: '127.0.0.1', PORT: '0', API_DOCS: 'false', QA_AUTH_MODE: 'test', QA_IDENTITY_STORAGE: 'managed', QA_DATA_DIR: dataDir, QA_ENGINE_CLI: resolve(root, '.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'), QA_ENGINE_MANIFEST: resolve(root, 'apps/app/assets/engine-runtime.json'), QA_LOCAL_IDENTITIES_JSON: JSON.stringify(identities) },
});
// Never print authentication-bearing child diagnostics. Count bounded startup output only.
let stderrBytes = 0, timer;
server.stderr.on('data', bytes => { stderrBytes += bytes.length; });
const lines = createInterface({ input: server.stdout });
try {
  const origin = await new Promise((done, reject) => {
    timer = setTimeout(() => reject(new Error(`Fixture startup timeout; stderr bytes=${stderrBytes}`)), 20000);
    server.once('error', () => reject(new Error('Fixture spawn failed')));
    server.once('exit', code => reject(new Error(`Fixture exited ${code}`)));
    lines.on('line', line => { if (line.length < 4096) { try { const record = JSON.parse(line); if (record.event === 'listening') done(record.url); } catch {} } });
  });
  clearTimeout(timer);
  const api = new AdministrationApi(new Configuration({ basePath: origin, accessToken: token }));
  const created = await api.createManagedProjectUser({ projectId: 'sdk', idempotencyKey: 'ts-create', managedUserCreate: { userId: 'ts-member', displayName: '한글 이름', role: 'viewer' } });
  const cleared = await api.updateManagedProjectUser({ projectId: 'sdk', userId: created.userId, managedUserUpdate: { userRevision: created.userRevision, clearDisplayName: true } });
  assert.equal(cleared.displayName, null); assert.equal(cleared.userRevision, 1);
  const named = await api.updateManagedProjectUser({ projectId: 'sdk', userId: created.userId, managedUserUpdate: { userRevision: 1, displayName: '보존' } });
  const disabled = await api.updateManagedProjectUser({ projectId: 'sdk', userId: created.userId, managedUserUpdate: { userRevision: named.userRevision, active: false } });
  assert.equal(disabled.displayName, '보존'); assert.equal(disabled.active, false);
  assert.equal((await api.removeManagedMembership({ projectId: 'sdk', userId: created.userId, membershipRevision: disabled.membershipRevision })).role, null);
  console.log('TypeScript generated API: real Nest create/clear/name/active-only/remove PASS');
  const dart = spawn(resolve(root, '../.tools/flutter-3.47.5/bin/cache/dart-sdk/bin/dart.exe'), ['run', 'tool/administration_models.dart'], { cwd: resolve(root, 'packages/api_client_dart'), env: { ...process.env, QA_TEST_ORIGIN: origin, QA_TEST_ADMIN_TOKEN: token }, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
  let output = '', errorBytes = 0;
  dart.stdout.on('data', bytes => { if (output.length < 8192) output += bytes.toString(); });
  dart.stderr.on('data', bytes => { errorBytes += bytes.length; });
  const deadline = setTimeout(() => dart.kill(), 30000);
  const [code] = await once(dart, 'close'); clearTimeout(deadline);
  assert.equal(code, 0, `Dart integration failed; stderr bytes=${errorBytes}`);
  console.log(output.trim());
  console.log('A07 generated SDK HTTP integration PASS; temporary database retained for diagnosis.');
} finally {
  clearTimeout(timer); lines.close();
  if (server.exitCode === null) { const closed = once(server, 'close'); server.kill(); await closed; }
}
