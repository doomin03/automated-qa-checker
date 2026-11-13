import 'reflect-metadata';
import test from 'node:test';
import assert from 'node:assert/strict';
import {createServer} from 'node:http';
import {mkdtemp} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {randomBytes,createHash} from 'node:crypto';
import {generateKeyPair,exportJWK,SignJWT} from 'jose';
import {NestFactory} from '@nestjs/core';
import {Module} from '@nestjs/common';
import {AppModule} from '../dist/src/app.module.js';
import {AuthModule} from '../dist/src/modules/auth/auth.module.js';
import {AuthService} from '../dist/src/modules/auth/auth.service.js';
import {AuthRepository} from '../dist/src/modules/auth/auth.repository.js';
import {authConfig} from '../dist/src/modules/auth/auth.config.js';
import {PlatformService} from '../dist/src/modules/platform/platform.service.js';
import {configureApp} from '../dist/src/config/configure-app.js';

test('actual OIDC provider signature/state/session and Desktop one-use exchange', {timeout:120000},async t=>{
 const keys=await generateKeyPair('RS256'),wrong=await generateKeyPair('RS256'),jwk={...await exportJWK(keys.publicKey),kid:'fixture-key',alg:'RS256',use:'sig'};
 const codes=new Map();let variant='ok',issuer;const provider=createServer(async(req,res)=>{try{
  const url=new URL(req.url,issuer);res.setHeader('content-type','application/json');
  if(url.pathname==='/openid/connect/keys'){res.end(JSON.stringify({keys:[jwk]}));return;}
  if(url.pathname==='/openid/connect/authorize'){const code=randomBytes(32).toString('hex');codes.set(code,{nonce:url.searchParams.get('nonce'),variant});const next=new URL(url.searchParams.get('redirect_uri'));next.searchParams.set('code',code);next.searchParams.set('state',url.searchParams.get('state'));res.writeHead(302,{location:next.href});res.end();return;}
  if(url.pathname==='/api/openid.connect.token'){
   let body='';for await(const chunk of req)body+=chunk;const fields=new URLSearchParams(body),entry=codes.get(fields.get('code'));codes.delete(fields.get('code'));
   if(!entry||fields.get('client_id')!=='test-client'||fields.get('client_secret')!=='fixture-client-secret'){res.writeHead(400);res.end('{}');return;}
   const now=Math.floor(Date.now()/1000),v=entry.variant;
   const token=await new SignJWT({nonce:v==='nonce'?'wrong':entry.nonce,'https://slack.com/team_id':v==='workspace'?'TOTHER':'TDEMO'}).setProtectedHeader({alg:'RS256',kid:'fixture-key'}).setIssuer(v==='issuer'?'https://wrong.invalid':issuer).setSubject('UDEMO').setAudience(v==='audience'?'wrong-client':'test-client').setIssuedAt(now).setExpirationTime(v==='expired'?now-3600:now+300).sign(v==='signature'?wrong.privateKey:keys.privateKey);
   res.end(JSON.stringify({access_token:'fixture-never-stored',token_type:'Bearer',id_token:token}));return;
  }res.writeHead(404);res.end('{}');
 }catch{res.writeHead(500);res.end('{}');}});
 await new Promise(r=>provider.listen(0,'127.0.0.1',r));issuer=`http://127.0.0.1:${provider.address().port}`;t.after(()=>provider.close());
 class TestRoot{}Module({imports:[AppModule,AuthModule]})(TestRoot);const app=await NestFactory.create(TestRoot,{logger:false});configureApp(app,()=>{});t.after(()=>app.close());
 const root=resolve('../..'),dataDir=await mkdtemp(join(tmpdir(),'qa-auth-'));
 await app.get(PlatformService).start({mode:'test',dataDir,engineCli:resolve(root,'.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'),engineManifest:resolve(root,'apps/app/assets/engine-runtime.json'),identities:{users:[{id:'registered',token:randomBytes(32).toString('base64url'),active:true}],projects:[{id:'demo',name:'Demo'}],memberships:[{userId:'registered',projectId:'demo',role:'qa_tester'}]}});
 await app.listen(0,'127.0.0.1');const origin=await app.getUrl(),webOrigin='http://127.0.0.1:4318',auth=app.get(AuthService),repo=app.get(AuthRepository).platform;
 const env={QA_AUTH_MODE:'oidc-test',NODE_ENV:'test',QA_OIDC_TEST_ISSUER:issuer,QA_OIDC_CLIENT_ID:'test-client',QA_OIDC_CLIENT_SECRET:'fixture-client-secret',QA_OIDC_CALLBACK_URL:`${origin}/api/v1/auth/callback`,QA_OIDC_WEB_ORIGIN:webOrigin,QA_OIDC_ALLOWED_WORKSPACES:'TDEMO',QA_OIDC_BINDINGS_JSON:JSON.stringify([{subject:'UDEMO',workspace:'TDEMO',userId:'registered'}])};auth.start(authConfig(env));
 app.get(PlatformService).registerIdentityResolver?.(auth.resolveIdentity.bind(auth));
 const cookie=response=>response.headers.getSetCookie().map(s=>s.split(';')[0]).join('; ');
 async function begin(query='') {const start=await fetch(`${origin}/api/v1/auth/start${query}`,{redirect:'manual'});assert.equal(start.status,302);const response=await fetch(start.headers.get('location'),{redirect:'manual'});return{url:response.headers.get('location'),cookie:cookie(start)};}
 async function finish(flow){return fetch(flow.url,{redirect:'manual',headers:{cookie:flow.cookie}});}
 await t.test('config fails closed and callback forgery/replay is rejected',async()=>{
  assert.throws(()=>authConfig({...env,NODE_ENV:'production'}));assert.throws(()=>authConfig({...env,QA_OIDC_WEB_ORIGIN:'https://web.test/path'}));
  const flow=await begin();const bad=new URL(flow.url);bad.searchParams.set('state','forged');assert.equal((await finish({...flow,url:bad.href})).status,401);
  assert.equal((await finish({...flow,cookie:''})).status,401);
  const done=await finish(flow);assert.equal(done.status,302);assert.equal((await finish(flow)).status,401);
 });
 await t.test('ID token signature/nonce/audience/issuer/expiry/workspace all deny',async()=>{
  for(const bad of ['signature','nonce','audience','issuer','expired','workspace']){variant=bad;const response=await finish(await begin());assert.equal(response.status,bad==='workspace'?403:401,bad);}variant='ok';
 });
 await t.test('cookie sessions require CSRF, are hash-only and revoke immediately',async()=>{
  const done=await finish(await begin()),sessionCookie=cookie(done);const response=await fetch(`${origin}/api/v1/auth/session`,{headers:{cookie:sessionCookie}});assert.equal(response.status,200);const session=await response.json();assert.equal(session.userId,'registered');assert.equal(session.localMode,false);assert.equal(session.projects[0].role,'qa_tester');
  const raw=sessionCookie.match(/qa_session=([^;]+)/)[1];assert.notEqual(repo.get('SELECT token_hash FROM auth_sessions WHERE token_hash=?',createHash('sha256').update(raw).digest('hex')).token_hash,raw);
  assert.equal((await fetch(`${origin}/api/v1/auth/logout`,{method:'POST',headers:{cookie:sessionCookie,origin:webOrigin}})).status,403);
  assert.equal((await fetch(`${origin}/api/v1/auth/logout`,{method:'POST',headers:{cookie:sessionCookie,origin:'https://evil.invalid','x-csrf-token':session.csrfToken}})).status,403);
  assert.equal((await fetch(`${origin}/api/v1/auth/logout`,{method:'POST',headers:{cookie:sessionCookie,origin:webOrigin,'x-csrf-token':session.csrfToken}})).status,200);
  assert.equal((await fetch(`${origin}/api/v1/auth/session`,{headers:{cookie:sessionCookie}})).status,401);
 });
 await t.test('Desktop callback is loopback, PKCE-bound, one-use and short-lived',async()=>{
  const verifier=randomBytes(32).toString('base64url'),challenge=createHash('sha256').update(verifier).digest('base64url'),redirectUri='http://127.0.0.1:48123/qa/callback';
  assert.equal((await fetch(`${origin}/api/v1/auth/start?kind=desktop&redirectUri=${encodeURIComponent('https://evil.invalid/qa/callback')}&challenge=${challenge}`,{redirect:'manual'})).status,400);
  async function getCode(){const flow=await begin(`?kind=desktop&redirectUri=${encodeURIComponent(redirectUri)}&challenge=${challenge}`),done=await finish(flow);assert.equal(done.status,302);const location=new URL(done.headers.get('location'));assert.equal(location.searchParams.get('state'),challenge);return location.searchParams.get('code');}
  const exchange=(code,v=verifier)=>fetch(`${origin}/api/v1/auth/desktop/exchange`,{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({code,verifier:v,redirectUri})});
  const code=await getCode();assert.equal((await exchange(code,randomBytes(32).toString('base64url'))).status,401);const response=await exchange(code);assert.equal(response.status,200);const {token}=await response.json();assert.equal((await exchange(code)).status,401);
  const session=await fetch(`${origin}/api/v1/auth/session`,{headers:{authorization:`Bearer ${token}`}});assert.equal(session.status,200);assert.equal((await session.json()).csrfToken,null);
  const expired=await getCode();repo.exec('UPDATE desktop_codes SET expires=0');assert.equal((await exchange(expired)).status,401);
  repo.exec('UPDATE users SET active=0 WHERE id=?','registered');assert.equal((await fetch(`${origin}/api/v1/auth/session`,{headers:{authorization:`Bearer ${token}`}})).status,401);
 });
});
