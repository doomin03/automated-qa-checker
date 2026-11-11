import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus } from '@nestjs/common';
import { randomUUID } from 'node:crypto';
import type { Request, Response } from 'express';
import type { ApiErrorDetail, ApiErrorResponse } from './api-error.dto.js';

export type RequestLog = (record: { requestId: string; method: string; path: string; status: number }) => void;
export type IdentifiedRequest = Request & { requestId?: string };

@Catch()
export class ApiErrorFilter implements ExceptionFilter {
  catch(error: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const request = context.getRequest<IdentifiedRequest>();
    const response = context.getResponse<Response>();
    const parserType = error && typeof error === 'object' && 'type' in error ? error.type : undefined;
    const status = error instanceof HttpException ? error.getStatus() : parserType === 'entity.too.large' ? 413 : parserType === 'entity.parse.failed' ? 400 : HttpStatus.INTERNAL_SERVER_ERROR;
    const codes: Record<number, string> = { 400: 'VALIDATION_ERROR', 401: 'UNAUTHORIZED', 403: 'FORBIDDEN', 404: 'NOT_FOUND', 409: 'CONFLICT', 413: 'PAYLOAD_TOO_LARGE', 500: 'INTERNAL_ERROR', 503: 'UNAVAILABLE' };
    const messages: Record<number, string> = { 400: 'Request validation failed', 401: 'Authentication required', 403: 'Project permission denied', 404: 'API route not found', 409: 'Resource state conflict', 413: 'Request exceeds size limit', 500: 'Internal server error', 503: 'Service unavailable' };
    const code = codes[status] ?? 'HTTP_ERROR';
    const message = messages[status] ?? 'Request failed';
    const detail = error instanceof HttpException ? error.getResponse() : undefined;
    const details = status === 400 && typeof detail === 'object' && detail !== null && 'details' in detail
      ? (detail as { details: ApiErrorDetail[] }).details : [];
    const requestId = request.requestId ?? randomUUID();
    const body: ApiErrorResponse = { code, message, requestId, details };
    response.setHeader('x-request-id', requestId);
    response.status(status).json(body);
  }
}
