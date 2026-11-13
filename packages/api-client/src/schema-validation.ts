import { schemas } from './generated/contract-schema.js';

export class ContractFailure extends Error {
  readonly kind = 'contract';
}

// The constraints are generated from OpenAPI; this interpreter owns no models.
export function validateModel(name: string, value: unknown): void {
  const all = schemas as Record<string, any>;
  function visit(schema: any, item: any, path: string): void {
    const fail = () => { throw new ContractFailure(`Invalid API response at ${path}`); };
    if (item === null) { if (!schema.nullable) fail(); return; }
    if (item === undefined) return fail();
    if (schema.$ref) return visit(all[schema.$ref.split('/').at(-1)], item, path);
    if (schema.allOf) { for (const child of schema.allOf) visit(child, item, path); if (!schema.type) return; }
    if (schema.enum && !schema.enum.includes(item)) fail();
    switch (schema.type) {
      case 'object':
        if (typeof item !== 'object' || Array.isArray(item)) return fail();
        for (const key of schema.required ?? []) if (!Object.hasOwn(item, key)) fail();
        for (const [key, child] of Object.entries(schema.properties ?? {})) if (Object.hasOwn(item, key)) visit(child, item[key], `${path}.${key}`);
        break;
      case 'array':
        if (!Array.isArray(item) || (schema.maxItems !== undefined && item.length > schema.maxItems)) return fail();
        item.forEach((child: unknown, index: number) => visit(schema.items, child, `${path}[${index}]`)); break;
      case 'string':
        if (typeof item !== 'string' || (schema.pattern && !new RegExp(schema.pattern).test(item))) return fail();
        if (schema.format === 'uuid' && !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(item)) fail();
        if (schema.format === 'date-time') {
          if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/.test(item) || !Number.isFinite(Date.parse(item))) return fail();
          if (new Date(item).toISOString().slice(0, 19) !== item.slice(0, 19)) fail();
        }
        break;
      case 'integer': if (!Number.isSafeInteger(item)) return fail();
      // fall through for numeric ranges
      case 'number':
        if (typeof item !== 'number' || !Number.isFinite(item) || (schema.minimum !== undefined && item < schema.minimum) || (schema.maximum !== undefined && item > schema.maximum)) fail(); break;
      case 'boolean': if (typeof item !== 'boolean') fail(); break;
      default: throw new ContractFailure(`Unsupported schema type at ${path}`);
    }
  }
  if (!all[name]) throw new ContractFailure(`Unknown response schema ${name}`);
  visit(all[name], value, name);
}
