import { Body, Controller, Get, Headers, HttpCode, Param, Post, Put, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { ApiErrorResponse } from '../../common/errors/api-error.dto.js';
import { LocalIdentityGuard } from '../platform/platform.controller.js';
import { PageQuery, PinInput, PinResponse, PublishInput, VersionQuery } from '../platform/platform.dto.js';
import { SuiteDraftInput, SuiteDraftPage, SuiteDraftResponse, SuitePage, SuiteResponse } from './suite.dto.js';
import { SuiteService } from './suite.service.js';
@ApiTags('suite') @ApiBearerAuth('localBearer') @UseGuards(LocalIdentityGuard)
@ApiResponse({status:400,type:ApiErrorResponse}) @ApiResponse({status:401,type:ApiErrorResponse}) @ApiResponse({status:403,type:ApiErrorResponse}) @ApiResponse({status:404,type:ApiErrorResponse}) @ApiResponse({status:409,type:ApiErrorResponse}) @ApiResponse({status:503,type:ApiErrorResponse})
@Controller('projects/:projectId/suites')
export class SuiteController {
 constructor(private readonly suite:SuiteService){}
 @Post('drafts') @ApiOperation({operationId:'createSuiteDraft'}) @ApiResponse({status:201,type:SuiteDraftResponse})
 create(@Req() r:any,@Param('projectId') p:string,@Body() b:SuiteDraftInput):any{return this.suite.create(r.localUser,p,b);}
 @Get('drafts') @ApiOperation({operationId:'listSuiteDrafts'}) @ApiResponse({status:200,type:SuiteDraftPage})
 drafts(@Req() r:any,@Param('projectId') p:string,@Query() q:PageQuery):any{return this.suite.drafts(r.localUser,p,q);}
 @Post('drafts/:draftId/review') @HttpCode(200) @ApiOperation({operationId:'reviewSuiteDraft'}) @ApiResponse({status:200,type:SuiteDraftResponse})
 review(@Req() r:any,@Param('projectId') p:string,@Param('draftId') id:string):any{return this.suite.review(r.localUser,p,id);}
 @Post('drafts/:draftId/publish') @ApiHeader({name:'idempotency-key',required:true}) @ApiOperation({operationId:'publishSuiteDraft'}) @ApiResponse({status:201,type:SuiteResponse})
 publish(@Req() r:any,@Param('projectId') p:string,@Param('draftId') id:string,@Body() b:PublishInput,@Headers('idempotency-key') key:string):any{return this.suite.publish(r.localUser,p,id,b.version,key??'');}
 @Get('versions') @ApiOperation({operationId:'listSuites'}) @ApiResponse({status:200,type:SuitePage})
 versions(@Req() r:any,@Param('projectId') p:string,@Query() q:VersionQuery):any{return this.suite.versions(r.localUser,p,q);}
 @Get('versions/:versionId') @ApiOperation({operationId:'getSuite'}) @ApiResponse({status:200,type:SuiteResponse})
 get(@Req() r:any,@Param('projectId') p:string,@Param('versionId') id:string):any{return this.suite.get(r.localUser,p,id);}
 @Put('pins') @ApiOperation({operationId:'pinSuite'}) @ApiResponse({status:200,type:PinResponse})
 pin(@Req() r:any,@Param('projectId') p:string,@Body() b:PinInput):any{return this.suite.pin(r.localUser,p,b.versionId,b.sha256);}
}
