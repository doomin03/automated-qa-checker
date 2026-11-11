import { Body, Controller, Get, HttpCode, Param, Post, Put, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { ApiErrorResponse } from '../../common/errors/api-error.dto.js';
import { LocalIdentityGuard } from '../platform/platform.controller.js';
import { WorkflowService } from './workflow.service.js';
import { BaselineInput, ComparisonResponse, NotificationPage, NotificationResponse, WorkInput, WorkResponse } from './workflow.dto.js';

@ApiTags('workflow') @ApiBearerAuth('localBearer') @UseGuards(LocalIdentityGuard)
@ApiResponse({status:400,type:ApiErrorResponse}) @ApiResponse({status:401,type:ApiErrorResponse}) @ApiResponse({status:403,type:ApiErrorResponse})
@ApiResponse({status:404,type:ApiErrorResponse}) @ApiResponse({status:409,type:ApiErrorResponse}) @ApiResponse({status:503,type:ApiErrorResponse})
@Controller('projects/:projectId/runs/:runId')
export class WorkflowController {
  constructor(private readonly workflow: WorkflowService) {}
  @Get('work') @ApiOperation({operationId:'getRunWork'}) @ApiResponse({status:200,type:WorkResponse})
  work(@Req() r:any,@Param('projectId') p:string,@Param('runId') id:string):any{return this.workflow.work(r.localUser,p,id);}
  @Put('work') @ApiOperation({operationId:'updateRunWork'}) @ApiResponse({status:200,type:WorkResponse})
  update(@Req() r:any,@Param('projectId') p:string,@Param('runId') id:string,@Body() b:WorkInput):any{return this.workflow.update(r.localUser,p,id,b);}
  @Get('comparison') @ApiOperation({operationId:'getRunComparison'}) @ApiResponse({status:200,type:ComparisonResponse})
  compare(@Req() r:any,@Param('projectId') p:string,@Param('runId') id:string):any{return this.workflow.compare(r.localUser,p,id);}
  @Put('baseline') @ApiOperation({operationId:'selectRunBaseline'}) @ApiResponse({status:200,type:ComparisonResponse})
  baseline(@Req() r:any,@Param('projectId') p:string,@Param('runId') id:string,@Body() b:BaselineInput):any{return this.workflow.selectBaseline(r.localUser,p,id,b.baselineRunId);}
  @Post('notifications') @HttpCode(200) @ApiOperation({operationId:'enqueueRunNotification'}) @ApiResponse({status:200,type:NotificationResponse})
  enqueue(@Req() r:any,@Param('projectId') p:string,@Param('runId') id:string):any{return this.workflow.enqueue(r.localUser,p,id);}
  @Get('notifications') @ApiOperation({operationId:'listRunNotifications'}) @ApiResponse({status:200,type:NotificationPage})
  notifications(@Req() r:any,@Param('projectId') p:string,@Param('runId') id:string):any{return this.workflow.notifications(r.localUser,p,id);}
}
