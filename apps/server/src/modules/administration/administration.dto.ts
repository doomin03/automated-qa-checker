import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsIn, IsInt, IsString, Matches, Max, MaxLength, Min, ValidateIf } from 'class-validator';
import { idPattern, roles, type Role } from '../platform/platform.dto.js';

export class AdministrationStatus {
  @ApiProperty({ enum: ['provisioned', 'managed'] }) identityStorage!: 'provisioned' | 'managed';
  @ApiProperty() mutationSupported!: boolean;
}
export class ManagedUserResponse {
  @ApiProperty() userId!: string;
  @ApiProperty({ type: String, nullable: true }) displayName!: string | null;
  @ApiProperty() active!: boolean;
  @ApiProperty({ enum: roles }) role!: Role;
  @ApiProperty({ type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER }) userRevision!: number;
  @ApiProperty({ type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER }) membershipRevision!: number;
}
export class ManagedUserPage {
  @ApiProperty({ type: [ManagedUserResponse] }) items!: ManagedUserResponse[];
  @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null;
}
export class ManagedUserCreate {
  @ApiProperty({ pattern: idPattern }) @Matches(new RegExp(idPattern)) userId!: string;
  @ApiProperty({ type: String, nullable: true, maxLength: 200 }) @ValidateIf((_, v) => v !== null) @IsString() @MaxLength(200) displayName!: string | null;
  @ApiProperty({ enum: roles.slice(0, -1) }) @IsIn(roles.slice(0, -1)) role!: Exclude<Role, 'system_admin'>;
}
export class ManagedUserUpdate {
  @ApiProperty({ type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER }) @IsInt() @Min(0) @Max(Number.MAX_SAFE_INTEGER) userRevision!: number;
  @ApiPropertyOptional({ type: String, maxLength: 200 }) @ValidateIf((_, v) => v !== undefined) @IsString() @MaxLength(200) displayName?: string;
  @ApiPropertyOptional({ description: 'true clears the display name; mutually exclusive with displayName.' }) @ValidateIf((_, v) => v !== undefined) @IsBoolean() clearDisplayName?: boolean;
  @ApiPropertyOptional() @ValidateIf((_, v) => v !== undefined) @IsBoolean() active?: boolean;
}
export class ManagedMembershipUpdate {
  @ApiProperty({ enum: roles.slice(0, -1) }) @IsIn(roles.slice(0, -1)) role!: Exclude<Role, 'system_admin'>;
  @ApiProperty({ type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER }) @IsInt() @Min(0) @Max(Number.MAX_SAFE_INTEGER) membershipRevision!: number;
}
export class ManagedMembershipRevisionQuery {
  @ApiProperty({ type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER })
  @Transform(({ value }) => typeof value === 'string' && /^\d+$/.test(value) ? Number(value) : value)
  @IsInt() @Min(0) @Max(Number.MAX_SAFE_INTEGER) membershipRevision!: number;
}
export class ManagedMembershipState {
  @ApiProperty() userId!: string;
  @ApiProperty({ type: String, enum: roles, nullable: true }) role!: Role | null;
  @ApiProperty({ type: 'integer', minimum: 0, maximum: Number.MAX_SAFE_INTEGER }) membershipRevision!: number;
}
