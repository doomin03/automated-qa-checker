import 'reflect-metadata';
import { readFile } from 'node:fs/promises';
import { resolve, join, isAbsolute } from 'node:path';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../dist/src/app.module.js';
import { PlatformService } from '../dist/src/modules/platform/platform.service.js';
import { AgentService } from '../dist/src/modules/agent/agent.service.js';
import { demoIdentities } from './agent-demo-identities.mjs';
const root = resolve(import.meta.dirname, '../../..');
const [command, inputFile, tokenFile] = process.argv.slice(2);
if (!['enqueue','enqueue-cases','cancel','provision','recover'].includes(command) || !inputFile || !tokenFile || !isAbsolute(inputFile) || !isAbsolute(tokenFile)) throw new Error('Usage: agent-demo-admin.mjs enqueue|enqueue-cases|cancel|provision|recover ABS_INPUT_JSON ABS_MANAGER_TOKEN_FILE');
if (process.env.NODE_ENV === 'production') throw new Error('Demo management is local development only');
const demoName = process.env.QA_AGENT_DEMO_NAME ?? 'agent-demo-alpha6'; if (!/^[A-Za-z0-9_-]{1,64}$/.test(demoName)) throw new Error('Invalid demo directory name');
const directory = resolve(root, '.local', demoName);
const managerToken = (await readFile(join(directory, 'manager-token.txt'), 'utf8')).trim();
const suppliedToken = (await readFile(tokenFile, 'utf8')).trim();
const input = JSON.parse(await readFile(inputFile, 'utf8'));
if (command === 'recover') {
  const config = JSON.parse(await readFile(join(directory, 'agent-config.json'), 'utf8'));
  const origin = new URL(config.serverUrl);
  if (origin.protocol !== 'http:' || !['127.0.0.1', '[::1]'].includes(origin.hostname)) throw new Error('Recovery demo requires its loopback HTTP server');
  const { requestId, resourceKey, fence, reason, ownerProcessesStopped, externalSessionsStopped } = input;
  const response = await fetch(`${origin.origin}/api/v1/projects/${encodeURIComponent(input.projectId)}/executions/${encodeURIComponent(input.executionId)}/recovery`, { method: 'POST', headers: { authorization: `Bearer ${suppliedToken}`, 'content-type': 'application/json' }, body: JSON.stringify({ requestId, resourceKey, fence, reason, ownerProcessesStopped, externalSessionsStopped }), signal: AbortSignal.timeout(10000) });
  const body = await response.json(); if (!response.ok) throw new Error(`Recovery HTTP ${response.status}: ${body.message}`);
  console.log(JSON.stringify(body)); process.exit(0);
}
if (command === 'enqueue' && input.resources !== undefined) {
  if (!Array.isArray(input.resources) || input.resources.length > 64) throw new Error('Invalid resource count');
  let total = 0;
  input.resources = input.resources.map(resource => {
    if (typeof resource.base64 !== 'string' || resource.base64.length > 13981016 || !/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(resource.base64)) throw new Error('Invalid bounded resource base64');
    const bytes = Buffer.from(resource.base64, 'base64'); total += bytes.length;
    if (bytes.length > 10485760 || total > 67108864) throw new Error('Resource byte quota exceeded');
    return { name: resource.name, bytes, sha256: resource.sha256, mimeType: resource.mimeType };
  });
}
const app = await NestFactory.createApplicationContext(AppModule, { logger: false });
try {
  const platform = app.get(PlatformService);
  await platform.start({ mode: 'local', dataDir: join(directory, 'data'), identities: await demoIdentities(directory, managerToken), engineCli: process.env.QA_ENGINE_CLI ?? resolve(root, '.local/engine-agent-candidate/node_modules/automated-qa-engine/packages/cli/aqa.mjs'), engineManifest: process.env.QA_ENGINE_MANIFEST ?? resolve(root, '.local/engine-agent-candidate/engine-runtime.json') });
  const user = platform.authenticate(`Bearer ${suppliedToken}`), service = app.get(AgentService); service.start(false);
  if (command === 'enqueue') console.log(JSON.stringify({ executionId: await service.enqueue(user, input) }));
  else if (command === 'enqueue-cases') console.log(JSON.stringify({ executionId: await service.enqueueFixtureCases(user,input) }));
  else if (command === 'cancel') console.log(JSON.stringify(service.cancel(user, input.projectId, input.executionId)));
  else if (command === 'recover') console.log(JSON.stringify(service.recover(user,input.projectId,input.executionId,input)));
  else {
    if (!input.outputTokenFile || !isAbsolute(input.outputTokenFile)) throw new Error('Provision requires an absolute outputTokenFile');
    const { writeFile } = await import('node:fs/promises');
    const provisioned = service.provision(user, input); await writeFile(input.outputTokenFile, provisioned.token, { flag: 'wx', mode: 0o600 });
    console.log(JSON.stringify({ agentId: provisioned.agentId, tokenFile: input.outputTokenFile }));
  }
} finally { await app.close(); }
