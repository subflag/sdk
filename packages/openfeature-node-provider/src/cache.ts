import type { EvaluationResult, SubflagCache } from './types';

interface CacheEntry {
  value: EvaluationResult;
  expiresAt: number;
}

/**
 * Simple in-memory cache with TTL support.
 *
 * This cache stores values in a Map and automatically expires them based on TTL.
 * Suitable for single-instance Node.js applications.
 *
 * For distributed systems, implement SubflagCache with Redis, Memcached, etc.
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
export class InMemoryCache implements SubflagCache {
  private readonly cache = new Map<string, CacheEntry>();
  private cleanupInterval: ReturnType<typeof setInterval> | null = null;

  /**
   * Create a new in-memory cache.
   * @param cleanupIntervalMs - How often to run cleanup of expired entries (default: 60000ms)
   */
  constructor(cleanupIntervalMs: number = 60_000) {
    // Periodically clean up expired entries to prevent memory leaks
    this.cleanupInterval = setInterval(() => {
      this.cleanup();
    }, cleanupIntervalMs);

    // Don't prevent Node.js from exiting
    if (this.cleanupInterval.unref) {
      this.cleanupInterval.unref();
    }
  }

  get(key: string): EvaluationResult | undefined {
    const entry = this.cache.get(key);

    if (!entry) {
      return undefined;
    }

    // Check if expired
    if (Date.now() > entry.expiresAt) {
      this.cache.delete(key);
      return undefined;
    }

    return entry.value;
  }

  set(key: string, value: EvaluationResult, ttlSeconds: number): void {
    this.cache.set(key, {
      value,
      expiresAt: Date.now() + ttlSeconds * 1000,
    });
  }

  delete(key: string): void {
    this.cache.delete(key);
  }

  clear(): void {
    this.cache.clear();
  }

  /**
   * Get the number of entries in the cache (including expired).
   * Useful for debugging and monitoring.
   */
  get size(): number {
    return this.cache.size;
  }

  /**
   * Stop the cleanup interval.
   * Call this when shutting down to clean up resources.
   */
  destroy(): void {
    if (this.cleanupInterval) {
      clearInterval(this.cleanupInterval);
      this.cleanupInterval = null;
    }
    this.cache.clear();
  }

  /**
   * Remove all expired entries from the cache.
   */
  private cleanup(): void {
    const now = Date.now();
    for (const [key, entry] of this.cache.entries()) {
      if (now > entry.expiresAt) {
        this.cache.delete(key);
      }
    }
  }
}
