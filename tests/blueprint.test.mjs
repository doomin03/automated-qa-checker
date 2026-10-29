import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import {readBlueprint,readEvents,replay,blueprintHash} from '../apps/web/src/entities/blueprint/model.mjs';
const b=readBlueprint(await readFile(new URL('../apps/web/public/demo/blueprint.json',import.meta.url),'utf8'));
const text=await readFile(new URL('../apps/web/public/demo/events.jsonl',import.meta.url),'utf8');
test('real engine FAIL events map to failed node and unrun nodes',async()=>{
 const events=await readEvents(text,b),state=replay(b,events);
 assert.equal(state.outcome,'failed');assert.equal(state.states.home,'failed');assert.equal(state.states.end,'unrun');
 assert.equal(replay(b,events,0).outcome,'not_started');
 assert.equal(replay(b,events,1).outcome,'running');
});
test('duplicates dedupe, reordered events sort and gaps reject',async()=>{
 const lines=text.trim().split('\n');const normal=await readEvents(text,b);
 assert.equal((await readEvents([...lines.reverse(),lines[0]].join('\n'),b)).length,normal.length);
 await assert.rejects(readEvents(text.trim().split('\n').slice(1).join('\n'),b),/sequence/);
});
test('mismatched blueprint, run and conflicting sequence reject',async()=>{
 const changed=structuredClone(b);changed.flow.nodes[1].params.target='other';
 await assert.rejects(readEvents(text,changed),/snapshot/);
 const lines=text.trim().split('\n');const e=JSON.parse(lines[1]);e.runId='other';
 await assert.rejects(readEvents([lines[0],JSON.stringify(e)].join('\n'),b),/run\/attempt/);
 const first=JSON.parse(lines[0]);first.timestamp='different';
 await assert.rejects(readEvents(text+JSON.stringify(first),b),/sequence/);
});
test('live reader waits for incomplete final record',async()=>{
 const events=await readEvents(text+'{"schemaVersion":',b,{live:true});
 assert.equal(replay(b,events).outcome,'failed');
 await assert.rejects(readEvents(text+'{"schemaVersion":',b));
});
test('hash is independent of object key order',async()=>{
 const reordered=Object.fromEntries(Object.entries(b).reverse());
 assert.equal(await blueprintHash(b),await blueprintHash(reordered));
});
test('branch replay leaves the untaken branch unrun',async()=>{
 const branch=structuredClone(b);
 branch.flow.nodes=[{id:'start',type:'start'},{id:'choose',type:'branch',condition:{variable:'username',operator:'equals',value:'qa-user'}},{id:'yes',type:'end'},{id:'no',type:'end'}];
 branch.flow.edges=[{from:'start',to:'choose'},{from:'choose',to:'yes',label:'true'},{from:'choose',to:'no',label:'false'}];
 const events=[{type:'run.started',blueprintSnapshotHash:await blueprintHash(branch)}];
 for(const nodeId of ['start','choose','yes']) {
  events.push({type:'step.started',nodeId});
  events.push({type:'step.finished',nodeId,outcome:'passed',...(nodeId==='choose'?{branch:'true'}:{})});
 }
 events.push({type:'run.finished',outcome:'passed'});
 const source=events.map((event,i)=>JSON.stringify({schemaVersion:'qa.runEvent/v1',runId:'branch-run',attempt:1,sequence:i+1,timestamp:'2026-10-24T01:00:00Z',...event})).join('\n');
 const state=replay(branch,await readEvents(source,branch));
 assert.equal(state.states.yes,'passed');assert.equal(state.states.no,'unrun');
});
test('malicious markup remains data and unsupported actions reject',()=>{
 const changed=structuredClone(b);changed.name='<img src=x onerror=alert(1)>';
 assert.equal(readBlueprint(JSON.stringify(changed)).name,changed.name);
 changed.flow.nodes[1].action='shell';assert.throws(()=>readBlueprint(JSON.stringify(changed)),/규격 오류/);
});

