import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, OpenAPIObject, SwaggerModule } from '@nestjs/swagger';
import { ApiErrorDetail, ApiErrorResponse } from '../common/errors/api-error.dto.js';

export function createOpenApi(app: INestApplication): OpenAPIObject {
  const config = new DocumentBuilder().setTitle('Automated QA Checker API').setVersion('v1')
    .setDescription('Checker HTTP contract; execution schemas belong to the independent QA Engine.').addBearerAuth({ type: 'http', scheme: 'bearer', description: 'Explicit local/test identity token or exchanged organization Desktop token.' }, 'localBearer')
    .addBearerAuth({ type: 'http', scheme: 'bearer', description: 'Provisioned Agent credential; separate from user identities.' }, 'agentBearer').build();
  const document = SwaggerModule.createDocument(app, config, { extraModels: [ApiErrorResponse, ApiErrorDetail] });
  document.openapi = '3.0.3';
  document.components ??= {};
  for (const [name, schema] of Object.entries(document.components.schemas ?? {})) if (name.startsWith('Agent') && !('$ref' in schema) && schema.type === 'object') schema.additionalProperties = false;
  document.components.responses = {
    NotFound: { description: '404 NOT_FOUND for every unknown /api/v1 path', content: { 'application/json': { schema: { $ref: '#/components/schemas/ApiErrorResponse' } } } },
  };
  for (const path of Object.values(document.paths)) {
    for (const method of ['get', 'post', 'put', 'patch', 'delete'] as const) {
      if (path[method]) path[method]!.responses['404'] = { $ref: '#/components/responses/NotFound' };
    }
  }
  return document;
}

export function sortedJson(value: unknown): string {
  const sort = (item: unknown): unknown => Array.isArray(item) ? item.map(sort)
    : item !== null && typeof item === 'object'
      ? Object.fromEntries(Object.entries(item).sort(([a], [b]) => a.localeCompare(b, 'en')).map(([key, value]) => [key, sort(value)])) : item;
  return JSON.stringify(sort(value), null, 2) + '\n';
}
