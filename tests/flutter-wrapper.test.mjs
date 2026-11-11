import test from 'node:test';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {mkdtempSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
test('Flutter wrapper fails explicitly when SDK is absent instead of a successful placeholder',()=>{
 const missing=mkdtempSync(join(tmpdir(),'qa-missing-flutter-'));
 const run=spawnSync(process.execPath,['scripts/flutter.mjs','analyze'],{env:{...process.env,FLUTTER_SDK:missing},encoding:'utf8',windowsHide:true});
 assert.equal(run.status,1);assert.match(run.stderr,/Flutter 3\.47\.5 SDK/);
});
