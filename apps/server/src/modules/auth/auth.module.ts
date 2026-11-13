import { Module } from '@nestjs/common';
import { PlatformModule } from '../platform/platform.module.js';
import { AuthRepository } from './auth.repository.js';
import { AuthService } from './auth.service.js';
import { AuthController } from './auth.controller.js';
@Module({ imports: [PlatformModule], controllers: [AuthController], providers: [AuthRepository, AuthService], exports: [AuthService] })
export class AuthModule {}
