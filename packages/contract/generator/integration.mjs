import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { resolve } from 'node:path';
import { root } from './contract-tools.mjs';
const server = spawn(process.execPath, ['apps/server/dist/src/main.js'], { cwd: root, env: { ...process.env, PORT: '0', API_DOCS: 'false' }, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
server.stderr.pipe(process.stderr);
const timeout = setTimeout(() => { server.kill(); throw new Error('Nest server did not start'); }, 15000);
try {
  const origin = await new Promise((done, reject) => {
    server.once('error', reject); server.once('exit', code => reject(new Error(`Server exited ${code}`)));
    createInterface({ input: server.stdout }).on('line', line => {
      try { const record = JSON.parse(line); if (record.event === 'listening') done(record.url); } catch {}
    });
  });
  clearTimeout(timeout);
  for (const [command, args, cwd] of [
    [process.execPath, ['packages/api-client/test/integration.mjs'], root],
    [process.env.QA_DART ?? resolve(root, '../.tools/flutter-3.47.5/bin/cache/dart-sdk/bin/dart.exe'), ['run', 'tool/integration.dart'], resolve(root, 'packages/api_client_dart')],
  ]) {
    await new Promise((done, reject) => {
      const child = spawn(command, args, { cwd, env: { ...process.env, QA_TEST_ORIGIN: origin }, windowsHide: true, stdio: 'inherit' });
      child.once('error', reject); child.once('exit', code => code === 0 ? done() : reject(new Error(`Client integration exited ${code}`)));
    });
  }
} finally { clearTimeout(timeout); server.kill(); }
