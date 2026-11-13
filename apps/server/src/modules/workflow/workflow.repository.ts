import { Injectable } from '@nestjs/common';
import { PlatformRepository } from '../platform/platform.repository.js';

@Injectable()
export class WorkflowRepository {
  constructor(readonly platform: PlatformRepository) {}
  start(): void {
    const db = this.platform;
    if (db.get('SELECT version FROM migrations WHERE version=4')) return;
    db.transaction(() => {
      db.exec('CREATE TABLE work_items(run_id TEXT PRIMARY KEY REFERENCES runs(id),status TEXT NOT NULL,assignee_id TEXT REFERENCES users(id),revision INTEGER NOT NULL,updated_at TEXT NOT NULL)');
      db.exec('CREATE TABLE run_baselines(run_id TEXT PRIMARY KEY REFERENCES runs(id),baseline_id TEXT NOT NULL REFERENCES runs(id),selected_by TEXT NOT NULL,selected_at TEXT NOT NULL)');
      db.exec('CREATE TABLE notification_outbox(id TEXT PRIMARY KEY,run_id TEXT NOT NULL REFERENCES runs(id),project_id TEXT NOT NULL,actor_id TEXT NOT NULL,payload TEXT NOT NULL,payload_hash TEXT NOT NULL,state TEXT NOT NULL,attempts INTEGER NOT NULL,next_at INTEGER NOT NULL,lease_until INTEGER NOT NULL,last_error TEXT,created_at TEXT NOT NULL,UNIQUE(run_id,payload_hash))');
      db.exec('INSERT INTO migrations VALUES(4)');
    });
  }
}
