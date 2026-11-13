import { Module } from '@nestjs/common';
import { PlatformController, LocalIdentityGuard } from './platform.controller.js';
import { PlatformService } from './platform.service.js';
import { PlatformRepository } from './platform.repository.js';
import { EngineContractService } from './engine-contract.service.js';
import { AdministrationController } from '../administration/administration.controller.js';
import { AdministrationService } from '../administration/administration.service.js';
@Module({ controllers: [PlatformController, AdministrationController], providers: [PlatformRepository, EngineContractService, PlatformService, LocalIdentityGuard, AdministrationService], exports: [PlatformService, PlatformRepository, EngineContractService] })
export class PlatformModule {}
