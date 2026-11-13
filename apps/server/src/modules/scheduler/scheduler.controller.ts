import { Body, Controller, Get, HttpCode, Param, Post, Put, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { ApiErrorResponse } from '../../common/errors/api-error.dto.js';
import { LocalIdentityGuard } from '../platform/platform.controller.js';
import { PageQuery } from '../platform/platform.dto.js';
import { SchedulerService } from './scheduler.service.js';
import { ExecutionInput, ExecutionPage, ExecutionResponse, OperatorRecoveryInput, OperatorRecoveryResponse, ScheduleEnabledInput, ScheduleInput, ScheduleOccurrencePage, SchedulePage, ScheduleResponse } from './scheduler.dto.js';
import { AgentService } from '../agent/agent.service.js';
@ApiTags('scheduler') @ApiBearerAuth('localBearer') @UseGuards(LocalIdentityGuard)
@ApiResponse({status:400,type:ApiErrorResponse}) @ApiResponse({status:401,type:ApiErrorResponse}) @ApiResponse({status:403,type:ApiErrorResponse}) @ApiResponse({status:404,type:ApiErrorResponse}) @ApiResponse({status:409,type:ApiErrorResponse}) @ApiResponse({status:503,type:ApiErrorResponse})
@Controller('projects/:projectId')
export class SchedulerController {
  constructor(private readonly scheduler: SchedulerService,private readonly agents: AgentService) {}
  @Post('executions/:executionId/recovery') @HttpCode(200) @ApiOperation({operationId:'recoverExecution'}) @ApiResponse({status:200,type:OperatorRecoveryResponse})
  recover(@Req() r:any,@Param('projectId') p:string,@Param('executionId') id:string,@Body() b:OperatorRecoveryInput):any { return this.agents.recover(r.localUser,p,id,b); }
  @Post('executions') @ApiOperation({operationId:'createExecution'}) @ApiResponse({status:201,type:ExecutionResponse})
  createExecution(@Req() r:any,@Param('projectId') p:string,@Body() b:ExecutionInput):any { return this.scheduler.createExecution(r.localUser,p,b); }
  @Get('executions') @ApiOperation({operationId:'listExecutions'}) @ApiResponse({status:200,type:ExecutionPage})
  executions(@Req() r:any,@Param('projectId') p:string,@Query() q:PageQuery):any { return this.scheduler.executions(r.localUser,p,q); }
  @Get('executions/:executionId') @ApiOperation({operationId:'getExecution'}) @ApiResponse({status:200,type:ExecutionResponse})
  execution(@Req() r:any,@Param('projectId') p:string,@Param('executionId') id:string):any { return this.scheduler.execution(r.localUser,p,id); }
  @Post('executions/:executionId/cancel') @HttpCode(200) @ApiOperation({operationId:'cancelExecution'}) @ApiResponse({status:200,type:ExecutionResponse})
  cancel(@Req() r:any,@Param('projectId') p:string,@Param('executionId') id:string):any { return this.scheduler.cancelExecution(r.localUser,p,id); }
  @Post('schedules') @ApiOperation({operationId:'createSchedule'}) @ApiResponse({status:201,type:ScheduleResponse})
  create(@Req() r:any,@Param('projectId') p:string,@Body() b:ScheduleInput):any { return this.scheduler.create(r.localUser,p,b); }
  @Get('schedules') @ApiOperation({operationId:'listSchedules'}) @ApiResponse({status:200,type:SchedulePage})
  schedules(@Req() r:any,@Param('projectId') p:string,@Query() q:PageQuery):any { return this.scheduler.list(r.localUser,p,q); }
  @Put('schedules/:scheduleId/enabled') @ApiOperation({operationId:'setScheduleEnabled'}) @ApiResponse({status:200,type:ScheduleResponse})
  enabled(@Req() r:any,@Param('projectId') p:string,@Param('scheduleId') id:string,@Body() b:ScheduleEnabledInput):any { return this.scheduler.setEnabled(r.localUser,p,id,b.enabled); }
  @Get('schedules/:scheduleId/occurrences') @ApiOperation({operationId:'listScheduleOccurrences'}) @ApiResponse({status:200,type:ScheduleOccurrencePage})
  occurrences(@Req() r:any,@Param('projectId') p:string,@Param('scheduleId') id:string,@Query() q:PageQuery):any { return this.scheduler.occurrences(r.localUser,p,id,q); }
}
