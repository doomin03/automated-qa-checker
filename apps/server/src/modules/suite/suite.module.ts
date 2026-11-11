import { Module } from '@nestjs/common';
import { PlatformModule } from '../platform/platform.module.js';
import { SuiteController } from './suite.controller.js';
import { SuiteService } from './suite.service.js';
@Module({imports:[PlatformModule],controllers:[SuiteController],providers:[SuiteService],exports:[SuiteService]})
export class SuiteModule {}
