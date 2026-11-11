import { pathToFileURL } from 'node:url';
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module.js';
import { configureApp, corsOrigins } from './config/configure-app.js';
import { createOpenApi } from './config/openapi.js';
import { platformConfig } from './modules/platform/platform.config.js';
import { PlatformService } from './modules/platform/platform.service.js';
import { AuthService } from './modules/auth/auth.service.js';
import { authConfig } from './modules/auth/auth.config.js';
import { AgentService } from './modules/agent/agent.service.js';
import { WorkflowService } from './modules/workflow/workflow.service.js';
import { SchedulerService } from './modules/scheduler/scheduler.service.js';
import { SuiteService } from './modules/suite/suite.service.js';

export async function bootstrap(): Promise<void> {
  const port = Number(process.env.PORT ?? 3000);
  const platform = platformConfig(process.env);
  const auth = authConfig(process.env);
  if (!Number.isInteger(port) || port < 0 || port > 65535) throw new Error('PORT must be an integer from 0 to 65535');
  const app = await NestFactory.create(AppModule, { logger: ['error', 'warn'] });
  configureApp(app, undefined, [...new Set([...corsOrigins(process.env.CORS_ORIGINS), ...(auth ? [auth.webOrigin] : [])])], Boolean(auth));
  if (platform) {
    await app.get(PlatformService).start(platform); app.get(AgentService).start();
    const workflow = app.get(WorkflowService); workflow.start(process.env);
    app.get(PlatformService).registerWorkStatusResolver(workflow.status.bind(workflow));
    const suites = app.get(SuiteService); suites.start(); app.get(AgentService).registerSuiteResolver(suites.resolvePublished.bind(suites));
    app.get(SchedulerService).start();
  }
  if (auth) { const service = app.get(AuthService); service.start(auth); app.get(PlatformService).registerIdentityResolver(service.resolveIdentity.bind(service)); }
  if (process.env.API_DOCS === 'true') {
    SwaggerModule.setup('api/docs', app, createOpenApi(app), { jsonDocumentUrl: '/api/openapi.json' });
  }
  app.enableShutdownHooks();
  await app.listen(port, process.env.HOST ?? '127.0.0.1');
  process.stdout.write(`${JSON.stringify({ event: 'listening', url: await app.getUrl() })}\n`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) bootstrap().catch(error => { console.error(error.message); process.exitCode = 1; });
