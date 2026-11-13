import { readFile, readdir, writeFile, realpath } from 'node:fs/promises';
import { createHash } from 'node:crypto';
import { resolve, join, relative, isAbsolute } from 'node:path';
const root = resolve(import.meta.dirname, '../../..');
const candidates = {
  'candidate-1': ['engine-agent-candidate', '917c6ae07acdbec7227bec96443f7be7be23cc7f6d4586f0be12db93c54deee1'],
  'candidate-2': ['engine-agent-candidate2', '0dce64bf4b3be2bab09cce56c96e394f1cfa759eae3b7535f5fbc7e8ae908c45'],
};
const selected = candidates[process.argv[2] ?? 'candidate-1'];
if (!selected) throw new Error('Expected a reviewed candidate-1 or candidate-2');
const [name, expected] = selected;
const directory = resolve(root, '.local', name);
const hash = bytes => createHash('sha256').update(bytes).digest('hex');
if (hash(await readFile(join(directory, 'engine.tgz'))) !== expected) throw new Error('Reviewed candidate archive hash mismatch');
const packageRoot = await realpath(join(directory, 'node_modules/automated-qa-engine'));
const files = {};
async function walk(path) {
  for (const entry of await readdir(path, { withFileTypes: true })) {
    const file = join(path, entry.name), rel = relative(packageRoot, file).replaceAll('\\', '/');
    if (rel.startsWith('..') || isAbsolute(rel) || entry.isSymbolicLink()) throw new Error('Unsafe candidate package path');
    if (entry.isDirectory()) await walk(file); else files[rel] = hash(await readFile(file));
  }
}
await walk(packageRoot);
const manifest = { packageName: 'automated-qa-engine', engineVersion: '0.1.0-alpha.6', artifact: 'engine.tgz', sha256: expected, entrypoint: 'packages/cli/aqa.mjs', files };
await writeFile(join(directory, 'engine-runtime.json'), JSON.stringify(manifest, null, 2) + '\n');
console.log(JSON.stringify({ manifestPath: join(directory, 'engine-runtime.json'), archiveSha256: expected, fileCount: Object.keys(files).length, engineContractSha256: files['contracts/releases/qa-contract-0.1.0-alpha.6.json'] }));
