import { ArgumentsHost, Catch, ConflictException, ExceptionFilter } from '@nestjs/common';
import type { Response } from 'express';
import type { IdentifiedRequest } from '../../common/errors/api-error.filter.js';

export class IdentityStorageNotManaged extends ConflictException {}
@Catch(IdentityStorageNotManaged)
export class IdentityStorageFilter implements ExceptionFilter {
  catch(_error: IdentityStorageNotManaged, host: ArgumentsHost): void {
    const request = host.switchToHttp().getRequest<IdentifiedRequest>();
    host.switchToHttp().getResponse<Response>().status(409).json({
      code: 'CONFLICT', message: 'Managed identity storage is required', requestId: request.requestId,
      details: [{ field: 'identityStorage', code: 'IDENTITY_STORAGE_NOT_MANAGED', message: 'Administrative changes require explicit managed storage configuration' }],
    });
  }
}
