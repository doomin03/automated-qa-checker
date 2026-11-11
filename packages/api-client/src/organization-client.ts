import { AuthApi, type DesktopExchangeInput } from './generated/index.js';
import { responseOperations } from './generated/contract-schema.js';
import { apiOrigin, ApiFailure, TransportFailure } from './health-client.js';
import { ContractFailure } from './schema-validation.js';
import { JsonTransport, type ClientOptions, type RequestOptions } from './platform-client.js';

export class OrganizationClient {
  private readonly api: AuthApi;
  private readonly transport: JsonTransport;
  private readonly origin: string;
  constructor(origin: string, options: ClientOptions & { token?: string } = {}) {
    this.origin = apiOrigin(origin);
    this.transport = new JsonTransport(origin, options.token ?? '', { session: !options.token, ...options });
    this.api = new AuthApi(this.transport.configuration);
  }
  loginUrl(kind: 'web' | 'desktop' = 'web', redirectUri?: string, challenge?: string): string {
    const operation = responseOperations.find(op => op.operationId === 'startOrganizationLogin');
    if (!operation) throw new ContractFailure('Organization login operation is absent');
    const url = new URL(operation.path, this.origin); url.searchParams.set('kind', kind);
    if (redirectUri) url.searchParams.set('redirectUri', redirectUri);
    if (challenge) url.searchParams.set('challenge', challenge);
    return url.toString();
  }
  private async call<T>(action: () => Promise<T>): Promise<T> {
    try { return await action(); } catch (error) {
      if (error instanceof ApiFailure || error instanceof TransportFailure || error instanceof ContractFailure) throw error;
      if (error instanceof Error && (error.cause instanceof ApiFailure || error.cause instanceof TransportFailure || error.cause instanceof ContractFailure)) throw error.cause;
      throw new ContractFailure('Organization response could not be decoded', { cause: error });
    }
  }
  getSession(options: RequestOptions = {}) { return this.call(() => this.api.getOrganizationSession(options)); }
  logout(options: RequestOptions = {}) { return this.call(() => this.api.logoutOrganizationSession(options)); }
  desktopExchange(input: DesktopExchangeInput, options: RequestOptions = {}) { return this.call(() => this.api.exchangeDesktopLogin({ desktopExchangeInput: input }, options)); }
  close(): void { this.transport.close(); }
}
