import assert from 'node:assert/strict';
import { Configuration, FixtureApi, FixtureBodyFromJSON, FixtureBodyToJSON, ApiErrorResponseFromJSON } from './client/dist/generated/index.js';
import { validateModel, ContractFailure } from './client/dist/schema-validation.js';
const origin=process.env.QA_TEST_ORIGIN;
const api=new FixtureApi(new Configuration({basePath:origin,middleware:[{post:async({response})=>{if(response.status===201)validateModel('FixtureBody',await response.clone().json());return response;}}]}));
const value={label:null,choice:'two',count:9007199254740991,measurement:0.125,largeId:'18446744073709551616',utc:'2026-10-31T12:34:56.123Z',values:['한글','x/y','%?']};
validateModel('FixtureBody',value);const body=FixtureBodyFromJSON(value);
assert.equal(FixtureBodyToJSON(body).label,null);assert.equal(FixtureBodyToJSON(body).optional,undefined);
const echoed=await api.fixtureRoundTrip({id:'plain',enabled:false,fixtureBody:body});assert.deepEqual(echoed,body);
const path='segment / 한글 %?';const encoded=await api.fixtureRoundTrip({id:path,enabled:true,fixtureBody:body});assert.equal(encoded.optional,path);
const future=await api.fixtureRoundTrip({id:'unknown-addition',enabled:false,fixtureBody:body});assert.equal(future.largeId,value.largeId);assert.equal('futureField' in future,false);
for(const invalid of [{...value,choice:'future'},{...value,utc:'2026-02-30T12:34:56.123Z'},{...value,count:9007199254740992},{...value,label:undefined}])assert.throws(()=>validateModel('FixtureBody',invalid),ContractFailure);
for(const query of ['enabled=true&enabled=false','enabled=invalid']){
  const response=await fetch(`${origin}/api/v1/__fixture/plain?${query}`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(value)});assert.equal(response.status,400);const error=await response.json();validateModel('ApiErrorResponse',error);assert.equal(ApiErrorResponseFromJSON(error).code,'VALIDATION_ERROR');
}
try{await api.fixtureFailure();assert.fail('Expected HTTP500');}catch(error){assert.equal(error.response.status,500);const body=await error.response.json();validateModel('ApiErrorResponse',body);assert.equal(ApiErrorResponseFromJSON(body).code,'INTERNAL_ERROR');assert.equal(JSON.stringify(body).includes('private-secret-stack'),false);}
console.log('TS expanded fixture SDK actual HTTP PASS');
