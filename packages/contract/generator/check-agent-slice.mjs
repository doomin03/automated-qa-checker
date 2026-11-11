import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { isDeepStrictEqual } from 'node:util';
import { root } from './contract-tools.mjs';
const draft = JSON.parse(await readFile(resolve(root, 'packages/contract/agent-protocol/v0.1.0-draft.1/openapi.json')));
const actual = JSON.parse(await readFile(resolve(root, process.argv[2] ?? 'packages/contract/openapi.json')));
function schema(document, value) {
  if (!value) return value;
  if (value.$ref) { const target = value.$ref.split('/').slice(1).reduce((at, key) => at[key], document); return schema(document, { ...target, ...Object.fromEntries(Object.entries(value).filter(([key]) => key !== '$ref')) }); }
  if (value.allOf?.length === 1) return schema(document, { ...value.allOf[0], ...Object.fromEntries(Object.entries(value).filter(([key]) => key !== 'allOf')) });
  return Object.fromEntries(Object.entries(value).filter(([key]) => ['type','enum','format','pattern','nullable','minimum','maximum','minLength','maxLength','minItems','maxItems','uniqueItems','required','properties','items','additionalProperties'].includes(key)).map(([key, item]) => [key, key === 'properties' ? Object.fromEntries(Object.entries(item).map(([name, child]) => [name,schema(document,child)])) : key === 'items' ? schema(document,item) : ['required','enum'].includes(key) ? [...item].sort() : item]));
}
const differences = [];
for (const [path, methods] of Object.entries(draft.paths)) for (const [method, operation] of Object.entries(methods)) {
  if (!operation.operationId) continue;
  const produced = actual.paths[path]?.[method];
  if (!produced || produced.operationId !== operation.operationId) { differences.push(`${method} ${path} operation`); continue; }
  const compare = (label, expected, found) => { const a = schema(draft,expected), b = schema(actual,found); if (!isDeepStrictEqual(a,b)) differences.push(`${method} ${path} ${label}\nexpected=${JSON.stringify(a)}\nactual=${JSON.stringify(b)}`); };
  compare('request', operation.requestBody?.content?.['application/json']?.schema, produced.requestBody?.content?.['application/json']?.schema);
  for (const [status, response] of Object.entries(operation.responses)) if (status.startsWith('2')) compare(`response ${status}`, response.content?.['application/json']?.schema, produced.responses[status]?.content?.['application/json']?.schema);
}
if (differences.length) throw new Error(`Agent slice differs from reviewed contract:\n${differences.join('\n')}`);
console.log('Agent DTO request/success schemas match reviewed contract after reference expansion.');
