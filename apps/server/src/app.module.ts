import { Module } from '@nestjs/common';
import { HealthController } from './modules/health/health.controller.js';
import { HealthService } from './modules/health/health.service.js';
import { PlatformModule } from './modules/platform/platform.module.js';
import { AuthModule } from './modules/auth/auth.module.js';
import { AgentModule } from './modules/agent/agent.module.js';
import { WorkflowModule } from './modules/workflow/workflow.module.js';
import { SchedulerModule } from './modules/scheduler/scheduler.module.js';
import { SuiteModule } from './modules/suite/suite.module.js';

@Module({ imports: [PlatformModule, AuthModule, AgentModule, WorkflowModule, SchedulerModule, SuiteModule], controllers: [HealthController], providers: [HealthService] })
export class AppModule {}
