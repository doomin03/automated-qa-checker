import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';
import { IdentityResponse } from '../platform/platform.dto.js';
export class LoginQuery {
  @ApiPropertyOptional({ enum: ['web', 'desktop'], default: 'web' }) @IsOptional() @IsIn(['web', 'desktop']) kind: 'web' | 'desktop' = 'web';
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(1024) redirectUri?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(128) challenge?: string;
}
export class CallbackQuery {
  @ApiProperty() @IsString() @MinLength(1) @MaxLength(256) state!: string;
  @ApiProperty() @IsString() @MinLength(1) @MaxLength(4096) code!: string;
}
export class SessionResponse extends IdentityResponse {
  @ApiProperty({ type: String, nullable: true, required: true }) csrfToken!: string | null;
}
export class DesktopExchangeInput {
  @ApiProperty() @IsString() @MaxLength(128) code!: string;
  @ApiProperty() @IsString() @MaxLength(128) verifier!: string;
  @ApiProperty() @IsString() @MaxLength(1024) redirectUri!: string;
}
export class DesktopSessionResponse {
  @ApiProperty() token!: string;
  @ApiProperty({ format: 'date-time' }) expiresAt!: string;
}
export class LogoutResponse { @ApiProperty({ enum: [true] }) loggedOut!: true; }
