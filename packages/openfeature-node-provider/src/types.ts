/**
 * Configuration options for the Subflag provider.
 */
export interface SubflagProviderConfig {
  /**
   * The Subflag API URL (e.g., "http://localhost:8080" or "https://api.subflag.com")
   */
  apiUrl: string;

  /**
   * The API key for SDK authentication (format: sdk-{env}-{random})
   */
  apiKey: string;

  /**
   * Optional timeout for API requests in milliseconds (default: 5000)
   */
  timeout?: number;

  /**
   * Optional cache configuration for caching flag evaluation results.
   *
   * @example
   * ```typescript
   * import { SubflagNodeProvider, InMemoryCache } from '@subflag/openfeature-node-provider';
   *
   * const provider = new SubflagNodeProvider({
   *   apiUrl: 'https://api.subflag.com',
   *   apiKey: 'sdk-prod-...',
   *   cache: {
   *     cache: new InMemoryCache(),
   *     ttlSeconds: 30,
   *   }
   * });
   * ```
   */
  cache?: CacheConfig;
}

/**
 * Evaluation context for flag targeting.
 */
export interface EvaluationContext {
  targetingKey?: string | null;
  kind: string | null;
  attributes?: Record<string, unknown> | null;
}

/**
 * Reason for flag evaluation result
 */
export type EvaluationReason =
  | 'DEFAULT'
  | 'OVERRIDE'
  | 'SEGMENT_MATCH'
  | 'PERCENTAGE_ROLLOUT'
  | 'TARGETING_MATCH'
  | 'ERROR';

/**
 * Lifecycle status of a flag.
 */
export type FlagStatus = 'ACTIVE' | 'DEPRECATED';

/**
 * Result of a flag evaluation.
 */
export interface EvaluationResult {
  flagKey: string;
  value: unknown;
  variant: string;
  reason: EvaluationReason;
  flagStatus?: FlagStatus;
}

/**
 * Cache interface for storing flag evaluation results.
 *
 * Implement this interface to provide custom caching (e.g., Redis, Memcached).
 * A built-in InMemoryCache is provided for simple use cases.
 *
 * @example
 * ```typescript
 * // Using Redis
 * const redisCache: SubflagCache = {
 *   async get(key) {
 *     const data = await redis.get(key);
 *     return data ? JSON.parse(data) : undefined;
 *   },
 *   async set(key, value, ttlSeconds) {
 *     await redis.setex(key, ttlSeconds, JSON.stringify(value));
 *   },
 *   async delete(key) {
 *     await redis.del(key);
 *   }
 * };
 * ```
 */
export interface SubflagCache {
  /**
   * Get a cached value by key.
   * @returns The cached value, or undefined if not found or expired.
   */
  get(key: string): Promise<EvaluationResult | undefined> | EvaluationResult | undefined;

  /**
   * Set a cached value with TTL.
   * @param key - Cache key
   * @param value - Value to cache
   * @param ttlSeconds - Time-to-live in seconds
   */
  set(key: string, value: EvaluationResult, ttlSeconds: number): Promise<void> | void;

  /**
   * Delete a cached value (optional).
   */
  delete?(key: string): Promise<void> | void;

  /**
   * Clear all cached values (optional).
   */
  clear?(): Promise<void> | void;
}

/**
 * Cache configuration options.
 */
export interface CacheConfig {
  /**
   * Cache implementation to use.
   */
  cache: SubflagCache;

  /**
   * Time-to-live for cached values in seconds.
   * @default 60
   */
  ttlSeconds?: number;

  /**
   * Function to generate cache keys.
   * Default: `subflag:${flagKey}:${hash(context)}`
   */
  keyGenerator?: (flagKey: string, context: EvaluationContext | undefined) => string;
}
