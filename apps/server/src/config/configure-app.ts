import { BadRequestException, INestApplication, ValidationPipe } from '@nestjs/common';
import type { ValidationError } from 'class-validator';
import { randomUUID } from 'node:crypto';
import type { NextFunction, Response } from 'express';
import { ApiErrorFilter, IdentifiedRequest, RequestLog } from '../common/errors/api-error.filter.js';
import type { ApiErrorDetail } from '../common/errors/api-error.dto.js';
import type { NestExpressApplication } from '@nestjs/platform-express';

function validationDetails(errors: ValidationError[], prefix = ''): ApiErrorDetail[] {
  return errors.flatMap(error => {
    const field = prefix ? `${prefix}.${error.property}` : error.property;
    return [
      ...Object.keys(error.constraints ?? {}).map(code => ({ field, code, message: `Invalid value for ${field}` })),
      ...validationDetails(error.children ?? [], field),
    ];
  });
}

export function corsOrigins(setting = ''): string[] {
  if (!setting.trim()) return [];
  return setting.split(',').map(value => {
    const url = new URL(value.trim());
    if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.pathname !== '/' || url.search || url.hash) throw new Error('CORS_ORIGINS must contain exact HTTP(S) origins');
    return url.origin;
  });
}

export function configureApp(app: INestApplication, log: RequestLog = record => process.stdout.write(`${JSON.stringify(record)}\n`), allowedOrigins: string[] = [], credentials = false): void {
  app.setGlobalPrefix('api/v1');
  app.enableCors({ origin: allowedOrigins, credentials, methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'], allowedHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key', 'X-CSRF-Token'], exposedHeaders: ['X-Request-Id'] });
  app.getHttpAdapter().getInstance().set('query parser', 'simple');
  app.use((request: IdentifiedRequest, response: Response, next: NextFunction) => {
    request.requestId = randomUUID();
    response.setHeader('x-request-id', request.requestId);
    response.on('finish', () => log({ requestId: request.requestId!, method: request.method, path: request.path, status: response.statusCode }));
    next();
  });
  (app as NestExpressApplication).useBodyParser('json', { limit: '16mb' });
  app.useGlobalPipes(new ValidationPipe({
    transform: true, whitelist: true, forbidNonWhitelisted: true,
    transformOptions: { enableImplicitConversion: false },
    validationError: { target: false, value: false },
    exceptionFactory: errors => new BadRequestException({ details: validationDetails(errors) }),
  }));
  app.useGlobalFilters(new ApiErrorFilter());
}
