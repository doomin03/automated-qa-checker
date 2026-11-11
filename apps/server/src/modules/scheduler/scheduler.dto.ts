import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, ArrayUnique, IsArray, IsBoolean, IsDefined, IsIn, IsInt, IsString, IsUUID, Matches, Max, MaxLength, Min, MinLength, ValidateIf, ValidateNested } from 'class-validator';
import { AgentCaseSnapshotDto, AgentExecutionPolicyDto, AgentOperatorRecoveryDto } from '../agent/agent.dto.js';
export class ExecutionInput {
  @ApiProperty({ type: String, nullable: true }) @ValidateIf((_o,v) => v !== null) @IsDefined() @IsString() @MaxLength(128) versionId!: string | null;
  @ApiProperty({ type: String, nullable: true }) @ValidateIf((_o,v) => v !== null) @IsDefined() @IsString() @MaxLength(128) suiteVersionId!: string | null;
  @ApiProperty({ pattern: '^[a-f0-9]{64}$' }) @Matches(/^[a-f0-9]{64}$/) sha256!: string;
  @ApiProperty({ type: () => AgentExecutionPolicyDto }) @IsDefined() @ValidateNested() @Type(() => AgentExecutionPolicyDto) executionPolicy!: AgentExecutionPolicyDto;
}
export class ExecutionCaseRun {
  @ApiProperty() caseId!: string;
  @ApiProperty() runId!: string;
}
export class ExecutionResponse {
  @ApiProperty() id!: string;
  @ApiProperty() projectId!: string;
  @ApiProperty() state!: string;
  @ApiProperty({ type: String, nullable: true }) reason!: string | null;
  @ApiProperty({ type: String, nullable: true }) leaseId!: string | null;
  @ApiProperty({ type: String, nullable: true, description: 'Recovery metadata is visible to qa_manager and system_admin only.' }) resourceKey!: string | null;
  @ApiProperty({ type: 'integer', minimum: 1, nullable: true }) fence!: number | null;
  @ApiProperty({ type: String, enum: ['confirmed', 'unknown', 'failed'], nullable: true }) cleanupState!: string | null;
  @ApiProperty({ type: () => AgentOperatorRecoveryDto, nullable: true }) operatorRecovery!: AgentOperatorRecoveryDto | null;
  @ApiProperty() cancelRequested!: boolean;
  @ApiProperty({ type: String, nullable: true }) reportedExecutionStatus!: string | null;
  @ApiProperty({ type: String, nullable: true }) evidenceStatus!: string | null;
  @ApiProperty({ type: [AgentCaseSnapshotDto] }) cases!: AgentCaseSnapshotDto[];
  @ApiProperty({ type: [ExecutionCaseRun] }) caseRuns!: ExecutionCaseRun[];
  @ApiProperty({ format: 'date-time' }) createdAt!: string;
  @ApiProperty({ type: String, nullable: true, format: 'date-time' }) deadlineAt!: string | null;
}
export class ExecutionPage { @ApiProperty({ type: [ExecutionResponse] }) items!: ExecutionResponse[]; @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null; }
export class ScheduleInput extends ExecutionInput {
  @ApiProperty({ maxLength: 128 }) @IsString() @MaxLength(128) timezone!: string;
  @ApiProperty({ type: [Number], minItems: 1, maxItems: 7 }) @IsArray() @ArrayMinSize(1) @ArrayMaxSize(7) @ArrayUnique() @IsInt({ each: true }) @Min(1, { each: true }) @Max(7, { each: true }) weekdays!: number[];
  @ApiProperty({ pattern: '^([01][0-9]|2[0-3]):[0-5][0-9]$' }) @Matches(/^([01][0-9]|2[0-3]):[0-5][0-9]$/) localTime!: string;
  @ApiProperty({ type: 'integer', minimum: 1, maximum: 86400 }) @IsInt() @Min(1) @Max(86400) latenessSeconds!: number;
  @ApiProperty() @IsBoolean() enabled!: boolean;
}
export class ScheduleResponse extends ScheduleInput {
  @ApiProperty() id!: string;
  @ApiProperty() projectId!: string;
  @ApiProperty() createdBy!: string;
  @ApiProperty({ format: 'date-time' }) createdAt!: string;
  @ApiProperty({ format: 'date-time' }) lastScannedAt!: string;
}
export class SchedulePage { @ApiProperty({ type: [ScheduleResponse] }) items!: ScheduleResponse[]; @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null; }
export class ScheduleEnabledInput { @ApiProperty() @IsBoolean() enabled!: boolean; }
export class ScheduleOccurrenceResponse {
  @ApiProperty() id!: string;
  @ApiProperty() scheduleId!: string;
  @ApiProperty() localDate!: string;
  @ApiProperty({ type: String, nullable: true, format: 'date-time' }) occurrenceAt!: string | null;
  @ApiProperty() state!: string;
  @ApiProperty({ type: String, nullable: true }) reason!: string | null;
  @ApiProperty({ type: String, nullable: true }) executionId!: string | null;
}
export class ScheduleOccurrencePage { @ApiProperty({ type: [ScheduleOccurrenceResponse] }) items!: ScheduleOccurrenceResponse[]; @ApiProperty({ type: String, nullable: true }) nextCursor!: string | null; }
export class OperatorRecoveryInput {
  @ApiProperty({ format: 'uuid' }) @IsUUID('all') requestId!: string;
  @ApiProperty() @IsString() @MinLength(1) @MaxLength(256) resourceKey!: string;
  @ApiProperty({ type: 'integer', minimum: 1 }) @IsInt() @Min(1) fence!: number;
  @ApiProperty({ minLength: 1, maxLength: 2000 }) @IsString() @MinLength(1) @MaxLength(2000) reason!: string;
  @ApiProperty({ type: Boolean, enum: [true] }) @IsIn([true]) ownerProcessesStopped!: boolean;
  @ApiProperty({ type: Boolean, enum: [true] }) @IsIn([true]) externalSessionsStopped!: boolean;
}
export class OperatorRecoveryResponse {
  @ApiProperty() executionId!: string;
  @ApiProperty() leaseId!: string;
  @ApiProperty() resourceKey!: string;
  @ApiProperty({ type: () => AgentOperatorRecoveryDto }) recovery!: AgentOperatorRecoveryDto;
}
