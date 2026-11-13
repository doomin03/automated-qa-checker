import { DatabaseSync, SQLInputValue } from 'node:sqlite';
import { mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { createHash } from 'node:crypto';
import { ConflictException, Injectable, OnModuleDestroy, ServiceUnavailableException } from '@nestjs/common';
import type { LocalIdentities } from './platform.config.js';

export const sha256 = (value: string | Uint8Array): string => createHash('sha256').update(value).digest('hex');
export function canonical(value: unknown): string {
  const sort = (v: any): any => Array.isArray(v) ? v.map(sort) : v !== null && typeof v === 'object' ? Object.fromEntries(Object.keys(v).sort().map(k => [k, sort(v[k])])) : v;
  return JSON.stringify(sort(value));
}
export type Row = Record<string, any>;

@Injectable()
export class PlatformRepository implements OnModuleDestroy {
  private connection?: DatabaseSync;
  private transactionDepth = 0;
  private get db(): DatabaseSync { if (!this.connection) throw new ServiceUnavailableException('Platform is not configured'); return this.connection; }
  start(dataDir: string, identities: LocalIdentities, identityStorage: 'provisioned' | 'managed' = 'provisioned'): void {
    if (!['provisioned', 'managed'].includes(identityStorage)) throw new Error('Unsupported identity storage mode');
    mkdirSync(dataDir, { recursive: true });
    this.connection = new DatabaseSync(join(dataDir, 'platform.sqlite'));
    this.db.exec('PRAGMA foreign_keys=ON; PRAGMA journal_mode=WAL; PRAGMA busy_timeout=5000;');
    this.db.exec('CREATE TABLE IF NOT EXISTS migrations (version INTEGER PRIMARY KEY)');
    if (!this.get('SELECT version FROM migrations WHERE version=1')) this.transaction(() => {
      this.db.exec(`
        CREATE TABLE users(id TEXT PRIMARY KEY,token_hash TEXT NOT NULL UNIQUE,active INTEGER NOT NULL CHECK(active IN (0,1)));
        CREATE TABLE projects(id TEXT PRIMARY KEY,name TEXT NOT NULL);
        CREATE TABLE memberships(user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,project_id TEXT NOT NULL REFERENCES projects(id),role TEXT NOT NULL,PRIMARY KEY(user_id,project_id));
        CREATE TABLE drafts(id TEXT PRIMARY KEY,project_id TEXT NOT NULL REFERENCES projects(id),package_id TEXT NOT NULL,title TEXT NOT NULL,xml TEXT NOT NULL,hash TEXT NOT NULL,dependencies TEXT NOT NULL,author_id TEXT NOT NULL,state TEXT NOT NULL,reviewer_id TEXT,created_at TEXT NOT NULL);
        CREATE TABLE versions(id TEXT PRIMARY KEY,project_id TEXT NOT NULL REFERENCES projects(id),package_id TEXT NOT NULL,version TEXT NOT NULL,draft_id TEXT NOT NULL UNIQUE,title TEXT NOT NULL,xml TEXT NOT NULL,hash TEXT NOT NULL,dependencies TEXT NOT NULL,engine_version TEXT NOT NULL,blueprint_hash TEXT NOT NULL,flow_hash TEXT NOT NULL,node_ids TEXT NOT NULL,created_at TEXT NOT NULL,UNIQUE(project_id,package_id,version));
        CREATE TRIGGER immutable_versions_update BEFORE UPDATE ON versions BEGIN SELECT RAISE(ABORT,'Immutable published version'); END;
        CREATE TRIGGER immutable_versions_delete BEFORE DELETE ON versions BEGIN SELECT RAISE(ABORT,'Immutable published version'); END;
        CREATE TABLE pins(user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,project_id TEXT NOT NULL REFERENCES projects(id),package_id TEXT NOT NULL,version_id TEXT NOT NULL REFERENCES versions(id),hash TEXT NOT NULL,PRIMARY KEY(user_id,project_id,package_id));
        CREATE TABLE idempotency(scope TEXT NOT NULL,key TEXT NOT NULL,hash TEXT NOT NULL,response TEXT NOT NULL,PRIMARY KEY(scope,key));
        CREATE TABLE runs(id TEXT PRIMARY KEY,project_id TEXT NOT NULL REFERENCES projects(id),owner_id TEXT NOT NULL,engine_run_id TEXT NOT NULL,attempt INTEGER NOT NULL,snapshot_hash TEXT NOT NULL,engine_version TEXT NOT NULL,version_id TEXT REFERENCES versions(id),blueprint_json TEXT NOT NULL,flow_hash TEXT NOT NULL,node_ids TEXT NOT NULL,last_sequence INTEGER NOT NULL DEFAULT 0,terminal INTEGER NOT NULL DEFAULT 0,outcome TEXT,result_json TEXT,evidence_status TEXT NOT NULL DEFAULT 'pending',created_at TEXT NOT NULL,UNIQUE(project_id,engine_run_id,attempt));
        CREATE TABLE events(run_id TEXT NOT NULL REFERENCES runs(id),sequence INTEGER NOT NULL,payload TEXT NOT NULL,hash TEXT NOT NULL,PRIMARY KEY(run_id,sequence));
        CREATE TABLE artifacts(id TEXT PRIMARY KEY,run_id TEXT NOT NULL REFERENCES runs(id),name TEXT NOT NULL,hash TEXT NOT NULL,size INTEGER NOT NULL,mime TEXT NOT NULL,uploaded INTEGER NOT NULL DEFAULT 0,UNIQUE(run_id,name));
        CREATE TABLE audit(id INTEGER PRIMARY KEY AUTOINCREMENT,project_id TEXT NOT NULL,actor_id TEXT NOT NULL,action TEXT NOT NULL,resource_id TEXT NOT NULL,created_at TEXT NOT NULL);
        INSERT INTO migrations(version) VALUES(1);
      `);
    });
    if (!this.get('SELECT version FROM migrations WHERE version=10')) this.transaction(() => {
      this.db.exec(`
        CREATE TABLE identity_administration(id INTEGER PRIMARY KEY CHECK(id=1),mode TEXT NOT NULL CHECK(mode IN ('provisioned','managed')));
        CREATE TABLE managed_users(user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,display_name TEXT,revision INTEGER NOT NULL DEFAULT 0);
        CREATE TABLE managed_memberships(user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,project_id TEXT NOT NULL REFERENCES projects(id),revision INTEGER NOT NULL DEFAULT 0,PRIMARY KEY(user_id,project_id));
        INSERT INTO identity_administration VALUES(1,'provisioned');
        INSERT INTO managed_users(user_id) SELECT id FROM users;
        INSERT INTO managed_memberships(user_id,project_id) SELECT user_id,project_id FROM memberships;
        INSERT INTO migrations VALUES(10);
      `);
    });
    try { this.transaction(() => {
      const previous = this.identityStorage;
      if (previous === 'managed') {
        if (identityStorage !== 'managed') throw new Error('Managed identity storage cannot be reconciled from provisioning');
        return;
      }
      if (identityStorage === 'managed') {
        // Existing identity state is authoritative on explicit adoption; only an empty database is seeded.
        if (this.get('SELECT COUNT(*) AS n FROM users')!.n === 0) {
          for (const user of identities.users) this.exec('INSERT INTO users VALUES(?,?,?)', user.id, sha256(user.token), user.active ? 1 : 0);
          for (const project of identities.projects) this.exec('INSERT INTO projects VALUES(?,?)', project.id, project.name);
          for (const member of identities.memberships) this.exec('INSERT INTO memberships VALUES(?,?,?)', member.userId, member.projectId, member.role);
        }
        if (!this.get("SELECT 1 FROM memberships m JOIN users u ON u.id=m.user_id WHERE u.active=1 AND m.role='system_admin' LIMIT 1")) throw new Error('Managed identity storage requires an existing active system administrator');
        this.exec("UPDATE identity_administration SET mode='managed' WHERE id=1");
      } else {
      this.exec('UPDATE users SET active=0');
      this.exec('DELETE FROM memberships');
      for (const user of identities.users) this.exec('INSERT INTO users VALUES(?,?,?) ON CONFLICT(id) DO UPDATE SET token_hash=excluded.token_hash,active=excluded.active', user.id, sha256(user.token), user.active ? 1 : 0);
      for (const project of identities.projects) this.exec('INSERT INTO projects VALUES(?,?) ON CONFLICT(id) DO UPDATE SET name=excluded.name', project.id, project.name);
      for (const member of identities.memberships) this.exec('INSERT INTO memberships VALUES(?,?,?)', member.userId, member.projectId, member.role);
      }
      this.exec('INSERT OR IGNORE INTO managed_users(user_id) SELECT id FROM users');
      this.exec('INSERT OR IGNORE INTO managed_memberships(user_id,project_id) SELECT user_id,project_id FROM memberships');
    }); } catch (error) { this.onModuleDestroy(); throw error; }
  }
  get identityStorage(): 'provisioned' | 'managed' { return this.get('SELECT mode FROM identity_administration WHERE id=1')!.mode; }
  get(sql: string, ...args: SQLInputValue[]): Row | undefined { return this.db.prepare(sql).get(...args); }
  all(sql: string, ...args: SQLInputValue[]): Row[] { return this.db.prepare(sql).all(...args); }
  exec(sql: string, ...args: SQLInputValue[]): void { this.db.prepare(sql).run(...args); }
  transaction<T>(action: () => T): T {
    const depth = this.transactionDepth++;
    const savepoint = `qa_transaction_${depth}`;
    try {
      this.db.exec(depth === 0 ? 'BEGIN IMMEDIATE' : `SAVEPOINT ${savepoint}`);
      try { const result = action(); this.db.exec(depth === 0 ? 'COMMIT' : `RELEASE ${savepoint}`); return result; }
      catch (error) { this.db.exec(depth === 0 ? 'ROLLBACK' : `ROLLBACK TO ${savepoint}; RELEASE ${savepoint}`); throw error; }
    } finally { this.transactionDepth--; }
  }
  audit(project: string, actor: string, action: string, resource = ''): void { this.exec('INSERT INTO audit(project_id,actor_id,action,resource_id,created_at) VALUES(?,?,?,?,?)', project, actor, action, resource, new Date().toISOString()); }
  idempotent<T>(scope: string, key: string, payload: unknown, action: () => T): T {
    if (!/^[A-Za-z0-9_.:-]{1,128}$/.test(key)) throw new ConflictException('A valid Idempotency-Key header is required');
    const hash = sha256(canonical(payload));
    return this.transaction(() => {
      const previous = this.get('SELECT * FROM idempotency WHERE scope=? AND key=?', scope, key);
      if (previous) { if (previous.hash !== hash) throw new ConflictException('Idempotency key payload conflict'); return JSON.parse(previous.response); }
      const result = action(); this.exec('INSERT INTO idempotency VALUES(?,?,?,?)', scope, key, hash, JSON.stringify(result)); return result;
    });
  }
  onModuleDestroy(): void { this.connection?.close(); this.connection = undefined; }
}
