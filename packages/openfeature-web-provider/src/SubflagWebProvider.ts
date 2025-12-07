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
 * Flags are cached in memory and re-fetched when context changes via OpenFeature.setContext().
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
 * // Option 1: Set context during provider registration
 * await OpenFeature.setProviderAndWait(provider, { targetingKey: 'user-123', plan: 'premium' });
 *
 * // Option 2: Or set provider first, then update context later
 * await OpenFeature.setProviderAndWait(provider);
 * await OpenFeature.setContext({ targetingKey: 'user-123', plan: 'premium' });
 *
 * const client = OpenFeature.getClient();
 * const enabled = client.getBooleanValue('my-flag', false);
 *
 * // Update context when user changes (e.g., after login)
 * await OpenFeature.setContext({ targetingKey: 'user-456', plan: 'free' });
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
   * Called automatically by OpenFeature when the provider is set.
   *
   * @param context - The evaluation context from OpenFeature (passed during setProviderAndWait or from global context)
   */
  async initialize(context?: OpenFeatureContext): Promise<void> {
    try {
      this.status = ProviderStatus.NOT_READY;

      // Fetch all flags from the server with context for targeting
      const results = await this.httpClient.evaluateAllFlags(context);

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
   * Handle context changes from OpenFeature.setContext().
   * Re-fetches all flags with the new context.
   *
   * @param _oldContext - The previous evaluation context (unused)
   * @param newContext - The new evaluation context
   */
  async onContextChange(
    _oldContext: OpenFeatureContext,
    newContext: OpenFeatureContext
  ): Promise<void> {
    // Re-fetch all flags with the new context
    const results = await this.httpClient.evaluateAllFlags(newContext);

    // Update the cache with new values
    this.flagCache.clear();
    for (const result of results) {
      this.flagCache.set(result.flagKey, result);
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
    logger: Logger
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

    this.warnIfDeprecated(cached, logger);

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
    logger: Logger
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

    this.warnIfDeprecated(cached, logger);

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
    logger: Logger
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

    this.warnIfDeprecated(cached, logger);

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
    logger: Logger
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

    this.warnIfDeprecated(cached, logger);

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

  /**
   * Log a warning if the flag is deprecated.
   */
  private warnIfDeprecated(result: EvaluationResult, logger: Logger): void {
    if (result.flagStatus === 'DEPRECATED') {
      logger.warn(
        `Flag "${result.flagKey}" is deprecated and scheduled for removal. ` +
        `Please migrate away from this flag.`
      );
    }
  }
}
