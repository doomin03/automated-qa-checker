import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { ArrayMaxSize, ArrayMinSize, IsArray, IsBoolean, IsString, Matches, MaxLength, MinLength, ValidateNested } from 'class-validator';
import { idPattern } from '../platform/platform.dto.js';
export class SuiteCase {
  @ApiProperty() @Matches(new RegExp(idPattern)) caseId!: string;
  @ApiProperty() @Matches(new RegExp(idPattern)) versionId!: string;
  @ApiProperty({pattern:'^[a-f0-9]{64}$'}) @Matches(/^[a-f0-9]{64}$/) sha256!: string;
}
export class SuiteDraftInput {
  @ApiProperty() @Matches(new RegExp(idPattern)) packageId!: string;
  @ApiProperty({minLength:1,maxLength:200}) @IsString() @MinLength(1) @MaxLength(200) title!: string;
  @ApiProperty() @IsBoolean() stopOnFailure!: boolean;
  @ApiProperty({type:[SuiteCase],minItems:1,maxItems:32}) @IsArray() @ArrayMinSize(1) @ArrayMaxSize(32) @ValidateNested({each:true}) @Type(()=>SuiteCase) cases!: SuiteCase[];
}
export class SuiteDraftResponse extends SuiteDraftInput {
  @ApiProperty() id!: string;
  @ApiProperty() projectId!: string;
  @ApiProperty() authorId!: string;
  @ApiProperty({type:String,nullable:true}) reviewerId!: string | null;
  @ApiProperty({enum:['draft','reviewed','published']}) state!: string;
  @ApiProperty() engineVersion!: string;
  @ApiProperty() contractVersion!: string;
  @ApiProperty({format:'date-time'}) createdAt!: string;
}
export class SuiteResponse extends SuiteDraftInput {
  @ApiProperty() id!: string;
  @ApiProperty() projectId!: string;
  @ApiProperty() version!: string;
  @ApiProperty() sha256!: string;
  @ApiProperty() authorId!: string;
  @ApiProperty() reviewerId!: string;
  @ApiProperty() engineVersion!: string;
  @ApiProperty() contractVersion!: string;
  @ApiProperty({format:'date-time'}) createdAt!: string;
}
export class SuiteDraftPage { @ApiProperty({type:[SuiteDraftResponse]}) items!: SuiteDraftResponse[]; @ApiProperty({type:String,nullable:true}) nextCursor!: string | null; }
export class SuitePage { @ApiProperty({type:[SuiteResponse]}) items!: SuiteResponse[]; @ApiProperty({type:String,nullable:true}) nextCursor!: string | null; }
