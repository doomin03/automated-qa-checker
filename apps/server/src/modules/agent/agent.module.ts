import { Module } from '@nestjs/common';
import { PlatformModule } from '../platform/platform.module.js';
import { AgentController, AgentIdentityGuard } from './agent.controller.js';
import { AgentRepository } from './agent.repository.js';
import { AgentService } from './agent.service.js';
@Module({ imports: [PlatformModule], controllers: [AgentController], providers: [AgentIdentityGuard, AgentRepository, AgentService], exports: [AgentService] })
export class AgentModule {}
