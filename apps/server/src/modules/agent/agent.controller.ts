import { Body, CanActivate, Controller, ExecutionContext, Get, HttpCode, Injectable, Param, Post, Put, Query, Req, Res, UseGuards, BadRequestException } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import type { Request, Response } from 'express';
import { AgentService } from './agent.service.js';
import * as D from './agent.dto.js';
import { ApiErrorResponse } from '../../common/errors/api-error.dto.js';
type AgentRequest = Request & { agentId: string };
@Injectable()
export class AgentIdentityGuard implements CanActivate {
  constructor(private readonly service: AgentService) {}
  canActivate(context: ExecutionContext): boolean { const request = context.switchToHttp().getRequest<AgentRequest>(); request.agentId = this.service.authenticate(request.headers.authorization); return true; }
}
@ApiTags('agent') @ApiBearerAuth('agentBearer') @UseGuards(AgentIdentityGuard)
@ApiResponse({ status: 400, type: ApiErrorResponse }) @ApiResponse({ status: 401, type: ApiErrorResponse }) @ApiResponse({ status: 403, type: ApiErrorResponse }) @ApiResponse({ status: 404, type: ApiErrorResponse }) @ApiResponse({ status: 409, type: ApiErrorResponse }) @ApiResponse({ status: 413, type: ApiErrorResponse }) @ApiResponse({ status: 503, type: ApiErrorResponse })
@Controller('agent')
export class AgentController {
  constructor(private readonly service: AgentService) {}
  @Post('claims') @HttpCode(200) @ApiOperation({ operationId: 'claimAgentExecution' }) @ApiResponse({ status: 200, type: D.AgentClaimResponseDto }) @ApiResponse({ status: 204, description: 'No eligible execution' })
  claim(@Req() r: AgentRequest, @Body() b: D.AgentClaimRequestDto, @Res({ passthrough: true }) response: Response): any { const result = this.service.claim(r.agentId, b); if (!result) response.status(204); return result ?? undefined; }
  @Post('leases/:leaseId/heartbeat') @HttpCode(200) @ApiOperation({ operationId: 'heartbeatAgentLease' }) @ApiResponse({ status: 200, type: D.AgentHeartbeatResponseDto })
  heartbeat(@Req() r: AgentRequest, @Param('leaseId') id: string, @Body() b: D.AgentHeartbeatRequestDto): any { return this.service.heartbeat(r.agentId, id, b); }
  @Post('leases/:leaseId/events') @HttpCode(200) @ApiOperation({ operationId: 'appendAgentDeliveries' }) @ApiResponse({ status: 200, type: D.AgentEventsResponseDto })
  events(@Req() r: AgentRequest, @Param('leaseId') id: string, @Body() b: D.AgentEventsRequestDto): any { return this.service.events(r.agentId, id, b); }
  @Put('leases/:leaseId/complete') @ApiOperation({ operationId: 'completeAgentExecution' }) @ApiResponse({ status: 200, type: D.AgentCompleteResponseDto })
  complete(@Req() r: AgentRequest, @Param('leaseId') id: string, @Body() b: D.AgentCompleteRequestDto): any { return this.service.complete(r.agentId, id, b); }
  @Post('reconcile') @HttpCode(200) @ApiOperation({ operationId: 'reconcileAgentInstance' }) @ApiQuery({ name: 'cursor', required: false }) @ApiResponse({ status: 200, type: D.AgentReconcileResponseDto })
  reconcile(@Req() r: AgentRequest, @Body() b: D.AgentReconcileRequestDto, @Query('cursor') cursor?: string): any { if (cursor !== undefined && typeof cursor !== 'string') throw new BadRequestException('Invalid cursor'); return this.service.reconcile(r.agentId, b, cursor); }
  @Get('leases/:leaseId/resources/:resourceId') @ApiOperation({ operationId: 'downloadAgentResource' }) @ApiQuery({ name: 'agentId' }) @ApiQuery({ name: 'instanceId' }) @ApiQuery({ name: 'fence', type: Number }) @ApiResponse({ status: 200, type: D.AgentResourceBytesDto })
  resource(@Req() r: AgentRequest, @Param('leaseId') id: string, @Param('resourceId') resourceId: string, @Query('agentId') agentId: string, @Query('instanceId') instanceId: string, @Query('fence') fence: string): any { if (!/^[1-9]\d*$/.test(fence) || !Number.isSafeInteger(Number(fence))) throw new BadRequestException('Invalid fence'); return this.service.resource(r.agentId, id, resourceId, { agentId, instanceId, fence: Number(fence) }); }
  @Put('leases/:leaseId/artifacts') @ApiOperation({ operationId: 'uploadAgentArtifact' }) @ApiResponse({ status: 200, type: D.AgentArtifactReceiptDto })
  upload(@Req() r: AgentRequest, @Param('leaseId') id: string, @Body() b: D.AgentArtifactUploadRequestDto): any { return this.service.upload(r.agentId, id, b); }
  @Post('leases/:leaseId/historical-evidence') @HttpCode(200) @ApiOperation({ operationId: 'recordHistoricalAgentEvidence' }) @ApiResponse({ status: 200, type: D.AgentHistoricalEvidenceResponseDto })
  historical(@Req() r: AgentRequest, @Param('leaseId') id: string, @Body() b: D.AgentHistoricalEvidenceRequestDto): any { return this.service.historical(r.agentId, id, b); }
  @Post('instances/release') @HttpCode(200) @ApiOperation({ operationId: 'releaseAgentInstance' }) @ApiResponse({ status: 200, type: D.AgentInstanceReleaseResponseDto })
  release(@Req() r: AgentRequest, @Body() b: D.AgentInstanceReleaseRequestDto): any { return this.service.release(r.agentId, b); }
}
