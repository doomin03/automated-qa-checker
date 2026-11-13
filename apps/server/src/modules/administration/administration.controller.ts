import { Body, Controller, Delete, Get, Headers, Param, Patch, Post, Put, Query, Req, UseFilters, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { LocalIdentityGuard } from '../platform/platform.controller.js';
import { PageQuery } from '../platform/platform.dto.js';
import { ApiErrorResponse } from '../../common/errors/api-error.dto.js';
import { AdministrationService } from './administration.service.js';
import { IdentityStorageFilter } from './administration.errors.js';
import { AdministrationStatus, ManagedUserCreate, ManagedUserUpdate, ManagedUserResponse, ManagedUserPage, ManagedMembershipUpdate, ManagedMembershipRevisionQuery, ManagedMembershipState } from './administration.dto.js';

@ApiTags('administration') @ApiBearerAuth('localBearer') @UseGuards(LocalIdentityGuard) @UseFilters(IdentityStorageFilter)
@ApiResponse({ status: 400, type: ApiErrorResponse }) @ApiResponse({ status: 401, type: ApiErrorResponse }) @ApiResponse({ status: 403, type: ApiErrorResponse }) @ApiResponse({ status: 404, type: ApiErrorResponse }) @ApiResponse({ status: 409, type: ApiErrorResponse })
@Controller('projects/:projectId/administration')
export class AdministrationController {
  constructor(private readonly administration: AdministrationService) {}
  @Get() @ApiOperation({ operationId: 'getAdministrationStatus' }) @ApiResponse({ status: 200, type: AdministrationStatus })
  status(@Req() r: any, @Param('projectId') p: string): AdministrationStatus { return this.administration.status(r.localUser, p); }
  @Get('users') @ApiOperation({ operationId: 'listManagedProjectUsers' }) @ApiResponse({ status: 200, type: ManagedUserPage })
  list(@Req() r: any, @Param('projectId') p: string, @Query() q: PageQuery): ManagedUserPage { return this.administration.list(r.localUser, p, q); }
  @Post('users') @ApiHeader({ name: 'idempotency-key', required: true }) @ApiOperation({ operationId: 'createManagedProjectUser' }) @ApiResponse({ status: 201, type: ManagedUserResponse })
  create(@Req() r: any, @Param('projectId') p: string, @Body() b: ManagedUserCreate, @Headers('idempotency-key') key?: string): ManagedUserResponse { return this.administration.create(r.localUser, p, b, key ?? ''); }
  @Patch('users/:userId') @ApiOperation({ operationId: 'updateManagedProjectUser' }) @ApiResponse({ status: 200, type: ManagedUserResponse })
  update(@Req() r: any, @Param('projectId') p: string, @Param('userId') u: string, @Body() b: ManagedUserUpdate): ManagedUserResponse { return this.administration.updateUser(r.localUser, p, u, b); }
  @Get('members/:userId') @ApiOperation({ operationId: 'getManagedMembershipState', description: 'Current or removed membership revision in this project; not a global user lookup.' }) @ApiResponse({ status: 200, type: ManagedMembershipState })
  membership(@Req() r: any, @Param('projectId') p: string, @Param('userId') u: string): ManagedMembershipState { return this.administration.membership(r.localUser, p, u); }
  @Put('members/:userId') @ApiOperation({ operationId: 'updateManagedMembership' }) @ApiResponse({ status: 200, type: ManagedUserResponse })
  putMembership(@Req() r: any, @Param('projectId') p: string, @Param('userId') u: string, @Body() b: ManagedMembershipUpdate): ManagedUserResponse { return this.administration.updateMembership(r.localUser, p, u, b); }
  @Delete('members/:userId') @ApiOperation({ operationId: 'removeManagedMembership' }) @ApiResponse({ status: 200, type: ManagedMembershipState })
  remove(@Req() r: any, @Param('projectId') p: string, @Param('userId') u: string, @Query() q: ManagedMembershipRevisionQuery): ManagedMembershipState { return this.administration.removeMembership(r.localUser, p, u, q.membershipRevision); }
}
