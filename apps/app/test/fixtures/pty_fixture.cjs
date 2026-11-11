const fs = require('node:fs');
const {spawn} = require('node:child_process');
const [mode, receipt, ...args] = process.argv.slice(2);
fs.writeFileSync(receipt, JSON.stringify({pid:process.pid,cwd:process.cwd(),args,tty:!!process.stdin.isTTY,columns:process.stdout.columns,rows:process.stdout.rows}));
if (mode === 'echo') {
  process.stdin.setRawMode(true);
  process.stdout.write('준비 READY\r\n');
  process.stdout.on('resize', () => process.stdout.write(`SIZE:${process.stdout.columns}x${process.stdout.rows}\r\n`));
  process.stdin.on('data', b => {
    process.stdout.write(`INPUT:${b.toString('hex')}\r\n`);
    if (b.includes(4)) process.exit(0);
  });
} else if (mode === 'tree') {
  const child = spawn(process.execPath, ['-e','setInterval(()=>{},1000)'], {stdio:'inherit'});
  fs.writeFileSync(receipt+'.child', String(child.pid));
  setTimeout(()=>process.exit(0), 500);
} else if (mode === 'flood') {
  process.stdout.write('X'.repeat(1024*1024));
  process.stdout.write('END\r\n');
  setInterval(()=>{},1000);
}
