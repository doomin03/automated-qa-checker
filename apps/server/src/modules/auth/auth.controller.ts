import { Body, Controller, Get, HttpCode, Post, Query, Req, Res } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import type { Request, Response } from 'express';
import { ApiErrorResponse } from '../../common/errors/api-error.dto.js';
import { AuthService } from './auth.service.js';
import { CallbackQuery, DesktopExchangeInput, DesktopSessionResponse, LoginQuery, LogoutResponse, SessionResponse } from './auth.dto.js';
@ApiTags('auth') @Controller('auth')
@ApiResponse({ status: 400, type: ApiErrorResponse }) @ApiResponse({ status: 401, type: ApiErrorResponse }) @ApiResponse({ status: 403, type: ApiErrorResponse }) @ApiResponse({ status: 503, type: ApiErrorResponse })
export class AuthController {
  constructor(private readonly auth: AuthService) {}
  @Get('start') @ApiOperation({ operationId: 'startOrganizationLogin' }) @ApiResponse({ status: 302, description: 'Browser redirect to the pinned identity provider; not a JSON SDK call.' })
  start(@Query() query: LoginQuery, @Res() response: Response): void { const result = this.auth.startLogin(query.kind, query.redirectUri, query.challenge); response.setHeader('cache-control', 'no-store'); response.setHeader('set-cookie', result.cookie); response.redirect(302, result.url); }
  @Get('callback') @ApiOperation({ operationId: 'completeOrganizationLogin' }) @ApiResponse({ status: 302, description: 'Verified login redirects to the configured web origin or bound Desktop loopback callback.' })
  async callback(@Query() query: CallbackQuery, @Req() request: Request, @Res() response: Response): Promise<void> { const result = await this.auth.callback(query.state, query.code, request.headers.cookie); response.setHeader('cache-control', 'no-store'); response.setHeader('referrer-policy', 'no-referrer'); response.setHeader('set-cookie', result.cookies); response.redirect(302, result.redirect); }
  @Get('session') @ApiOperation({ operationId: 'getOrganizationSession' }) @ApiResponse({ status: 200, type: SessionResponse })
  session(@Req() request: Request, @Res({ passthrough: true }) response: Response): any { response.setHeader('cache-control', 'no-store'); return this.auth.sessionInfo(request.headers.authorization, request.headers.cookie); }
  @Post('desktop/exchange') @HttpCode(200) @ApiOperation({ operationId: 'exchangeDesktopLogin' }) @ApiResponse({ status: 200, type: DesktopSessionResponse })
  exchange(@Body() input: DesktopExchangeInput, @Res({ passthrough: true }) response: Response): any { response.setHeader('cache-control', 'no-store'); return this.auth.exchange(input.code, input.verifier, input.redirectUri); }
  @Post('logout') @HttpCode(200) @ApiOperation({ operationId: 'logoutOrganizationSession' }) @ApiResponse({ status: 200, type: LogoutResponse })
  logout(@Req() request: Request, @Res({ passthrough: true }) response: Response): any { this.auth.logout(request.headers.authorization, request.headers.cookie, request.headers['x-csrf-token'] as string, request.headers.origin); response.setHeader('set-cookie', this.auth.cookies('qa_session', '', 0)); response.setHeader('cache-control', 'no-store'); return { loggedOut: true }; }
}
