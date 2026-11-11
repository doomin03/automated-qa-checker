import { pathToFileURL } from 'node:url';
import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { writeFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/config/configure-app.js';
import { createOpenApi, sortedJson } from '../src/config/openapi.js';

export async function exportOpenApi(destination: string): Promise<void> {
  const app = await NestFactory.create(AppModule, { logger: false });
  try {
    configureApp(app, () => {});
    const document = createOpenApi(app);
    if (app.getHttpServer().listening) throw new Error('Offline export must not open a network listener');
    await mkdir(dirname(destination), { recursive: true });
    await writeFile(destination, sortedJson(document));
  } finally { await app.close(); }
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  if (!process.argv[2]) throw new Error('Usage: export-openapi <output.json>');
  exportOpenApi(resolve(process.argv[2])).catch(error => { console.error(error.message); process.exitCode = 1; });
}
