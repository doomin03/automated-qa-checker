import { spawn, spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
import { fileURLToPath } from 'node:url';
const require = createRequire(import.meta.url);
const cwd = fileURLToPath(new URL('../', import.meta.url));
const compiler = require.resolve('typescript/lib/tsc.js');
// Local development defaults only; production bootstrap keeps explicit configuration.
process.env.PORT ??= '4319';
process.env.CORS_ORIGINS ??= 'http://127.0.0.1:4318';
const first = spawnSync(process.execPath, [compiler, '-p', 'tsconfig.json'], { cwd, stdio: 'inherit', windowsHide: true });
if (first.status !== 0) process.exit(first.status ?? 1);
const children = [
  spawn(process.execPath, [compiler, '-p', 'tsconfig.json', '--watch', '--preserveWatchOutput'], { cwd, stdio: 'inherit', windowsHide: true }),
  spawn(process.execPath, ['--watch', 'dist/src/main.js'], { cwd, stdio: 'inherit', windowsHide: true }),
];
let stopping = false;
function stop(code) {
  if (stopping) return;
  stopping = true;
  for (const child of children) child.kill();
  process.exitCode = code;
}
for (const child of children) {
  child.on('error', error => { console.error(error.message); stop(1); });
  child.on('exit', code => stop(code ?? 1));
}
process.on('SIGINT', () => stop(0));
process.on('SIGTERM', () => stop(0));
