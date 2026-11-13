// Test-only RS256 issuer and actual Nest server; no external OIDC or messages.
import {createServer} from 'node:http';
import {mkdtemp} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {randomBytes} from 'node:crypto';
import {pathToFileURL} from 'node:url';
import {createRequire} from 'node:module';
const require=createRequire(new URL('../apps/server/package.json',import.meta.url));
require('reflect-metadata');
const {generateKeyPair,exportJWK,SignJWT}=await import(pathToFileURL(require.resolve('jose')).href);
const {NestFactory}=await import(pathToFileURL(require.resolve('@nestjs/core')).href);
const {AppModule}=await import('../apps/server/dist/src/app.module.js');
const {PlatformService}=await import('../apps/server/dist/src/modules/platform/platform.service.js');
const {AuthService}=await import('../apps/server/dist/src/modules/auth/auth.service.js');
const {authConfig}=await import('../apps/server/dist/src/modules/auth/auth.config.js');
const {configureApp}=await import('../apps/server/dist/src/config/configure-app.js');

export async function startAuthFixture(webOrigin='http://127.0.0.1:4318'){
 const keys=await generateKeyPair('RS256'),jwk={...await exportJWK(keys.publicKey),kid:'test-only',alg:'RS256',use:'sig'},codes=new Map();let issuer;
 const provider=createServer(async(req,res)=>{try{
  const u=new URL(req.url,issuer);res.setHeader('content-type','application/json');
  if(u.pathname==='/openid/connect/keys'){res.end(JSON.stringify({keys:[jwk]}));return;}
  if(u.pathname==='/openid/connect/authorize'){const code=randomBytes(32).toString('base64url');codes.set(code,u.searchParams.get('nonce'));const callback=new URL(u.searchParams.get('redirect_uri'));callback.searchParams.set('code',code);callback.searchParams.set('state',u.searchParams.get('state'));res.writeHead(302,{location:callback.href});res.end();return;}
  if(u.pathname==='/api/openid.connect.token'){let raw='';for await(const c of req)raw+=c;const fields=new URLSearchParams(raw),nonce=codes.get(fields.get('code'));codes.delete(fields.get('code'));if(!nonce||fields.get('client_secret')!=='local-test-secret')throw Error('Invalid fixture request');const token=await new SignJWT({nonce,'https://slack.com/team_id':'TDEMO'}).setProtectedHeader({alg:'RS256',kid:'test-only'}).setIssuer(issuer).setAudience('fixture-client').setSubject('UDEMO').setIssuedAt().setExpirationTime('5m').sign(keys.privateKey);res.end(JSON.stringify({access_token:'not-stored',token_type:'Bearer',id_token:token}));return;}
  res.writeHead(404);res.end('{}');
 }catch{res.writeHead(400);res.end('{}');}});
 await new Promise(r=>provider.listen(0,'127.0.0.1',r));issuer=`http://127.0.0.1:${provider.address().port}`;
 const app=await NestFactory.create(AppModule,{logger:false});configureApp(app,()=>{},[webOrigin],true);
 const root=resolve(new URL('..',import.meta.url).pathname.replace(/^\/([A-Za-z]:)/,'$1')),dataDir=await mkdtemp(join(tmpdir(),'qa-auth-ui-'));
 const platform=app.get(PlatformService);
 await platform.start({mode:'oidc-test',dataDir,engineCli:resolve(root,'.local/engine/node_modules/automated-qa-engine/packages/cli/aqa.mjs'),engineManifest:resolve(root,'apps/app/assets/engine-runtime.json'),identities:{users:[{id:'organization-user',token:randomBytes(32).toString('base64url'),active:true}],projects:[{id:'organization-project',name:'Organization project'}],memberships:[{userId:'organization-user',projectId:'organization-project',role:'qa_manager'}]}});
 await app.listen(0,'127.0.0.1');const origin=await app.getUrl(),auth=app.get(AuthService);
 auth.start(authConfig({NODE_ENV:'test',QA_AUTH_MODE:'oidc-test',QA_OIDC_TEST_ISSUER:issuer,QA_OIDC_CLIENT_ID:'fixture-client',QA_OIDC_CLIENT_SECRET:'local-test-secret',QA_OIDC_CALLBACK_URL:`${origin}/api/v1/auth/callback`,QA_OIDC_WEB_ORIGIN:webOrigin,QA_OIDC_ALLOWED_WORKSPACES:'TDEMO',QA_OIDC_BINDINGS_JSON:JSON.stringify([{subject:'UDEMO',workspace:'TDEMO',userId:'organization-user'}])}));platform.registerIdentityResolver(auth.resolveIdentity.bind(auth));
 return {origin,close:async()=>{await app.close();await new Promise(r=>provider.close(r));}};
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){const fixture=await startAuthFixture();process.stdout.write(JSON.stringify({origin:fixture.origin})+'\n');process.stdin.resume();process.stdin.on('end',async()=>{await fixture.close();process.exit(0);});}
