import { Configuration, HealthApi, ResponseError, ApiErrorResponseFromJSON, type ApiErrorResponse, type GetHealthRequest, type HealthResponse } from './generated/index.js';
import { ContractFailure, validateModel } from './schema-validation.js';

export class ApiFailure extends Error {
  readonly kind = 'api';
  constructor(readonly status: number, readonly body: ApiErrorResponse) { super(body.message); }
}
export class TransportFailure extends Error {
  readonly kind = 'transport';
  constructor(readonly reason: 'timeout' | 'connection' | 'cancelled', cause: unknown) { super(reason === 'timeout' ? 'API request timed out' : reason === 'cancelled' ? 'API request cancelled' : 'API connection failed', { cause }); }
}

export function apiOrigin(value: string): string {
  const url = new URL(value);
  if (!['http:', 'https:'].includes(url.protocol) || url.username || url.password || url.pathname !== '/' || url.search || url.hash) throw new TypeError('API base URL must be an HTTP(S) origin without a path, query or credentials');
  return url.origin;
}

export class HealthClient {
  private readonly api: HealthApi;
  constructor(origin: string, options: { timeoutMs?: number; fetch?: typeof fetch } = {}) {
    const timeoutMs = options.timeoutMs ?? 10000;
    if (!Number.isFinite(timeoutMs) || timeoutMs <= 0) throw new TypeError('timeoutMs must be positive');
    const transport = options.fetch ?? globalThis.fetch;
    this.api = new HealthApi(new Configuration({ basePath: apiOrigin(origin), fetchApi: async (url, init) => {
      const abort = new AbortController();
      const timer = setTimeout(() => abort.abort(), timeoutMs);
      try {
        const response = await transport(url, { ...init, signal: init?.signal ? AbortSignal.any([abort.signal, init.signal]) : abort.signal });
        // Consume within the same timeout so a stalled response body cannot hang.
        const body = await response.text();
        return new Response(body, { status: response.status, statusText: response.statusText, headers: response.headers });
      } catch (error) { throw new TransportFailure(init?.signal?.aborted ? 'cancelled' : abort.signal.aborted ? 'timeout' : 'connection', error); }
      finally { clearTimeout(timer); }
    } }));
  }
  async getHealth(request: GetHealthRequest = {}, options: { signal?: AbortSignal } = {}): Promise<HealthResponse> {
    try {
      const response = await this.api.getHealthRaw(request, options);
      const raw: unknown = await response.raw.clone().json(); validateModel('HealthResponse', raw);
      return await response.value();
    } catch (error) {
      if (error instanceof ResponseError) {
        let raw: unknown;
        try { raw = await error.response.json(); } catch { throw new ContractFailure('API error was not JSON'); }
        validateModel('ApiErrorResponse', raw);
        throw new ApiFailure(error.response.status, ApiErrorResponseFromJSON(raw));
      }
      if (error instanceof ContractFailure || error instanceof TransportFailure) throw error;
      // OpenAPI fetch runtime wraps fetch failures and preserves their cause.
      if (error instanceof Error && error.cause instanceof TransportFailure) throw error.cause;
      throw new ContractFailure('API response could not be decoded', { cause: error });
    }
  }
}
