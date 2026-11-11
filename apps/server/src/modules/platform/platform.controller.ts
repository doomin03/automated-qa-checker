import { Body, CanActivate, Controller, ExecutionContext, Get, Headers, HttpCode, Injectable, Param, Post, Put, Query, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import type { Request } from 'express';
import { ApiErrorResponse } from '../../common/errors/api-error.dto.js';
import { PlatformService } from './platform.service.js';
import { ArtifactDownload, ArtifactInput, ArtifactResponse, AuditPage, DiffQuery, DraftInput, DraftPage, DraftResponse, EventBatchInput, EventsQuery, EventsResponse, IdentityResponse, PageQuery, PinInput, PinPage, PinResponse, ProjectPage, PublishInput, ResultInput, RunInput, RunPage, RunResponse, UpgradeDiffResponse, VersionPage, VersionQuery, VersionResponse } from './platform.dto.js';

type LocalRequest = Request & { localUser: string };
@Injectable()
export class LocalIdentityGuard implements CanActivate {
  constructor(private readonly platform: PlatformService) {}
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<LocalRequest>();
    const csrf = request.headers['x-csrf-token'];
    request.localUser = this.platform.authenticate(request.headers.authorization, request.headers.cookie, typeof csrf === 'string' ? csrf : undefined, request.method, request.headers.origin); return true;
  }
}

@ApiTags('platform') @ApiBearerAuth('localBearer') @UseGuards(LocalIdentityGuard)
@ApiResponse({ status: 400, type: ApiErrorResponse }) @ApiResponse({ status: 401, type: ApiErrorResponse }) @ApiResponse({ status: 403, type: ApiErrorResponse })
@ApiResponse({ status: 404, type: ApiErrorResponse }) @ApiResponse({ status: 409, type: ApiErrorResponse }) @ApiResponse({ status: 413, type: ApiErrorResponse }) @ApiResponse({ status: 500, type: ApiErrorResponse }) @ApiResponse({ status: 503, type: ApiErrorResponse })
@Controller()
export class PlatformController {
  constructor(private readonly platform: PlatformService) {}
  @Get('me') @ApiOperation({ operationId: 'getIdentity' }) @ApiResponse({ status: 200, type: IdentityResponse })
  me(@Req() request: LocalRequest): any { return this.platform.me(request.localUser); }
  @Get('projects') @ApiOperation({ operationId: 'listProjects' }) @ApiResponse({ status: 200, type: ProjectPage })
  projects(@Req() r: LocalRequest, @Query() q: PageQuery): any { return this.platform.projects(r.localUser, q); }
  @Post('projects/:projectId/registry/drafts') @ApiOperation({ operationId: 'createRegistryDraft', description: 'qa_editor or higher; no execution.' }) @ApiResponse({ status: 201, type: DraftResponse })
  createDraft(@Req() r: LocalRequest, @Param('projectId') p: string, @Body() b: DraftInput): any { return this.platform.createDraft(r.localUser, p, b); }
  @Get('projects/:projectId/registry/drafts') @ApiOperation({ operationId: 'listRegistryDrafts' }) @ApiResponse({ status: 200, type: DraftPage })
  drafts(@Req() r: LocalRequest, @Param('projectId') p: string, @Query() q: PageQuery): any { return this.platform.listDrafts(r.localUser, p, q); }
  @Post('projects/:projectId/registry/drafts/:draftId/review') @HttpCode(200) @ApiOperation({ operationId: 'reviewRegistryDraft', description: 'A qa_manager other than the author must review.' }) @ApiResponse({ status: 200, type: DraftResponse })
  review(@Req() r: LocalRequest, @Param('projectId') p: string, @Param('draftId') id: string): any { return this.platform.review(r.localUser, p, id); }
  @Post('projects/:projectId/registry/drafts/:draftId/publish') @ApiHeader({ name: 'idempotency-key', required: true }) @ApiOperation({ operationId: 'publishRegistryDraft', description: 'qa_manager; independent active review required.' }) @ApiResponse({ status: 201, type: VersionResponse })
  publish(@Req() r: LocalRequest, @Param('projectId') p: string, @Param('draftId') id: string, @Body() b: PublishInput, @Headers('idempotency-key') key: string): any { return this.platform.publish(r.localUser, p, id, b.version, key ?? ''); }
  @Get('projects/:projectId/registry/versions') @ApiOperation({ operationId: 'listRegistryVersions' }) @ApiResponse({ status: 200, type: VersionPage })
  versions(@Req() r: LocalRequest, @Param('projectId') p: string, @Query() q: VersionQuery): any { return this.platform.versions(r.localUser, p, q); }
  @Get('projects/:projectId/registry/versions/:versionId') @ApiOperation({ operationId: 'getRegistryVersion' }) @ApiResponse({ status: 200, type: VersionResponse })
  version(@Req() r: LocalRequest, @Param('projectId') p: string, @Param('versionId') id: string): any { return this.platform.getVersion(r.localUser, p, id); }
  @Put('projects/:projectId/registry/pins') @ApiOperation({ operationId: 'pinRegistryVersion', description: 'qa_tester or higher; personal immutable upstream selection.' }) @ApiResponse({ status: 200, type: PinResponse })
  pin(@Req() r: LocalRequest, @Param('projectId') p: string, @Body() b: PinInput): any { return this.platform.pin(r.localUser, p, b.versionId, b.sha256); }
  @Get('projects/:projectId/registry/pins') @ApiOperation({ operationId: 'listRegistryPins' }) @ApiResponse({ status: 200, type: PinPage })
  pins(@Req() r: LocalRequest, @Param('projectId') p: string, @Query() q: PageQuery): any { return this.platform.pins(r.localUser, p, q); }
  @Get('projects/:projectId/registry/upgrade-diff') @ApiOperation({ operationId: 'getRegistryUpgradeDiff' }) @ApiResponse({ status: 200, type: UpgradeDiffResponse })
  diff(@Req() r: LocalRequest, @Param('projectId') p: string, @Query() q: DiffQuery): any { return this.platform.diff(r.localUser, p, q.fromVersionId, q.toVersionId); }
  @Post('projects/:projectId/runs') @ApiHeader({ name: 'idempotency-key', required: true }) @ApiOperation({ operationId: 'createSharedRun', description: 'qa_tester; consumes actual run.started and immutable Engine Blueprint snapshot.' }) @ApiResponse({ status: 201, type: RunResponse })
  createRun(@Req() r: LocalRequest, @Param('projectId') p: string, @Body() b: RunInput, @Headers('idempotency-key') key: string): any { return this.platform.createRun(r.localUser, p, b, key ?? ''); }
  @Get('projects/:projectId/runs') @ApiOperation({ operationId: 'listSharedRuns' }) @ApiResponse({ status: 200, type: RunPage })
  runs(@Req() r: LocalRequest, @Param('projectId') p: string, @Query() q: PageQuery): any { return this.platform.runs(r.localUser, p, q); }
  @Get('projects/:projectId/runs/:runId') @ApiOperation({ operationId: 'getSharedRun' }) @ApiResponse({ status: 200, type: RunResponse })
  run(@Req() r: LocalRequest, @Param('projectId') p: string, @Param('runId') id: string): any { return this.platform.getRun(r.localUser, p, id); }
  @Post('projects/:projectId/runs/:runId/events') @HttpCode(200) @ApiOperation({ operationId: 'appendRunEvents' }) @ApiResponse({ status: 200, type: RunResponse })
  append(@Req() r: LocalRequest, @Param('projectId') p: string, @Param('runId') id: string, @Body() b: EventBatchInput): any { return this.platform.appendEvents(r.localUser, p, id, b.eventsJson); }
  @Get('projects/:projectId/runs/:runId/events') @ApiOperation({ operationId: 'pollRunEvents' }) @ApiResponse({ status: 200, type: EventsResponse })
  events(@Req() r: LocalRequest, @Param('projectId') p: string, @Param('runId') id: string, @Query() q: EventsQuery): any { return this.platform.events(r.localUser, p, id, q.afterSequence, q.limit); }
  @Put('projects/:projectId/runs/:runId/result') @ApiOperation({ operationId: 'putRunResult' }) @ApiResponse({ status: 200, type: RunResponse })
  result(@Req() r: LocalRequest, @Param('projectId') p: string, @Param('runId') id: string, @Body() b: ResultInput): any { return this.platform.putResult(r.localUser, p, id, b.resultJson); }
  @Put('projects/:projectId/runs/:runId/artifacts') @ApiOperation({ operationId: 'uploadRunArtifact' }) @ApiResponse({ status: 200, type: ArtifactResponse })
  upload(@Req() r: LocalRequest, @Param('projectId') p: string, @Param('runId') id: string, @Body() b: ArtifactInput): any { return this.platform.upload(r.localUser, p, id, b); }
  @Get('projects/:projectId/runs/:runId/artifacts/:artifactId') @ApiOperation({ operationId: 'downloadRunArtifact' }) @ApiResponse({ status: 200, type: ArtifactDownload })
  download(@Req() r: LocalRequest, @Param('projectId') p: string, @Param('runId') id: string, @Param('artifactId') artifact: string): any { return this.platform.download(r.localUser, p, id, artifact); }
  @Get('projects/:projectId/audit') @ApiOperation({ operationId: 'listProjectAudit' }) @ApiResponse({ status: 200, type: AuditPage })
  audit(@Req() r: LocalRequest, @Param('projectId') p: string, @Query() q: PageQuery): any { return this.platform.audit(r.localUser, p, q); }
}
