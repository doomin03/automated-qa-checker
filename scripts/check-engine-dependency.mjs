import assert from 'node:assert/strict';
import { readFileSync,existsSync } from 'node:fs';
import { resolve,dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const read=p=>JSON.parse(readFileSync(p,'utf8'));
const dep=read(resolve(root,'packages/contract/engine-dependency.json'));
assert.equal(dep.owner,'automated-qa-engine');
assert.equal(dep.repository,'https://github.com/doomin03/automated-qa-engine');
assert.equal(dep.contractVersion,'0.1.0-draft.1');
assert.equal(dep.status,'local-preview');
assert.equal(dep.engineVersion,'0.1.0-alpha.1');
assert.equal(dep.runtimeIntegrationEnabled,false,'Web viewer must not claim CLI execution integration');
const bytes=readFileSync(resolve(root,'packages/contract/generated/engine-contract.json'));
assert.equal(createHash('sha256').update(bytes).digest('hex'),dep.release.sha256,'Engine artifact hash mismatch');
const bundle=JSON.parse(bytes);
assert.equal(bundle.engineVersion,dep.engineVersion);
assert.equal(bundle.contractVersion,dep.contractVersion);
assert.deepEqual([...dep.requiredSchemas].sort(),[...bundle.schemas].sort());
for(const p of ['package.json','packages/contract/package.json','apps/web/package.json','apps/server/package.json']) {
 if(!existsSync(resolve(root,p)))continue;
 const pkg=read(resolve(root,p));
 for(const group of ['dependencies','devDependencies','optionalDependencies'])for(const[name,version]of Object.entries(pkg[group]||{})) {
  assert(!/^(file:|link:)|^[A-Za-z]:[\\/]|^\.\.?[\\/]/.test(version),'Tracked local dependency: '+name);
  assert(!name.includes('automated-qa-engine'),'Only public contract artifacts are consumed here');
 }
}
if(process.argv[2]) {
 const manifest=read(resolve(process.argv[2]));
 assert.equal(manifest.contractVersion,dep.contractVersion);
 assert.equal(manifest.engineVersion,dep.engineVersion);
 assert.deepEqual([...manifest.schemas].sort(),[...dep.requiredSchemas].sort());
}
console.log('Verified engine '+dep.engineVersion+' contract SHA-256; viewer only, no embedded runner.');

