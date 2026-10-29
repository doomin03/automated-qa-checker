import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { resolve } from 'node:path';
import { checkSource, checkDependency, checkRepository } from '../scripts/check-boundaries.mjs';

const repository = resolve('boundary-fixture');
const pkg = (path, name, dependencies = {}, exports = { '.': './src/index.mjs' }) => ({ path, directory: resolve(repository, path), manifest: { name, dependencies, exports } });
const contract = pkg('packages/contract', '@qa/contract');
const web = pkg('apps/web', '@qa/web', { '@qa/contract': 'workspace:*', react: '19.3.1' });
const server = pkg('apps/server', '@qa/server');
const client = pkg('packages/api-client', '@qa/api-client');
const packages = [contract, web, server, client];
const scan = (source, file = 'src/pages/example.jsx', owner = web) => checkSource(resolve(owner.directory, file), source, owner, packages);

test('public package imports and downward web imports are allowed', () => {
  assert.deepEqual(scan("import React from 'react'; import {x} from '@qa/contract'; import '../entities/value.mjs';"), []);
  assert.deepEqual(scan("// import '../../server/src/secret.mjs';\nconst s = `import('@qa/contract/src/private')`;"), []);
});

test('relative imports cannot escape an app; re-exports and dynamic imports are checked', () => {
  for (const source of ["import '../../../server/src/index.mjs';", "export {x} from '../../../server/src/index.mjs';", "const x = import('../../../server/src/index.mjs');", "require('../../../server/src/index.mjs');"]) {
    assert.match(scan(source).join('\n'), /cross-package/);
  }
});

test('package deep imports, undeclared imports and computed imports fail', () => {
  assert.match(scan("import '@qa/contract/src/index.mjs';").join('\n'), /public export/);
  assert.match(scan("import 'undeclared';").join('\n'), /undeclared runtime/);
  assert.match(scan('import(target);').join('\n'), /computed module/);
  assert.match(scan("import x = require('../../../server/src/index.mjs');").join('\n'), /cross-package/);
});

test('browser source cannot use Node builtins or reverse FSD layers', () => {
  assert.match(scan("import 'node:fs';").join('\n'), /Node builtin/);
  assert.match(scan("import '../../pages/example.jsx';", 'src/entities/qa/model.mjs').join('\n'), /FSD upward/);
  assert.deepEqual(scan("import 'node:fs';", 'src/main.ts', server), []);
});

test('app dependencies, local links and server SDK imports fail at manifest level', () => {
  assert.match(checkDependency(contract, '@qa/web', 'workspace:*', packages).join('\n'), /application dependency/);
  assert.match(checkDependency(web, '@qa/contract', 'file:../../packages/contract', packages).join('\n'), /local path/);
  assert.match(checkDependency(web, '@qa/contract', '^1.0.0', packages).join('\n'), /workspace:\*/);
  assert.match(checkDependency(server, '@qa/api-client', 'workspace:*', packages).join('\n'), /generated API client/);
});

test('repository scan rejects dependency cycles and hidden source violations', () => {
  const temporary = mkdtempSync(resolve(tmpdir(), 'qa-boundaries-'));
  try {
    mkdirSync(resolve(temporary, 'apps'));
    for (const [name, deps] of [['a', { b: 'workspace:*' }], ['b', { a: 'workspace:*' }]]) {
      const directory = resolve(temporary, 'packages', name);
      mkdirSync(resolve(directory, 'src'), { recursive: true });
      writeFileSync(resolve(directory, 'package.json'), JSON.stringify({ name, dependencies: deps }));
    }
    writeFileSync(resolve(temporary, 'packages/a/src/index.ts'), "export {x} from '../../b/src/index';");
    const errors = checkRepository(temporary).join('\n');
    assert.match(errors, /dependency cycle/);
    assert.match(errors, /cross-package/);
  } finally {
    rmSync(temporary, { recursive: true, force: true });
  }
});
