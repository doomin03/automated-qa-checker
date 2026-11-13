import { Module } from '@nestjs/common';
import { PlatformModule } from '../platform/platform.module.js';
import { AgentModule } from '../agent/agent.module.js';
import { SchedulerController } from './scheduler.controller.js';
import { SchedulerService } from './scheduler.service.js';
@Module({ imports:[PlatformModule,AgentModule],controllers:[SchedulerController],providers:[SchedulerService],exports:[SchedulerService] })
export class SchedulerModule {}
