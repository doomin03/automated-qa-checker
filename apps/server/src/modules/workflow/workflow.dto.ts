import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsInt, IsString, MaxLength, Min, ValidateIf } from 'class-validator';
export class WorkInput {
  @ApiProperty({enum:['todo','in_progress','done']}) @IsIn(['todo','in_progress','done']) status!: string;
  @ApiProperty({type:String,nullable:true,maxLength:128}) @ValidateIf((_, value) => value !== null) @IsString() @MaxLength(128) assigneeId!: string | null;
  @ApiProperty({type:'integer',minimum:0}) @IsInt() @Min(0) revision!: number;
}
export class WorkResponse extends WorkInput {
  @ApiProperty() runId!: string;
  @ApiProperty({type:String,nullable:true}) updatedAt!: string | null;
}
export class BaselineInput { @ApiProperty() @IsString() @MaxLength(128) baselineRunId!: string; }
export class ChangedNode {
  @ApiProperty() nodeId!: string;
  @ApiProperty() previous!: string;
  @ApiProperty() current!: string;
}
export class ComparisonResponse {
  @ApiProperty() runId!: string;
  @ApiProperty({type:String,nullable:true}) baselineRunId!: string | null;
  @ApiProperty() comparable!: boolean;
  @ApiProperty() reason!: string;
  @ApiProperty({enum:['incomparable','regression','improvement','unchanged','changed']}) classification!: string;
  @ApiProperty({type:String,nullable:true}) currentOutcome!: string | null;
  @ApiProperty({type:String,nullable:true}) baselineOutcome!: string | null;
  @ApiProperty({type:[ChangedNode]}) changedNodes!: ChangedNode[];
}
export class NotificationResponse {
  @ApiProperty() id!: string;
  @ApiProperty() runId!: string;
  @ApiProperty({enum:['pending','sending','retrying','delivery_failed','delivered']}) state!: string;
  @ApiProperty({type:'integer'}) attempts!: number;
  @ApiProperty() nextAttemptAt!: string;
  @ApiProperty({type:String,nullable:true}) lastError!: string | null;
  @ApiProperty() createdAt!: string;
}
export class NotificationPage { @ApiProperty({type:[NotificationResponse]}) items!: NotificationResponse[]; }
