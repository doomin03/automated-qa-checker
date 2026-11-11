import { Injectable, UnauthorizedException, ServiceUnavailableException } from '@nestjs/common';
import { PlatformRepository, sha256 } from '../platform/platform.repository.js';

@Injectable()
export class AuthRepository {
  constructor(readonly platform: PlatformRepository) {}
  start(): void {
    if (this.platform.get('SELECT version FROM migrations WHERE version=3')) return;
    this.platform.transaction(() => {
      this.platform.exec('CREATE TABLE oidc_states(state_hash TEXT PRIMARY KEY,nonce TEXT NOT NULL,browser_hash TEXT NOT NULL,expires INTEGER NOT NULL,kind TEXT NOT NULL,redirect_uri TEXT,challenge TEXT,consumed INTEGER NOT NULL DEFAULT 0)');
      this.platform.exec('CREATE TABLE auth_sessions(token_hash TEXT PRIMARY KEY,user_id TEXT NOT NULL REFERENCES users(id),expires INTEGER NOT NULL,kind TEXT NOT NULL)');
      this.platform.exec('CREATE TABLE desktop_codes(code_hash TEXT PRIMARY KEY,user_id TEXT NOT NULL REFERENCES users(id),challenge TEXT NOT NULL,redirect_uri TEXT NOT NULL,expires INTEGER NOT NULL,consumed INTEGER NOT NULL DEFAULT 0)');
      this.platform.exec('INSERT INTO migrations(version) VALUES(3)');
    });
  }
  state(state: string, nonce: string, browser: string, kind: string, redirect: string | null, challenge: string | null): void {
    this.platform.exec('DELETE FROM oidc_states WHERE expires<?', Date.now());
    if(this.platform.get('SELECT COUNT(*) AS count FROM oidc_states')!.count>=10000)throw new ServiceUnavailableException('Authentication capacity is busy');
    this.platform.exec('INSERT INTO oidc_states VALUES(?,?,?,?,?,?,?,0)', sha256(state), nonce, sha256(browser), Date.now() + 5 * 60000, kind, redirect, challenge);
  }
  consumeState(state: string, browser: string): Record<string, any> {
    return this.platform.transaction(() => {
      const row = this.platform.get('SELECT * FROM oidc_states WHERE state_hash=? AND browser_hash=? AND consumed=0 AND expires>?', sha256(state), sha256(browser), Date.now());
      if (!row) throw new UnauthorizedException('OIDC transaction is invalid or expired');
      this.platform.exec('UPDATE oidc_states SET consumed=1 WHERE state_hash=?', sha256(state)); return row;
    });
  }
  session(token: string, user: string, kind: 'web' | 'desktop'): number {
    const expires = Date.now() + 8 * 3600000;
    this.platform.exec('DELETE FROM auth_sessions WHERE expires<?', Date.now());
    this.platform.exec('INSERT INTO auth_sessions VALUES(?,?,?,?)', sha256(token), user, expires, kind); return expires;
  }
  lookup(token: string, kind: string): string | undefined {
    return this.platform.get('SELECT s.user_id FROM auth_sessions s JOIN users u ON u.id=s.user_id WHERE s.token_hash=? AND s.kind=? AND s.expires>? AND u.active=1', sha256(token), kind, Date.now())?.user_id;
  }
  revoke(token: string): void { this.platform.exec('DELETE FROM auth_sessions WHERE token_hash=?', sha256(token)); }
  desktop(code: string, user: string, challenge: string, redirect: string): void {
    this.platform.exec('DELETE FROM desktop_codes WHERE expires<?', Date.now());
    this.platform.exec('INSERT INTO desktop_codes VALUES(?,?,?,?,?,0)', sha256(code), user, challenge, redirect, Date.now() + 60000);
  }
  exchange(code: string, challenge: string, redirect: string): string {
    return this.platform.transaction(() => {
      const row = this.platform.get('SELECT d.user_id FROM desktop_codes d JOIN users u ON u.id=d.user_id WHERE d.code_hash=? AND d.challenge=? AND d.redirect_uri=? AND d.expires>? AND d.consumed=0 AND u.active=1', sha256(code), challenge, redirect, Date.now());
      if (!row) throw new UnauthorizedException('Desktop code is invalid or expired');
      this.platform.exec('UPDATE desktop_codes SET consumed=1 WHERE code_hash=?', sha256(code)); return row.user_id;
    });
  }
}
