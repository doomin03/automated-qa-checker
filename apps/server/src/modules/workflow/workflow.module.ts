import { Module } from '@nestjs/common';
import { PlatformModule } from '../platform/platform.module.js';
import { WorkflowController } from './workflow.controller.js';
import { WorkflowRepository } from './workflow.repository.js';
import { WorkflowService } from './workflow.service.js';
@Module({imports:[PlatformModule],controllers:[WorkflowController],providers:[WorkflowRepository,WorkflowService],exports:[WorkflowService]})
export class WorkflowModule {}
