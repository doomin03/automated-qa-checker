import { Injectable, BadRequestException, ServiceUnavailableException } from '@nestjs/common';
import { Ajv, type ValidateFunction } from 'ajv';
import { readFile, realpath, mkdtemp, writeFile, rm, mkdir } from 'node:fs/promises';
import { dirname, resolve, relative, isAbsolute, join } from 'node:path';
import { tmpdir } from 'node:os';
import { spawn } from 'node:child_process';
import { sha256 } from './platform.repository.js';

export function parseBounded(text: string, maxBytes = 1048576): any {
  if (Buffer.byteLength(text) > maxBytes) throw new BadRequestException('Engine JSON exceeds byte limit');
  let value: any; try { value = JSON.parse(text); } catch { throw new BadRequestException('Invalid Engine JSON'); }
  let count = 0;
  function check(item: any, depth: number): void {
    if (++count > 50000 || depth > 40) throw new BadRequestException('Engine JSON exceeds complexity limit');
    if (item && typeof item === 'object') for (const [key, child] of Object.entries(item)) {
      if (['__proto__', 'constructor', 'prototype'].includes(key)) throw new BadRequestException('Unsafe Engine JSON key');
      check(child, depth + 1);
    }
  }
  check(value, 0); return value;
}

@Injectable()
export class EngineContractService {
  private cli?: string;
  private packageRoot = '';
  private pinnedFiles: Record<string, string> = {};
  private validators = new Map<string, ValidateFunction>();
  version = '';
  contractVersion = '';
  contractSha256 = '';
  archiveSha256: string | null = null;
  async start(cli: string, manifestPath: string): Promise<void> {
    const manifest = JSON.parse(await readFile(manifestPath, 'utf8'));
    const packageRoot = await realpath(resolve(dirname(cli), '../..'));
    if (!manifest.files || typeof manifest.files !== 'object') throw new Error('Engine manifest must contain exact file hashes');
    if (!manifest.files[manifest.entrypoint] || !manifest.files['contracts/schemas/qa.schema.json']) throw new Error('Engine manifest omits required entrypoints');
    this.packageRoot = packageRoot; this.pinnedFiles = manifest.files;
    await this.verifyIntegrity();
    if (await realpath(cli) !== await realpath(join(packageRoot, manifest.entrypoint))) throw new Error('Unregistered Engine CLI entrypoint');
    this.cli = cli;
    const version = await this.command(['--version', '--json']);
    if (version.engineVersion !== manifest.engineVersion) throw new Error('Engine version mismatch');
    this.version = version.engineVersion;
    const contractBytes = await readFile(join(packageRoot, `contracts/releases/qa-contract-${this.version}.json`));
    this.contractSha256 = sha256(contractBytes);
    this.contractVersion = JSON.parse(contractBytes.toString('utf8')).contractVersion;
    const schema = JSON.parse(await readFile(join(packageRoot, 'contracts/schemas/qa.schema.json'), 'utf8'));
    const ajv = new Ajv({ allErrors: true, strict: false, ownProperties: true }); ajv.addSchema(schema);
    for (const name of ['event', 'result', 'checkReport', 'plan', 'blueprint']) {
      const validator = ajv.getSchema(`${schema.$id}#/definitions/${name}`);
      if (!validator) throw new Error(`Engine contract missing ${name}`);
      this.validators.set(name, validator);
    }
    this.archiveSha256 = typeof manifest.sha256 === 'string' && /^[a-f0-9]{64}$/.test(manifest.sha256) ? manifest.sha256 : null;
  }
  private async verifyIntegrity(): Promise<void> {
    for (const [file, expected] of Object.entries(this.pinnedFiles)) {
      const path = await realpath(resolve(this.packageRoot, file)); const rel = relative(this.packageRoot, path);
      if (rel.startsWith('..') || isAbsolute(rel) || sha256(await readFile(path)) !== expected) throw new ServiceUnavailableException('Engine release integrity mismatch');
    }
  }
  validate(text: string, name: string): any {
    const validate = this.validators.get(name);
    if (!validate) throw new ServiceUnavailableException('Engine contract is not configured');
    const value = parseBounded(text);
    if (!validate(value)) throw new BadRequestException('Public Engine schema validation failed');
    return value;
  }
  async plan(xml: string, format: 'xml' | 'json' = 'xml', resources: Array<{ name: string; bytes: Uint8Array; sha256: string }> = []): Promise<any> {
    await this.verifyIntegrity();
    if (Buffer.byteLength(xml) > 1048576) throw new BadRequestException('XML exceeds byte limit');
    if (format === 'json') this.validate(xml, 'blueprint');
    const temp = await mkdtemp(join(tmpdir(), 'qa-registry-'));
    try {
      const names = new Set<string>(); let total = 0;
      for (const resource of resources) {
        const segments = resource.name.split('/'), normalized = resource.name.toLowerCase();
        if (!segments.length || segments.some(segment => !/^[A-Za-z0-9_-][A-Za-z0-9_.-]{0,127}$/.test(segment) || segment.includes('..') || /^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)/i.test(segment)) || names.has(normalized) || /^scenario\.(xml|json)$/i.test(resource.name)) throw new BadRequestException('Unsafe or duplicate resource path');
        names.add(normalized); total += resource.bytes.length;
        if (resource.bytes.length > 10485760 || total > 67108864 || sha256(resource.bytes) !== resource.sha256) throw new BadRequestException('Resource integrity or quota mismatch');
        const path = resolve(temp, ...segments); if (!relative(temp, path) || relative(temp, path).startsWith('..') || isAbsolute(relative(temp, path))) throw new BadRequestException('Resource escapes document root');
        await mkdir(dirname(path), { recursive: true }); await writeFile(path, resource.bytes, { flag: 'wx' });
      }
      const file = join(temp, `scenario.${format}`); await writeFile(file, xml);
      await this.command(['validate', file, '--document-root', temp, '--json']);
      const plan = await this.command(['plan', file, '--document-root', temp, '--json']);
      return this.validate(JSON.stringify(plan), 'plan');
    } finally {
      const resolved = resolve(temp);
      if (dirname(resolved) !== resolve(tmpdir()) || !resolved.split(/[\\/]/).at(-1)!.startsWith('qa-registry-')) throw new Error('Unsafe temporary path');
      await rm(resolved, { recursive: true, force: true, maxRetries: 3, retryDelay: 100 });
    }
  }
  private command(args: string[]): Promise<any> {
    if (!this.cli) throw new ServiceUnavailableException('Engine CLI is not configured');
    return new Promise((done, reject) => {
      const child = spawn(process.execPath, [this.cli!, ...args], { shell: false, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe'] });
      let output = ''; let bytes = 0; let errorBytes = 0; let settled = false; let failure: Error | undefined; let killTimer: NodeJS.Timeout | undefined;
      const finish = (error?: Error, value?: any) => { if (settled) return; settled = true; clearTimeout(timer); clearTimeout(killTimer); error ? reject(error) : done(value); };
      const stop = (error: Error) => { if (failure) return; failure = error; child.kill(); killTimer = setTimeout(() => finish(error), 5000); };
      const timer = setTimeout(() => stop(new ServiceUnavailableException('Engine validation timed out')), 15000);
      child.stdout.setEncoding('utf8');
      child.stdout.on('data', data => { bytes += Buffer.byteLength(data); if (bytes > 2097152) stop(new BadRequestException('Engine validation output exceeded limit')); else output += data; });
      child.stderr.on('data', data => { errorBytes += data.length; if (errorBytes > 2097152) stop(new BadRequestException('Engine diagnostics exceeded limit')); });
      child.on('error', () => finish(new ServiceUnavailableException('Engine CLI could not start')));
      child.on('close', code => { if (failure) finish(failure); else if (code !== 0) finish(new BadRequestException('Engine rejected the document')); else { try { finish(undefined, parseBounded(output.trim(), 2097152)); } catch { finish(new BadRequestException('Invalid Engine CLI response')); } } });
    });
  }
}
