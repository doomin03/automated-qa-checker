import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { ApiErrorResponse } from '../../common/errors/api-error.dto.js';
import { HealthQuery, HealthResponse } from './health.dto.js';
import { HealthService } from './health.service.js';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly health: HealthService) {}

  @Get()
  @ApiOperation({ operationId: 'getHealth' })
  @ApiResponse({ status: 200, type: HealthResponse })
  @ApiResponse({ status: 400, type: ApiErrorResponse, description: 'VALIDATION_ERROR' })
  @ApiResponse({ status: 500, type: ApiErrorResponse, description: 'INTERNAL_ERROR' })
  getHealth(@Query() query: HealthQuery): HealthResponse {
    return this.health.getHealth(query);
  }
}
