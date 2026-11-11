import { Module } from '@nestjs/common';
import { PlatformController, LocalIdentityGuard } from './platform.controller.js';
import { PlatformService } from './platform.service.js';
import { PlatformRepository } from './platform.repository.js';
import { EngineContractService } from './engine-contract.service.js';
@Module({ controllers: [PlatformController], providers: [PlatformRepository, EngineContractService, PlatformService, LocalIdentityGuard], exports: [PlatformService, PlatformRepository, EngineContractService] })
export class PlatformModule {}
