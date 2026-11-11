import assert from 'node:assert/strict';
import {readdirSync,readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url));
const receipt=JSON.parse(readFileSync(root+'docs/third-party/flutter-pty2-3.0.0.json'));
const vendor=root+'apps/app/vendor/flutter_pty2/';
const expected={...Object.fromEntries(Object.entries(receipt.files).map(([p,v])=>[p,v.installed])),...receipt.extra};
function walk(dir,prefix=''){return readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(dir+e.name+'/',prefix+e.name+'/'):[prefix+e.name]);}
assert.deepEqual(walk(vendor).sort(),Object.keys(expected).sort());
for(const [path,hash] of Object.entries(expected))assert.equal(createHash('sha256').update(readFileSync(vendor+path)).digest('hex'),hash,path);
assert.deepEqual(Object.entries(receipt.files).filter(([,v])=>v.original!==v.installed).map(([p])=>p),['src/windows/pty_windows_spawn.c']);
console.log(`Terminal vendor: ${Object.keys(expected).length} files verified; one upstream source patch, MIT/provenance preserved.`);
