import { readFile,writeFile,mkdir } from 'node:fs/promises';
import { resolve,dirname,basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const [bundlePath,releasePath]=process.argv.slice(2);
if(!bundlePath || !releasePath) throw new Error('Pass verified engine contract bundle and release metadata paths');
const bytes=await readFile(bundlePath),bundle=JSON.parse(bytes),release=JSON.parse(await readFile(releasePath));
const sha256=createHash('sha256').update(bytes).digest('hex');
if(release.sha256!==sha256 || release.engineVersion!==bundle.engineVersion || basename(bundlePath)!==release.artifact || bundle.owner!=='automated-qa-engine') throw new Error('Engine bundle integrity mismatch');
await mkdir(resolve(root,'packages/contract/generated'),{recursive:true});
await writeFile(resolve(root,'packages/contract/generated/engine-contract.json'),bytes);
await writeFile(resolve(root,'packages/contract/engine-dependency.json'),JSON.stringify({
 owner:bundle.owner,repository:'https://github.com/doomin03/automated-qa-engine',contractVersion:bundle.contractVersion,
 status:'local-preview',requiredSchemas:bundle.schemas,engineVersion:bundle.engineVersion,
 release:{tag:null,artifact:release.artifact,sha256},runtimeIntegrationEnabled:false,
 usage:'Blueprint schema validation and event replay only; CLI execution remains external.'
},null,2)+'\n');
console.log('Imported public contract artifact '+release.artifact+' sha256='+sha256);

