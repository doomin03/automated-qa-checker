import { Injectable } from '@nestjs/common';
import { HealthQuery, HealthResponse } from './health.dto.js';

@Injectable()
export class HealthService {
  getHealth(query: HealthQuery): HealthResponse {
    return { status: 'ok', service: 'automated-qa-checker', apiVersion: 'v1', client: query.client ?? null };
  }
}
