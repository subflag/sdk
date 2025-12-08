import type {
  EvaluationContext as OpenFeatureContext,
  JsonValue,
  Logger,
  Provider,
  ResolutionDetails,
} from '@openfeature/server-sdk';
import { ErrorCode } from '@openfeature/server-sdk';
import { SubflagHttpClient, SubflagApiError } from './http-client';
import type { SubflagProviderConfig, EvaluationResult, CacheConfig, EvaluationContext } from './types';

const DEFAULT_CACHE_TTL_SECONDS = 60;

/**
 * OpenFeature provider for Subflag feature flags (Node.js/Server).
 *
 * @example
 * ```typescript
 * import { OpenFeature } from '@openfeature/server-sdk';
 * import { SubflagNodeProvider, InMemoryCache } from '@subflag/openfeature-node-provider';
 *
 * // Without caching (default)
 * const provider = new SubflagNodeProvider({
 *   apiUrl: 'http://localhost:8080',
 *   apiKey: 'sdk-prod-...'
 * });
 *
 * // With in-memory caching
 * const cachedProvider = new SubflagNodeProvider({
 *   apiUrl: 'http://localhost:8080',
 *   apiKey: 'sdk-prod-...',
 *   cache: {
 *     cache: new InMemoryCache(),
 *     ttlSeconds: 30,
 *   }
 * });
 *
 * await OpenFeature.setProviderAndWait(provider);
 *
 * const client = OpenFeature.getClient();
 * const enabled = await client.getBooleanValue('my-flag', false);
 * ```
 */
export class SubflagNodeProvider implements Provider {
  public readonly metadata = {
    name: 'Subflag Node Provider',
  };

  private readonly httpClient: SubflagHttpClient;
  private readonly cacheConfig?: CacheConfig;

  constructor(config: SubflagProviderConfig) {
    this.httpClient = new SubflagHttpClient(config);
    this.cacheConfig = config.cache;
  }

  /**
   * Prefetch all flags for a context and cache them.
   *
   * This fetches all flags in a single API call and populates the cache,
   * so subsequent flag evaluations can be served from cache without API calls.
   *
   * @param context - Optional evaluation context for targeting
   * @returns Array of all evaluation results
   * @throws Error if caching is not configured
   *
   * @example
   * ```typescript
   * const provider = new SubflagNodeProvider({
   *   apiUrl: 'http://localhost:8080',
   *   apiKey: 'sdk-prod-...',
   *   cache: { cache: new InMemoryCache(), ttlSeconds: 30 },
   * });
   *
   * // Prefetch all flags for a user
   * await provider.prefetchFlags({ targetingKey: 'user-123' });
   *
   * // Subsequent evaluations use cached values
   * const client = OpenFeature.getClient();
   * await client.getBooleanValue('feature-a', false); // No API call
   * await client.getBooleanValue('feature-b', false); // No API call
   * ```
   */
  async prefetchFlags(context?: OpenFeatureContext): Promise<EvaluationResult[]> {
    if (!this.cacheConfig) {
      throw new Error(
        'prefetchFlags requires caching to be enabled. ' +
        'Configure the provider with a cache: { cache: new InMemoryCache(), ttlSeconds: 30 }'
      );
    }

    // Fetch all flags from API
    const results = await this.httpClient.evaluateAllFlags(context);

    // Cache each result
    const cache = this.cacheConfig.cache;
    const ttl = this.cacheConfig.ttlSeconds ?? DEFAULT_CACHE_TTL_SECONDS;

    for (const result of results) {
      const cacheKey = this.getCacheKey(result.flagKey, context);
      await cache.set(cacheKey, result, ttl);
    }

    return results;
  }

  /**
   * Generate a cache key for a flag evaluation.
   */
  private getCacheKey(flagKey: string, context: OpenFeatureContext | undefined): string {
    if (this.cacheConfig?.keyGenerator) {
      const subflagContext = context ? this.toSubflagContext(context) : undefined;
      return this.cacheConfig.keyGenerator(flagKey, subflagContext);
    }

    // Default key format: subflag:{flagKey}:{contextHash}
    // Treat empty context the same as no context
    const hasContext = context && Object.keys(context).length > 0;
    const contextHash = hasContext ? this.hashContext(context) : 'no_context';
    return `subflag:${flagKey}:${contextHash}`;
  }

  /**
   * Convert OpenFeature context to Subflag context format.
   */
  private toSubflagContext(context: OpenFeatureContext): EvaluationContext {
    return {
      targetingKey: context.targetingKey ?? null,
      kind: 'user',
      attributes: Object.keys(context).length > 0 ? context : null,
    };
  }

  /**
   * Create a simple hash of the context for cache key generation.
   */
  private hashContext(context: OpenFeatureContext): string {
    const sorted = JSON.stringify(context, Object.keys(context).sort());
    // Simple hash function
    let hash = 0;
    for (let i = 0; i < sorted.length; i++) {
      const char = sorted.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return hash.toString(36);
  }

  /**
   * Get a cached evaluation result or fetch from API.
   */
  private async getOrFetch(
    flagKey: string,
    context: OpenFeatureContext | undefined
  ): Promise<EvaluationResult> {
    // If no cache configured, go directly to API
    if (!this.cacheConfig) {
      return this.httpClient.evaluateFlag(flagKey, context);
    }

    const cacheKey = this.getCacheKey(flagKey, context);
    const cache = this.cacheConfig.cache;

    // Try cache first
    const cached = await cache.get(cacheKey);
    if (cached) {
      return cached;
    }

    // Fetch from API
    const result = await this.httpClient.evaluateFlag(flagKey, context);

    // Store in cache
    const ttl = this.cacheConfig.ttlSeconds ?? DEFAULT_CACHE_TTL_SECONDS;
    await cache.set(cacheKey, result, ttl);

    return result;
  }

  /**
   * Resolve a boolean flag value.
   */
  async resolveBooleanEvaluation(
    flagKey: string,
    defaultValue: boolean,
    context: OpenFeatureContext,
    logger: Logger
  ): Promise<ResolutionDetails<boolean>> {
    try {
      const result = await this.getOrFetch(flagKey, context);
      this.warnIfDeprecated(result, logger);

      if (typeof result.value !== 'boolean') {
        return {
          value: defaultValue,
          reason: 'ERROR',
          errorCode: ErrorCode.TYPE_MISMATCH,
          errorMessage: `Expected boolean but got ${typeof result.value}`,
        };
      }

      return {
        value: result.value,
        variant: result.variant,
        reason: result.reason,
      };
    } catch (error) {
      return this.handleError(error, defaultValue);
    }
  }

  /**
   * Resolve a string flag value.
   */
  async resolveStringEvaluation(
    flagKey: string,
    defaultValue: string,
    context: OpenFeatureContext,
    logger: Logger
  ): Promise<ResolutionDetails<string>> {
    try {
      const result = await this.getOrFetch(flagKey, context);
      this.warnIfDeprecated(result, logger);

      if (typeof result.value !== 'string') {
        return {
          value: defaultValue,
          reason: 'ERROR',
          errorCode: ErrorCode.TYPE_MISMATCH,
          errorMessage: `Expected string but got ${typeof result.value}`,
        };
      }

      return {
        value: result.value,
        variant: result.variant,
        reason: result.reason,
      };
    } catch (error) {
      return this.handleError(error, defaultValue);
    }
  }

  /**
   * Resolve a number flag value.
   */
  async resolveNumberEvaluation(
    flagKey: string,
    defaultValue: number,
    context: OpenFeatureContext,
    logger: Logger
  ): Promise<ResolutionDetails<number>> {
    try {
      const result = await this.getOrFetch(flagKey, context);
      this.warnIfDeprecated(result, logger);

      if (typeof result.value !== 'number') {
        return {
          value: defaultValue,
          reason: 'ERROR',
          errorCode: ErrorCode.TYPE_MISMATCH,
          errorMessage: `Expected number but got ${typeof result.value}`,
        };
      }

      return {
        value: result.value,
        variant: result.variant,
        reason: result.reason,
      };
    } catch (error) {
      return this.handleError(error, defaultValue);
    }
  }

  /**
   * Resolve an object flag value.
   */
  async resolveObjectEvaluation<T extends JsonValue>(
    flagKey: string,
    defaultValue: T,
    context: OpenFeatureContext,
    logger: Logger
  ): Promise<ResolutionDetails<T>> {
    try {
      const result = await this.getOrFetch(flagKey, context);
      this.warnIfDeprecated(result, logger);

      if (typeof result.value !== 'object' || result.value === null) {
        return {
          value: defaultValue,
          reason: 'ERROR',
          errorCode: ErrorCode.TYPE_MISMATCH,
          errorMessage: `Expected object but got ${typeof result.value}`,
        };
      }

      return {
        value: result.value as T,
        variant: result.variant,
        reason: result.reason,
      };
    } catch (error) {
      return this.handleError(error, defaultValue);
    }
  }

  /**
   * Handle errors from API calls and convert to ResolutionDetails.
   */
  private handleError<T>(error: unknown, defaultValue: T): ResolutionDetails<T> {
    if (error instanceof SubflagApiError) {
      // Map HTTP status codes to OpenFeature error codes
      let errorCode: ErrorCode;
      if (error.statusCode === 401 || error.statusCode === 403) {
        errorCode = ErrorCode.INVALID_CONTEXT;
      } else if (error.statusCode === 404) {
        errorCode = ErrorCode.FLAG_NOT_FOUND;
      } else if (error.statusCode === 410) {
        // 410 Gone indicates archived flag
        errorCode = ErrorCode.FLAG_NOT_FOUND;
      } else {
        errorCode = ErrorCode.GENERAL;
      }

      return {
        value: defaultValue,
        reason: 'ERROR',
        errorCode,
        errorMessage: error.message,
      };
    }

    return {
      value: defaultValue,
      reason: 'ERROR',
      errorCode: ErrorCode.GENERAL,
      errorMessage: error instanceof Error ? error.message : 'Unknown error',
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
