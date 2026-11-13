import '../../../apps/server/node_modules/reflect-metadata/Reflect.js';
import { NestFactory } from '../../../apps/server/node_modules/@nestjs/core/index.js';
import { FixtureModule } from '../../../apps/server/dist/test/fixtures/fixture.module.js';
import { configureApp } from '../../../apps/server/dist/src/config/configure-app.js';
import { createOpenApi, sortedJson } from '../../../apps/server/dist/src/config/openapi.js';
import { writeFile } from 'node:fs/promises';
const app = await NestFactory.create(FixtureModule,{logger:false}); configureApp(app,()=>{});
const document=createOpenApi(app);
document.paths=Object.fromEntries(Object.entries(document.paths).filter(([path])=>path.includes('__fixture')||path.endsWith('/health')));
const keep=new Set(['ApiErrorResponse','ApiErrorDetail']);
function refs(value){if(!value||typeof value!=='object')return;if(value.$ref?.startsWith('#/components/schemas/')){const name=value.$ref.split('/').at(-1);if(!keep.has(name)){keep.add(name);refs(document.components.schemas[name]);}}for(const child of Object.values(value))refs(child);}
refs(document.paths);document.components.schemas=Object.fromEntries(Object.entries(document.components.schemas).filter(([name])=>keep.has(name)));
await writeFile(process.argv[2],sortedJson(document));
if(process.argv.includes('--export-only')){await app.close();}else{await app.listen(0,'127.0.0.1');console.log(JSON.stringify({origin:await app.getUrl()}));for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>app.close().then(()=>process.exit(0)));}
