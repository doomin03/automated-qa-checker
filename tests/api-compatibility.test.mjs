import test from 'node:test';
import assert from 'node:assert/strict';
import {spawnSync} from 'node:child_process';
import {breakingChanges} from '../scripts/check-api-compatibility.mjs';
const baseline={openapi:'3.0.3',paths:{'/api/v1/demo':{get:{operationId:'getDemo',parameters:[{in:'query',name:'client',required:false,schema:{type:'string',enum:['web','app']}}],responses:{200:{content:{'application/json':{schema:{$ref:'#/components/schemas/Demo'}}}}}}}},components:{schemas:{Demo:{type:'object',required:['id','value'],properties:{id:{type:'string'},value:{type:'string',nullable:true},extra:{type:'string'}}}}}};
test('API compatibility rejects removed/type/required/nullable/operationId/enum mutations',()=>{
 const mutations=[v=>delete v.paths['/api/v1/demo'],v=>delete v.components.schemas.Demo.properties.id,v=>v.components.schemas.Demo.properties.id.type='number',v=>v.components.schemas.Demo.required.push('extra'),v=>v.components.schemas.Demo.properties.value.nullable=false,v=>v.paths['/api/v1/demo'].get.operationId='renamed',v=>v.paths['/api/v1/demo'].get.parameters[0].schema.enum.pop(),v=>v.paths['/api/v1/demo'].get.parameters.push({in:'query',name:'requiredNew',required:true,schema:{type:'string'}})];
 for(const mutate of mutations){const changed=structuredClone(baseline);mutate(changed);assert.ok(breakingChanges(baseline,changed).length);}
});
test('unknown optional response fields and new operations remain compatible',()=>{const changed=structuredClone(baseline);changed.components.schemas.Demo.properties.future={type:'string'};changed.paths['/api/v1/new']={get:{operationId:'newOperation',responses:{}}};assert.deepEqual(breakingChanges(baseline,changed),[]);});
test('missing baseline is an actual nonzero gate, never a bootstrap success',()=>{const r=spawnSync(process.execPath,['scripts/check-api-compatibility.mjs','--baseline','packages/contract/missing-baseline.json'],{encoding:'utf8',windowsHide:true});assert.notEqual(r.status,0);assert.match(r.stderr,/ENOENT/);});
test('new required response-only fields preserve old client semantics; shared request refs do not',()=>{
 const changed=structuredClone(baseline);changed.components.schemas.Demo.properties.future={type:'string',nullable:true};changed.components.schemas.Demo.required.push('future');assert.deepEqual(breakingChanges(baseline,changed),[]);
 const shared=structuredClone(baseline);shared.paths['/api/v1/input']={post:{operationId:'input',requestBody:{content:{'application/json':{schema:{$ref:'#/components/schemas/Wrapper'}}}},responses:{}}};shared.components.schemas.Wrapper={type:'object',properties:{nested:{$ref:'#/components/schemas/Demo'}}};
 const nextShared=structuredClone(shared);nextShared.components.schemas.Demo=changed.components.schemas.Demo;assert.match(breakingChanges(shared,nextShared).join('\n'),/required set changed/);
 const newlyShared=structuredClone(changed);newlyShared.paths=shared.paths;newlyShared.components.schemas.Wrapper=shared.components.schemas.Wrapper;assert.match(breakingChanges(baseline,newlyShared).join('\n'),/required set changed/);
 const removed=structuredClone(changed);removed.components.schemas.Demo.required=['id','future'];assert.match(breakingChanges(baseline,removed).join('\n'),/required set changed/);
});
