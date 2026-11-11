import 'reflect-metadata';
import {mkdtemp} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {resolve,join} from 'node:path';
import {execFileSync} from 'node:child_process';
import {randomBytes,randomUUID} from 'node:crypto';
import {NestFactory} from '@nestjs/core';
import {AppModule} from '../dist/src/app.module.js';
import {PlatformService} from '../dist/src/modules/platform/platform.service.js';
import {AgentService} from '../dist/src/modules/agent/agent.service.js';
import {SuiteService} from '../dist/src/modules/suite/suite.service.js';
import {SchedulerService} from '../dist/src/modules/scheduler/scheduler.service.js';
import {WorkflowService} from '../dist/src/modules/workflow/workflow.service.js';
import {configureApp} from '../dist/src/config/configure-app.js';
export async function startSuiteUiFixture(webOrigin){
 const root=resolve(import.meta.dirname,'../../..'),cli=resolve(root,'.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'),tokens=Object.fromEntries(['author','reviewer','tester'].map(id=>[id,randomBytes(32).toString('base64url')]));
 const identities={users:Object.entries(tokens).map(([id,token])=>({id,token,active:true})),projects:[{id:'demo',name:'Demo'}],memberships:Object.keys(tokens).map(id=>({userId:id,projectId:'demo',role:id==='tester'?'qa_tester':'qa_manager'}))};
 const app=await NestFactory.create(AppModule,{logger:false});configureApp(app,()=>{},[webOrigin]);const platform=app.get(PlatformService);await platform.start({mode:'test',dataDir:await mkdtemp(join(tmpdir(),'qa-suite-ui-')),identities,engineCli:cli,engineManifest:resolve(root,'apps/app/assets/engine-runtime.json')});
 const agent=app.get(AgentService),suite=app.get(SuiteService);agent.start();suite.start();agent.registerSuiteResolver(suite.resolvePublished.bind(suite));app.get(SchedulerService).start(false);const workflow=app.get(WorkflowService);workflow.start({});platform.registerWorkStatusResolver(workflow.status.bind(workflow));
 agent.provision('author',{agentId:'ui-agent',projectIds:['demo'],resourceKeys:['ui-browser'],capabilities:{platforms:['web'],actions:['launch','input','tap','assertText','screenshot']}});
 const xml=execFileSync(process.execPath,[cli,'template','--format','xml'],{encoding:'utf8',windowsHide:true});const d=await platform.createDraft('author','demo',{packageId:'ui-case',title:'UI case',xml,dependencies:[]});platform.review('reviewer','demo',d.id);const version=await platform.publish('author','demo',d.id,'1.0.0','suite-ui-registry');
 let monotonic=1000;agent.monotonic=()=>monotonic;
 async function makeUncertain(expectedId){const prepared=await agent.preparePublished('author','demo',{versionId:version.id,suiteVersionId:null,sha256:version.sha256,executionPolicy:{resourceKey:'ui-browser',platform:'web',allowedOrigins:['http://127.0.0.1:4317'],nativeApps:[],secretRefs:[],allowProduction:false}});const claim=agent.claim('ui-agent',{agentId:'ui-agent',instanceId:randomUUID(),claimRequestId:randomUUID(),protocolVersion:'0.1.0-draft.1',engineVersion:prepared.engineVersion,engineContractVersion:prepared.engineContractVersion,engineContractSha256:prepared.engineContractSha256,projectIds:['demo'],resourceKeys:['ui-browser'],capabilities:{platforms:['web'],actions:['launch','input','tap','assertText','screenshot']}});if(claim?.lease.executionId!==expectedId)throw Error('Fixture claim identity mismatch');monotonic+=30001;}
 await app.listen(0,'127.0.0.1');return{origin:await app.getUrl(),tokens,version,makeUncertain,close:()=>app.close()};
}
