import { spawn, execFileSync } from 'node:child_process';
import { createInterface } from 'node:readline';
import { mkdtemp, writeFile, rm } from 'node:fs/promises';
import { resolve, join, dirname } from 'node:path';
import { tmpdir } from 'node:os';
import { root } from './contract-tools.mjs';
const dataDir = await mkdtemp(join(tmpdir(), 'qa-platform-sdk-'));
const engine = resolve(root, '.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs');
const users = ['author', 'reviewer', 'viewer'].map(id => ({ id, token: `${id}-sdk-local-test-token-32-characters`, active: true }));
const identities = { users, projects: [{ id: 'sdk-project', name: 'SDK integration' }], memberships: users.map(u => ({ userId: u.id, projectId: 'sdk-project', role: u.id === 'viewer' ? 'viewer' : 'qa_manager' })) };
const xml = execFileSync(process.execPath, [engine, 'template', '--format', 'xml'], { encoding: 'utf8', windowsHide: true });
const source = join(dataDir, 'source.xml'); await writeFile(source, xml);
const plan = JSON.parse(execFileSync(process.execPath, [engine, 'plan', source, '--json'], { encoding: 'utf8', windowsHide: true }));
const fixture = join(dataDir, 'fixture.json'); await writeFile(fixture, JSON.stringify({ xml, plan }));
const server = spawn(process.execPath, ['apps/server/dist/src/main.js'], { cwd: root, env: { ...process.env, NODE_ENV: 'test', HOST: '127.0.0.1', PORT: '0', API_DOCS: 'false', QA_AUTH_MODE: 'test', QA_DATA_DIR: dataDir, QA_ENGINE_CLI: engine, QA_ENGINE_MANIFEST: resolve(root, 'apps/app/assets/engine-runtime.json'), QA_LOCAL_IDENTITIES_JSON: JSON.stringify(identities) }, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
server.stderr.pipe(process.stderr);
let timer;
try {
  const origin = await new Promise((done, reject) => {
    timer = setTimeout(() => reject(new Error('Platform startup timed out')), 20000);
    server.once('error', reject); server.once('exit', code => reject(new Error(`Server exited ${code}`)));
    createInterface({ input: server.stdout }).on('line', line => { try { const record = JSON.parse(line); if (record.event === 'listening') done(record.url); } catch {} });
  });
  clearTimeout(timer);
  for (const [command, args, cwd] of [
    [process.execPath, ['packages/api-client/test/platform-integration.mjs'], root],
    [process.env.QA_DART ?? resolve(root, '../.tools/flutter-3.47.5/bin/cache/dart-sdk/bin/dart.exe'), ['run', 'tool/platform_integration.dart'], resolve(root, 'packages/api_client_dart')],
  ]) await new Promise((done, reject) => {
    const child = spawn(command, args, { cwd, env: { ...process.env, QA_TEST_ORIGIN: origin, QA_TEST_FIXTURE: fixture }, windowsHide: true, stdio: 'inherit' });
    child.once('error', reject); child.once('exit', code => code === 0 ? done() : reject(new Error(`SDK integration exited ${code}`)));
  });
} finally {
  clearTimeout(timer);
  if (server.exitCode === null) { const closed = new Promise(done => server.once('close', done)); server.kill(); await closed; }
  if (dirname(dataDir) !== resolve(tmpdir()) || !dataDir.split(/[\\/]/).at(-1).startsWith('qa-platform-sdk-')) throw new Error('Unexpected temporary path');
  await rm(dataDir, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
}
