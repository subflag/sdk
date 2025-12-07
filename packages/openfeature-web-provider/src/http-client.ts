import type { EvaluationContext as OpenFeatureContext } from '@openfeature/web-sdk';
import type { EvaluationContext, EvaluationResult, SubflagProviderConfig } from './types';

/**
 * Convert OpenFeature context to Subflag API context format.
 * OpenFeature context doesn't have a "kind" field, so we add it with a default value.
 */
function toSubflagContext(openFeatureContext: OpenFeatureContext): EvaluationContext {
  return {
    targetingKey: openFeatureContext.targetingKey ?? null,
    kind: 'user', // OpenFeature doesn't have "kind", default to "user"
    attributes: Object.keys(openFeatureContext).length > 0 ? openFeatureContext : null,
  };
}

/**
 * HTTP client for communicating with the Subflag API.
 */
export class SubflagHttpClient {
  private readonly apiUrl: string;
  private readonly apiKey: string;
  private readonly timeout: number;

  constructor(config: SubflagProviderConfig) {
    this.apiUrl = config.apiUrl.replace(/\/$/, ''); // Remove trailing slash
    this.apiKey = config.apiKey;
    this.timeout = config.timeout ?? 5000;
  }

  /**
   * Evaluate a single flag.
   */
  async evaluateFlag(
    flagKey: string,
    context?: EvaluationContext
  ): Promise<EvaluationResult> {
    const url = `${this.apiUrl}/sdk/evaluate/${encodeURIComponent(flagKey)}`;

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Subflag-API-Key': this.apiKey,
        },
        body: context ? JSON.stringify(context) : undefined,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({})) as SubflagApiError;
        throw new SubflagApiError(
          response.status,
          errorData.error || `HTTP ${response.status}`,
          errorData.message
        );
      }

      return await response.json() as EvaluationResult;
    } catch (error) {
      if (error instanceof SubflagApiError) {
        throw error;
      }

      if (error instanceof Error && error.name === 'AbortError') {
        throw new SubflagApiError(0, 'Request timeout', `Request exceeded ${this.timeout}ms`);
      }

      throw new SubflagApiError(
        0,
        'Network error',
        error instanceof Error ? error.message : 'Unknown error'
      );
    }
  }

  /**
   * Evaluate all flags in the environment (bulk evaluation).
   */
  async evaluateAllFlags(context?: OpenFeatureContext): Promise<EvaluationResult[]> {
    const url = `${this.apiUrl}/sdk/evaluate-all`;

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.timeout);

      const subflagContext = context ? toSubflagContext(context) : undefined;

      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Subflag-API-Key': this.apiKey,
        },
        body: subflagContext ? JSON.stringify(subflagContext) : undefined,
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({})) as SubflagApiError;
        throw new SubflagApiError(
          response.status,
          errorData.error || `HTTP ${response.status}`,
          errorData.message
        );
      }

      return await response.json() as EvaluationResult[];
    } catch (error) {
      if (error instanceof SubflagApiError) {
        throw error;
      }

      if (error instanceof Error && error.name === 'AbortError') {
        throw new SubflagApiError(0, 'Request timeout', `Request exceeded ${this.timeout}ms`);
      }

      throw new SubflagApiError(
        0,
        'Network error',
        error instanceof Error ? error.message : 'Unknown error'
      );
    }
  }
}

/**
 * Custom error class for Subflag API errors.
 */
export class SubflagApiError extends Error {
  constructor(
    public readonly statusCode: number,
    public readonly error: string,
    public readonly details?: string
  ) {
    super(`${error}${details ? `: ${details}` : ''}`);
    this.name = 'SubflagApiError';
  }
}
