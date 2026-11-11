import { Body, Controller, Get, Module, Param, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiProperty, ApiPropertyOptional, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { ArrayMaxSize, IsArray, IsBoolean, IsIn, IsInt, IsISO8601, IsNumber, IsString, Matches, Max, Min, ValidateIf } from 'class-validator';
import { AppModule } from '../../src/app.module.js';

export class FixtureBody {
  @ApiProperty({ type: String, nullable: true })
  @ValidateIf((_object, value) => value !== null)
  @IsString()
  label!: string | null;

  @ApiPropertyOptional() @ValidateIf((_object, value) => value !== undefined) @IsString()
  optional?: string;

  @ApiProperty({ enum: ['one', 'two'] }) @IsIn(['one', 'two'])
  choice!: 'one' | 'two';

  @ApiProperty({ type: 'integer', minimum: 0, maximum: 9007199254740991 }) @IsInt() @Min(0) @Max(Number.MAX_SAFE_INTEGER)
  count!: number;

  @ApiProperty({ type: Number }) @IsNumber({ allowNaN: false, allowInfinity: false })
  measurement!: number;

  @ApiProperty({ pattern: '^\\d+$', description: 'Large integer decimal string' }) @Matches(/^\d+$/)
  largeId!: string;

  @ApiProperty({ type: String, format: 'date-time', pattern: '^\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d{1,3})?Z$' })
  @Matches(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/)
  @IsISO8601({ strict: true, strictSeparator: true })
  utc!: string;

  @ApiProperty({ type: [String], maxItems: 10 }) @IsArray() @ArrayMaxSize(10) @IsString({ each: true })
  values!: string[];
}
export class FixturePath {
  @ApiProperty() @IsString() id!: string;
}
export class FixtureQuery {
  @ApiProperty({ type: Boolean })
  @Transform(({ value }) => value === 'true' ? true : value === 'false' ? false : value)
  @IsBoolean() enabled!: boolean;
}
@Controller('__fixture')
@ApiTags('fixture')
class FixtureController {
  @Post(':id') @ApiOperation({ operationId: 'fixtureRoundTrip' }) @ApiResponse({ status: 201, type: FixtureBody })
  roundTrip(@Param() path: FixturePath, @Query() query: FixtureQuery, @Body() body: FixtureBody): FixtureBody {
    if (path.id === 'fail') throw new Error('private-secret-stack');
    if (path.id === 'unknown-addition') return Object.assign(body, { futureField: 'compatible' });
    if (query.enabled) return { ...body, optional: path.id };
    return body;
  }
  @Get('fail') @ApiOperation({ operationId: 'fixtureFailure' })
  fail(): never { throw new Error('private-secret-stack'); }
}
@Module({ imports: [AppModule], controllers: [FixtureController] })
export class FixtureModule {}
