import {spawn} from 'node:child_process';
import {existsSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=resolve(dirname(fileURLToPath(import.meta.url)),'..');
const sdk=process.env.FLUTTER_SDK || resolve(root,'../.tools/flutter-3.47.5');
const dart=resolve(sdk,'bin/cache/dart-sdk/bin',process.platform==='win32'?'dart.exe':'dart');
const snapshot=resolve(sdk,'bin/cache/flutter_tools.snapshot');
if(!existsSync(dart)||!existsSync(snapshot)){console.error('Flutter 3.47.5 SDK가 없습니다. FLUTTER_SDK에 검증된 SDK 디렉터리를 지정하세요.');process.exit(1);}
const child=spawn(dart,[snapshot,...process.argv.slice(2)],{cwd:resolve(root,'apps/app'),env:{...process.env,FLUTTER_ROOT:sdk},stdio:'inherit',windowsHide:true});
child.on('error',error=>{console.error(error.message);process.exitCode=1;});
child.on('exit',code=>{process.exitCode=code??1;});
process.on('SIGINT',()=>child.kill('SIGINT'));
process.on('SIGTERM',()=>child.kill('SIGTERM'));
