import type {
  EvaluationContext as OpenFeatureContext,
  JsonValue,
  Logger,
  Provider,
  ResolutionDetails,
} from '@openfeature/web-sdk';
import { ErrorCode, ProviderStatus } from '@openfeature/web-sdk';
import { SubflagHttpClient } from './http-client';
import type { SubflagProviderConfig, EvaluationResult } from './types';

/**
 * OpenFeature provider for Subflag feature flags (Web/Browser).
 *
 * This provider pre-fetches all flags during initialization and serves them synchronously.
 * Flags are cached in memory and can be refreshed by calling initialize() again.
 *
 * @example
 * ```typescript
 * import { OpenFeature } from '@openfeature/web-sdk';
 * import { SubflagWebProvider } from '@subflag/openfeature-web-provider';
 *
 * const provider = new SubflagWebProvider({
 *   apiUrl: 'http://localhost:8080',
 *   apiKey: 'sdk-prod-...'
 * });
 *
 * await OpenFeature.setProviderAndWait(provider);
 *
 * const client = OpenFeature.getClient();
 * const enabled = await client.getBooleanValue('my-flag', false);
 * ```
 */
export class SubflagWebProvider implements Provider {
  public readonly metadata = {
    name: 'Subflag Web Provider',
  };

  public status: ProviderStatus = ProviderStatus.NOT_READY;

  private readonly httpClient: SubflagHttpClient;
  private flagCache: Map<string, EvaluationResult> = new Map();

  constructor(config: SubflagProviderConfig) {
    this.httpClient = new SubflagHttpClient(config);
  }

  /**
   * Initialize the provider by pre-fetching all flags.
   * This is called automatically by OpenFeature when the provider is set.
   */
  async initialize(): Promise<void> {
    try {
      this.status = ProviderStatus.NOT_READY;

      // Fetch all flags from the server
      const results = await this.httpClient.evaluateAllFlags();

      // Cache all flags by key
      this.flagCache.clear();
      for (const result of results) {
        this.flagCache.set(result.flagKey, result);
      }

      this.status = ProviderStatus.READY;
    } catch (error) {
      this.status = ProviderStatus.ERROR;
      throw error;
    }
  }

  /**
   * Clean up resources when provider is shut down.
   */
  async onClose(): Promise<void> {
    this.flagCache.clear();
    this.status = ProviderStatus.NOT_READY;
  }

  /**
   * Resolve a boolean flag value from cache.
   */
  resolveBooleanEvaluation(
    flagKey: string,
    defaultValue: boolean,
    _context: OpenFeatureContext,
    _logger: Logger
  ): ResolutionDetails<boolean> {
    const cached = this.flagCache.get(flagKey);

    if (!cached) {
      return {
        value: defaultValue,
        reason: 'DEFAULT',
        errorCode: ErrorCode.FLAG_NOT_FOUND,
        errorMessage: `Flag '${flagKey}' not found in cache`,
      };
    }

    if (typeof cached.value !== 'boolean') {
      return {
        value: defaultValue,
        reason: 'ERROR',
        errorCode: ErrorCode.TYPE_MISMATCH,
        errorMessage: `Expected boolean but got ${typeof cached.value}`,
      };
    }

    return {
      value: cached.value,
      variant: cached.variant,
      reason: cached.reason,
    };
  }

  /**
   * Resolve a string flag value from cache.
   */
  resolveStringEvaluation(
    flagKey: string,
    defaultValue: string,
    _context: OpenFeatureContext,
    _logger: Logger
  ): ResolutionDetails<string> {
    const cached = this.flagCache.get(flagKey);

    if (!cached) {
      return {
        value: defaultValue,
        reason: 'DEFAULT',
        errorCode: ErrorCode.FLAG_NOT_FOUND,
        errorMessage: `Flag '${flagKey}' not found in cache`,
      };
    }

    if (typeof cached.value !== 'string') {
      return {
        value: defaultValue,
        reason: 'ERROR',
        errorCode: ErrorCode.TYPE_MISMATCH,
        errorMessage: `Expected string but got ${typeof cached.value}`,
      };
    }

    return {
      value: cached.value,
      variant: cached.variant,
      reason: cached.reason,
    };
  }

  /**
   * Resolve a number flag value from cache.
   */
  resolveNumberEvaluation(
    flagKey: string,
    defaultValue: number,
    _context: OpenFeatureContext,
    _logger: Logger
  ): ResolutionDetails<number> {
    const cached = this.flagCache.get(flagKey);

    if (!cached) {
      return {
        value: defaultValue,
        reason: 'DEFAULT',
        errorCode: ErrorCode.FLAG_NOT_FOUND,
        errorMessage: `Flag '${flagKey}' not found in cache`,
      };
    }

    if (typeof cached.value !== 'number') {
      return {
        value: defaultValue,
        reason: 'ERROR',
        errorCode: ErrorCode.TYPE_MISMATCH,
        errorMessage: `Expected number but got ${typeof cached.value}`,
      };
    }

    return {
      value: cached.value,
      variant: cached.variant,
      reason: cached.reason,
    };
  }

  /**
   * Resolve an object flag value from cache.
   */
  resolveObjectEvaluation<T extends JsonValue>(
    flagKey: string,
    defaultValue: T,
    _context: OpenFeatureContext,
    _logger: Logger
  ): ResolutionDetails<T> {
    const cached = this.flagCache.get(flagKey);

    if (!cached) {
      return {
        value: defaultValue,
        reason: 'DEFAULT',
        errorCode: ErrorCode.FLAG_NOT_FOUND,
        errorMessage: `Flag '${flagKey}' not found in cache`,
      };
    }

    if (typeof cached.value !== 'object' || cached.value === null) {
      return {
        value: defaultValue,
        reason: 'ERROR',
        errorCode: ErrorCode.TYPE_MISMATCH,
        errorMessage: `Expected object but got ${typeof cached.value}`,
      };
    }

    return {
      value: cached.value as T,
      variant: cached.variant,
      reason: cached.reason,
    };
  }
}
