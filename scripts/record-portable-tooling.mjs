import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createHash} from 'node:crypto';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const output=resolve(root,'artifacts/releases/desktop-portable-alpha10');
const digest=b=>createHash('sha256').update(b).digest('hex');
const frozen=JSON.parse(await readFile(resolve(output,'source-freeze.json')));
// Preserve the already built app/SDK/vendor/configuration checkpoint.
for(const [path,sha] of Object.entries(frozen.files))assert.equal(digest(await readFile(resolve(root,path))),sha,`Source changed after build: ${path}`);
const files={};
for(const path of ['scripts/install-desktop-engine.mjs','scripts/lib/authoring-artifact.mjs','scripts/prepare-portable-runtime.mjs','scripts/build-portable-desktop.mjs','scripts/record-portable-release.mjs','scripts/record-portable-tooling.mjs','scripts/smoke-portable-release.ps1','scripts/test-portable-relocation.mjs']){
 files[path]=digest(await readFile(resolve(root,path)));
 frozen.files[path]=files[path];
}
await writeFile(resolve(output,'tooling-manifest.json'),JSON.stringify({directory:root,files,manifestSha256:digest(JSON.stringify(files)),timestamp:new Date().toISOString()},null,2)+'\n');
frozen.manifestSha256=digest(JSON.stringify(frozen.files));
frozen.toolingCapturedAt=new Date().toISOString();
await writeFile(resolve(output,'source-freeze.json'),JSON.stringify(frozen,null,2)+'\n');
console.log(JSON.stringify({toolingFiles:Object.keys(files).length,frozenFiles:Object.keys(frozen.files).length,manifestSha256:frozen.manifestSha256}));
