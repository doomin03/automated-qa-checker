import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, ValidateIf } from 'class-validator';

export class HealthQuery {
  @ApiPropertyOptional({ enum: ['web', 'app'] })
  @ValidateIf((_object, value) => value !== undefined)
  @IsIn(['web', 'app'])
  client?: 'web' | 'app';
}

export class HealthResponse {
  @ApiProperty({ enum: ['ok'] })
  status!: 'ok';
  @ApiProperty({ enum: ['automated-qa-checker'] })
  service!: 'automated-qa-checker';
  @ApiProperty({ enum: ['v1'] })
  apiVersion!: 'v1';
  @ApiProperty({ type: String, enum: ['web', 'app', null], nullable: true, required: true })
  client!: 'web' | 'app' | null;
}
