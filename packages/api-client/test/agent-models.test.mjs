import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { AgentReconcileDecisionDtoFromJSON, AgentReconcileDecisionDtoToJSON, ExecutionResponseFromJSON, ExecutionResponseToJSON, validateModel, ContractFailure } from '../dist/index.js';
test('recovered nullable reference validates and generated models round-trip null and object',async()=>{
  const fixture=JSON.parse(await readFile(new URL('../../contract/agent-protocol/v0.1.0-draft.1/examples/reconcile-response.json',import.meta.url)));
  const decision=fixture.decisions[0];validateModel('AgentReconcileDecisionDto',decision);
  assert.equal(AgentReconcileDecisionDtoToJSON(AgentReconcileDecisionDtoFromJSON(decision)).operatorRecovery,null);
  decision.lease.state='recovered';decision.directive='observe';decision.operatorRecovery={id:'99999999-9999-4999-8999-999999999999',confirmedAt:'2026-10-31T00:00:00.000Z',priorFence:1,newFence:2};
  validateModel('AgentReconcileDecisionDto',decision);
  assert.deepEqual(AgentReconcileDecisionDtoToJSON(AgentReconcileDecisionDtoFromJSON(decision)).operatorRecovery,decision.operatorRecovery);
  assert.throws(()=>validateModel('AgentReconcileDecisionDto',{...decision,operatorRecovery:{...decision.operatorRecovery,priorFence:0}}),ContractFailure);
  const missing={...decision};delete missing.operatorRecovery;assert.throws(()=>validateModel('AgentReconcileDecisionDto',missing),ContractFailure);
});
test('execution operational metadata preserves role-redacted nulls and manager recovery',()=>{
  const value={id:'execution',projectId:'demo',state:'recovered',reason:null,leaseId:'lease',resourceKey:null,fence:null,cleanupState:null,operatorRecovery:null,cancelRequested:false,reportedExecutionStatus:null,evidenceStatus:'pending',cases:[],caseRuns:[],createdAt:'2026-10-31T00:00:00.000Z',deadlineAt:null};
  validateModel('ExecutionResponse',value);const redacted=ExecutionResponseToJSON(ExecutionResponseFromJSON(value));for(const key of ['resourceKey','fence','cleanupState','operatorRecovery'])assert.equal(redacted[key],null);
  value.resourceKey='slot';value.fence=3;value.cleanupState='unknown';value.operatorRecovery={id:'99999999-9999-4999-8999-999999999999',confirmedAt:value.createdAt,priorFence:3,newFence:4};validateModel('ExecutionResponse',value);
  assert.deepEqual(ExecutionResponseToJSON(ExecutionResponseFromJSON(value)).operatorRecovery,value.operatorRecovery);
});
