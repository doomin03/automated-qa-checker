import 'reflect-metadata';
import { randomBytes } from 'node:crypto';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../dist/src/app.module.js';
import { PlatformService } from '../dist/src/modules/platform/platform.service.js';
import { PlatformRepository, sha256 } from '../dist/src/modules/platform/platform.repository.js';
import { AgentService } from '../dist/src/modules/agent/agent.service.js';
import { SuiteService } from '../dist/src/modules/suite/suite.service.js';
import { SchedulerService } from '../dist/src/modules/scheduler/scheduler.service.js';
import { configureApp } from '../dist/src/config/configure-app.js';
import { demoIdentities } from './agent-demo-identities.mjs';
import { runtimePaths, guardRegisteredRuntime } from './server-runtime.mjs';
const root = resolve(import.meta.dirname, '../../..');
if (process.env.NODE_ENV === 'production') throw new Error('Agent demo is loopback development only');
const demoName = process.env.QA_AGENT_DEMO_NAME ?? 'agent-demo-alpha10';
if (!/^[A-Za-z0-9_-]{1,64}$/.test(demoName)) throw new Error('Invalid demo directory name');
const directory = resolve(root, '.local', demoName); await mkdir(directory, { recursive: true });
const runtime = runtimePaths();
await guardRegisteredRuntime(join(directory, 'data'), runtime.engineManifest);
async function secret(file) {
  const path = join(directory, file);
  try { return (await readFile(path, 'utf8')).trim(); }
  catch (error) { if (error.code !== 'ENOENT') throw error; const value = randomBytes(32).toString('base64url'); await writeFile(path, value, { flag: 'wx', mode: 0o600 }); return value; }
}
const managerToken = await secret('manager-token.txt');
const port = Number(process.env.PORT ?? 4320); if (!Number.isInteger(port) || port < 0 || port > 65535) throw new Error('Invalid port');
const target = new URL(process.env.QA_DEMO_TARGET_ORIGIN ?? 'http://127.0.0.1:4317');
if (target.protocol !== 'http:' || !['127.0.0.1', '[::1]'].includes(target.hostname) || target.origin !== target.href.replace(/\/$/, '')) throw new Error('Demo target must be a loopback HTTP origin');
const identities = await demoIdentities(directory, managerToken);
const app = await NestFactory.create(AppModule, { logger: ['warn', 'error'] }); configureApp(app);
const platform = app.get(PlatformService); await platform.start({ mode: 'local', dataDir: join(directory, 'data'), identities, ...runtime });
const service = app.get(AgentService); service.start(); const db = app.get(PlatformRepository);
const suites = app.get(SuiteService); suites.start(); service.registerSuiteResolver(suites.resolvePublished.bind(suites));
app.get(SchedulerService).start();
const user = platform.authenticate(`Bearer ${managerToken}`);
const agentId = 'agent-demo', resourceKey = 'browser-slot-demo';
const capabilities = { platforms: ['web'], actions: ['launch', 'tap', 'input', 'assertText', 'screenshot'] };
const tokenFile = join(directory, 'agent-token.txt');
if (!db.get('SELECT id FROM agents WHERE id=?', agentId)) { const provisioned = service.provision(user, { agentId, projectIds: ['demo'], resourceKeys: [resourceKey], capabilities }); await writeFile(tokenFile, provisioned.token, { flag: 'wx', mode: 0o600 }); }
if (sha256((await readFile(tokenFile, 'utf8')).trim()) !== db.get('SELECT token_hash FROM agents WHERE id=?', agentId).token_hash) throw new Error('Agent credential file does not match provisioned identity');
if (!db.get('SELECT id FROM agent_jobs LIMIT 1')) {
  const fixture = JSON.parse(await readFile(resolve(root, 'packages/contract/agent-protocol/v0.1.0-draft.1/examples/claim-response.json'), 'utf8'));
  const blueprint = JSON.parse(fixture.lease.cases[0].blueprintJson); blueprint.target.allowedOrigins = [target.origin]; blueprint.target.launchTargets.login = target.origin;
  await service.enqueue(user, { projectId: 'demo', caseId: 'case-1', blueprintJson: JSON.stringify(blueprint), executionPolicy: { resourceKey, platform: 'web', allowedOrigins: [target.origin], nativeApps: [], secretRefs: [], allowProduction: false } });
}
await app.listen(port, '127.0.0.1'); app.enableShutdownHooks();
const configFile = join(directory, 'agent-config.json');
await writeFile(configFile, JSON.stringify({ schemaVersion: 'qa.agentConfig/v1', agentId, serverUrl: await app.getUrl(), tokenEnv: 'AQA_AGENT_TOKEN', stateDir: join(directory, 'engine-state'), allowInsecureLocal: true, projectIds: ['demo'], resources: { [resourceKey]: { platform: 'web', allowedOrigins: [target.origin], nativeApps: [], secretRefs: [], actions: capabilities.actions, allowProduction: false } }, credentials: {}, maxRunMs: 60000 }, null, 2) + '\n');
console.log(JSON.stringify({ event: 'agent-demo-ready', serverUrl: await app.getUrl(), targetOrigin: target.origin, configFile, tokenFile, managerTokenFile: join(directory, 'manager-token.txt') }));
