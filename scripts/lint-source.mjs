import {readdir,readFile} from 'node:fs/promises';
import {resolve,extname} from 'node:path';
import ts from 'typescript';
let count=0,failed=false;
async function walk(dir){for(const item of await readdir(dir,{withFileTypes:true})){if(['node_modules','dist','build','generated','.dart_tool'].includes(item.name))continue;const path=resolve(dir,item.name);if(item.isDirectory())await walk(path);else if(/\.(?:[cm]?js|jsx|tsx?)$/.test(item.name)){const source=await readFile(path,'utf8');const tree=ts.createSourceFile(path,source,ts.ScriptTarget.Latest,true,extname(path)==='.jsx'?ts.ScriptKind.JSX:extname(path)==='.tsx'?ts.ScriptKind.TSX:ts.ScriptKind.TS);for(const diagnostic of tree.parseDiagnostics){failed=true;console.error(`${path}: ${ts.flattenDiagnosticMessageText(diagnostic.messageText,' ')}`);}count++;}}}
for(const directory of ['apps/web/src','apps/server/src','scripts','tests'])await walk(resolve(directory));
console.log(`Source syntax lint: ${count} files, ${failed?'FAIL':'PASS'}. Import boundaries run separately.`);process.exitCode=failed?1:0;
