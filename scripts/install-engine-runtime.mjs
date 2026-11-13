import { readFile, writeFile, mkdir, readdir } from 'node:fs/promises';
import { resolve, dirname, relative, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';

const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const pin=JSON.parse(await readFile(resolve(root,'packages/contract/engine-runtime.json')));
const artifact=resolve(process.argv[2] || '');
const hash=bytes=>createHash('sha256').update(bytes).digest('hex');
if(!process.argv[2] || hash(await readFile(artifact))!==pin.sha256)throw new Error('Engine package SHA-256 mismatch');
const local=resolve(root,'.local/engine');await mkdir(local,{recursive:true});
// Invoke npm through Node, with no shell and no committed local dependency.
const npm=process.env.npm_execpath&&basename(process.env.npm_execpath)==='npm-cli.js'?process.env.npm_execpath:resolve(dirname(process.execPath),'node_modules/npm/bin/npm-cli.js');
const installed=spawnSync(process.execPath,[npm,'install','--prefix',local,'--ignore-scripts','--no-audit','--no-fund',artifact],{stdio:'inherit',windowsHide:true});
if(installed.status!==0)throw new Error('Engine package install failed');
const packageRoot=resolve(local,'node_modules',pin.packageName);
const pkg=JSON.parse(await readFile(resolve(packageRoot,'package.json')));
if(pkg.version!==pin.engineVersion)throw new Error('Installed version mismatch');
const files={};
async function walk(directory){for(const item of await readdir(directory,{withFileTypes:true})){const path=resolve(directory,item.name);if(item.isSymbolicLink())throw new Error('Unexpected package link');if(item.isDirectory()){if(item.name!=='node_modules')await walk(path);}else files[relative(packageRoot,path).replaceAll('\\','/')]=hash(await readFile(path));}}
await walk(packageRoot);
const manifest={...pin,files};
await mkdir(resolve(root,'apps/app/assets'),{recursive:true});
await writeFile(resolve(root,'apps/app/assets/engine-runtime.json'),JSON.stringify(manifest,null,2)+'\n');
await writeFile(resolve(root,'apps/app/assets/engine-contract.json'),await readFile(resolve(root,'packages/contract/generated/engine-contract.json')));
console.log('Verified engine runtime: '+resolve(packageRoot,pin.entrypoint));
