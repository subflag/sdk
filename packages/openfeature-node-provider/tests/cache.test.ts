import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { SubflagNodeProvider } from '../src/SubflagNodeProvider';
import { InMemoryCache } from '../src/cache';
import type { SubflagCache, EvaluationResult } from '../src/types';

describe('InMemoryCache', () => {
  let cache: InMemoryCache;

  beforeEach(() => {
    cache = new InMemoryCache();
  });

  afterEach(() => {
    cache.destroy();
  });

  it('should store and retrieve values', () => {
    const result: EvaluationResult = {
      flagKey: 'test-flag',
      value: true,
      variant: 'on',
      reason: 'DEFAULT',
    };

    cache.set('key1', result, 60);
    const retrieved = cache.get('key1');

    expect(retrieved).toEqual(result);
  });

  it('should return undefined for missing keys', () => {
    expect(cache.get('nonexistent')).toBeUndefined();
  });

  it('should expire values after TTL', async () => {
    const result: EvaluationResult = {
      flagKey: 'test-flag',
      value: true,
      variant: 'on',
      reason: 'DEFAULT',
    };

    // Set with 1 second TTL
    cache.set('key1', result, 1);

    // Should exist immediately
    expect(cache.get('key1')).toEqual(result);

    // Wait for expiration
    await new Promise((resolve) => setTimeout(resolve, 1100));

    // Should be expired
    expect(cache.get('key1')).toBeUndefined();
  });

  it('should delete values', () => {
    const result: EvaluationResult = {
      flagKey: 'test-flag',
      value: true,
      variant: 'on',
      reason: 'DEFAULT',
    };

    cache.set('key1', result, 60);
    cache.delete('key1');

    expect(cache.get('key1')).toBeUndefined();
  });

  it('should clear all values', () => {
    const result: EvaluationResult = {
      flagKey: 'test-flag',
      value: true,
      variant: 'on',
      reason: 'DEFAULT',
    };

    cache.set('key1', result, 60);
    cache.set('key2', result, 60);
    cache.clear();

    expect(cache.get('key1')).toBeUndefined();
    expect(cache.get('key2')).toBeUndefined();
    expect(cache.size).toBe(0);
  });

  it('should track size correctly', () => {
    const result: EvaluationResult = {
      flagKey: 'test-flag',
      value: true,
      variant: 'on',
      reason: 'DEFAULT',
    };

    expect(cache.size).toBe(0);

    cache.set('key1', result, 60);
    expect(cache.size).toBe(1);

    cache.set('key2', result, 60);
    expect(cache.size).toBe(2);

    cache.delete('key1');
    expect(cache.size).toBe(1);
  });
});

describe('SubflagNodeProvider with caching', () => {
  let provider: SubflagNodeProvider;
  let cache: InMemoryCache;

  const mockApiResponse = (value: unknown, flagKey = 'test-flag') => ({
    ok: true,
    json: async () => ({
      flagKey,
      value,
      variant: 'test-variant',
      reason: 'DEFAULT',
    }),
  });

  beforeEach(() => {
    vi.restoreAllMocks();
    cache = new InMemoryCache();
    provider = new SubflagNodeProvider({
      apiUrl: 'http://localhost:8080',
      apiKey: 'sdk-test-key',
      cache: {
        cache,
        ttlSeconds: 30,
      },
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
    cache.destroy();
  });

  it('should cache flag evaluations', async () => {
    const fetchMock = vi.fn().mockResolvedValue(mockApiResponse(true));
    global.fetch = fetchMock;

    // First call - should hit API
    await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);
    expect(fetchMock).toHaveBeenCalledTimes(1);

    // Second call - should use cache
    await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);
    expect(fetchMock).toHaveBeenCalledTimes(1); // Still 1, not 2
  });

  it('should use different cache keys for different contexts', async () => {
    const fetchMock = vi.fn().mockResolvedValue(mockApiResponse(true));
    global.fetch = fetchMock;

    // Call with user1 context
    await provider.resolveBooleanEvaluation(
      'test-flag',
      false,
      { targetingKey: 'user-1' },
      {} as any
    );

    // Call with user2 context - should hit API again
    await provider.resolveBooleanEvaluation(
      'test-flag',
      false,
      { targetingKey: 'user-2' },
      {} as any
    );

    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('should use same cache key for same context', async () => {
    const fetchMock = vi.fn().mockResolvedValue(mockApiResponse(true));
    global.fetch = fetchMock;

    const context = { targetingKey: 'user-1', plan: 'premium' };

    // Two calls with same context
    await provider.resolveBooleanEvaluation('test-flag', false, context, {} as any);
    await provider.resolveBooleanEvaluation('test-flag', false, context, {} as any);

    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('should cache different flag types separately', async () => {
    global.fetch = vi
      .fn()
      .mockResolvedValueOnce(mockApiResponse(true, 'bool-flag'))
      .mockResolvedValueOnce(mockApiResponse('hello', 'string-flag'))
      .mockResolvedValueOnce(mockApiResponse(42, 'number-flag'));

    await provider.resolveBooleanEvaluation('bool-flag', false, {}, {} as any);
    await provider.resolveStringEvaluation('string-flag', '', {}, {} as any);
    await provider.resolveNumberEvaluation('number-flag', 0, {}, {} as any);

    // All three should hit API (different flags)
    expect(global.fetch).toHaveBeenCalledTimes(3);

    // Calling them again should use cache
    await provider.resolveBooleanEvaluation('bool-flag', false, {}, {} as any);
    await provider.resolveStringEvaluation('string-flag', '', {}, {} as any);
    await provider.resolveNumberEvaluation('number-flag', 0, {}, {} as any);

    // Still only 3 calls
    expect(global.fetch).toHaveBeenCalledTimes(3);
  });

  it('should work without caching when not configured', async () => {
    const noCacheProvider = new SubflagNodeProvider({
      apiUrl: 'http://localhost:8080',
      apiKey: 'sdk-test-key',
      // No cache configured
    });

    const fetchMock = vi.fn().mockResolvedValue(mockApiResponse(true));
    global.fetch = fetchMock;

    // Both calls should hit API
    await noCacheProvider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);
    await noCacheProvider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);

    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('should use default TTL of 60 seconds when not specified', async () => {
    const providerDefaultTtl = new SubflagNodeProvider({
      apiUrl: 'http://localhost:8080',
      apiKey: 'sdk-test-key',
      cache: {
        cache: new InMemoryCache(),
        // No ttlSeconds specified
      },
    });

    global.fetch = vi.fn().mockResolvedValue(mockApiResponse(true));

    await providerDefaultTtl.resolveBooleanEvaluation('test-flag', false, {}, {} as any);
    await providerDefaultTtl.resolveBooleanEvaluation('test-flag', false, {}, {} as any);

    // Should still use cache (default TTL)
    expect(global.fetch).toHaveBeenCalledTimes(1);
  });
});

describe('Custom cache implementation', () => {
  it('should work with custom cache implementation', async () => {
    const store = new Map<string, EvaluationResult>();

    const customCache: SubflagCache = {
      get: (key) => store.get(key),
      set: (key, value) => {
        store.set(key, value);
      },
      delete: (key) => {
        store.delete(key);
      },
      clear: () => {
        store.clear();
      },
    };

    const provider = new SubflagNodeProvider({
      apiUrl: 'http://localhost:8080',
      apiKey: 'sdk-test-key',
      cache: {
        cache: customCache,
        ttlSeconds: 30,
      },
    });

    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        flagKey: 'test-flag',
        value: true,
        variant: 'on',
        reason: 'DEFAULT',
      }),
    });

    // First call - should hit API
    await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);
    expect(global.fetch).toHaveBeenCalledTimes(1);
    expect(store.size).toBe(1);

    // Second call - should use custom cache
    await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);
    expect(global.fetch).toHaveBeenCalledTimes(1);
  });

  it('should support async cache operations', async () => {
    const store = new Map<string, EvaluationResult>();

    // Simulates Redis or other async cache
    const asyncCache: SubflagCache = {
      get: async (key) => {
        await new Promise((r) => setTimeout(r, 10));
        return store.get(key);
      },
      set: async (key, value) => {
        await new Promise((r) => setTimeout(r, 10));
        store.set(key, value);
      },
    };

    const provider = new SubflagNodeProvider({
      apiUrl: 'http://localhost:8080',
      apiKey: 'sdk-test-key',
      cache: {
        cache: asyncCache,
        ttlSeconds: 30,
      },
    });

    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        flagKey: 'test-flag',
        value: true,
        variant: 'on',
        reason: 'DEFAULT',
      }),
    });

    // First call
    await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);
    expect(global.fetch).toHaveBeenCalledTimes(1);

    // Second call should use cache
    await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);
    expect(global.fetch).toHaveBeenCalledTimes(1);
  });
});

describe('Custom key generator', () => {
  it('should use custom key generator when provided', async () => {
    const keys: string[] = [];

    const cache: SubflagCache = {
      get: (key) => {
        keys.push(`get:${key}`);
        return undefined;
      },
      set: (key) => {
        keys.push(`set:${key}`);
      },
    };

    const provider = new SubflagNodeProvider({
      apiUrl: 'http://localhost:8080',
      apiKey: 'sdk-test-key',
      cache: {
        cache,
        ttlSeconds: 30,
        keyGenerator: (flagKey, context) => `custom:${flagKey}:${context?.targetingKey || 'anon'}`,
      },
    });

    global.fetch = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        flagKey: 'my-flag',
        value: true,
        variant: 'on',
        reason: 'DEFAULT',
      }),
    });

    await provider.resolveBooleanEvaluation(
      'my-flag',
      false,
      { targetingKey: 'user-123' },
      {} as any
    );

    expect(keys).toContain('get:custom:my-flag:user-123');
    expect(keys).toContain('set:custom:my-flag:user-123');
  });
});

describe('prefetchFlags', () => {
  let provider: SubflagNodeProvider;
  let cache: InMemoryCache;

  const mockBulkApiResponse = () => ({
    ok: true,
    json: async () => [
      { flagKey: 'flag-a', value: true, variant: 'on', reason: 'DEFAULT' },
      { flagKey: 'flag-b', value: 'hello', variant: 'greeting', reason: 'TARGETING_MATCH' },
      { flagKey: 'flag-c', value: 42, variant: 'high', reason: 'PERCENTAGE_ROLLOUT' },
    ],
  });

  beforeEach(() => {
    vi.restoreAllMocks();
    cache = new InMemoryCache();
    provider = new SubflagNodeProvider({
      apiUrl: 'http://localhost:8080',
      apiKey: 'sdk-test-key',
      cache: {
        cache,
        ttlSeconds: 30,
      },
    });
  });

  afterEach(() => {
    vi.clearAllMocks();
    cache.destroy();
  });

  it('should fetch all flags and cache them', async () => {
    const fetchMock = vi.fn().mockResolvedValue(mockBulkApiResponse());
    global.fetch = fetchMock;

    const results = await provider.prefetchFlags();

    // Should call evaluate-all endpoint
    expect(fetchMock).toHaveBeenCalledWith(
      'http://localhost:8080/sdk/evaluate-all',
      expect.any(Object)
    );

    // Should return all results
    expect(results).toHaveLength(3);
    expect(results[0].flagKey).toBe('flag-a');
    expect(results[1].flagKey).toBe('flag-b');
    expect(results[2].flagKey).toBe('flag-c');

    // Cache should have all flags
    expect(cache.size).toBe(3);
  });

  it('should allow subsequent evaluations to use cache', async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(mockBulkApiResponse())
      .mockResolvedValue({
        ok: true,
        json: async () => ({ flagKey: 'flag-a', value: true, variant: 'on', reason: 'DEFAULT' }),
      });

    global.fetch = fetchMock;

    // Prefetch all flags
    await provider.prefetchFlags();
    expect(fetchMock).toHaveBeenCalledTimes(1);

    // Subsequent evaluations should use cache - no more API calls
    await provider.resolveBooleanEvaluation('flag-a', false, {}, {} as any);
    await provider.resolveStringEvaluation('flag-b', '', {}, {} as any);
    await provider.resolveNumberEvaluation('flag-c', 0, {}, {} as any);

    // Still only 1 API call (the prefetch)
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('should prefetch with context', async () => {
    const fetchMock = vi.fn().mockResolvedValue(mockBulkApiResponse());
    global.fetch = fetchMock;

    const context = { targetingKey: 'user-123', plan: 'premium' };
    await provider.prefetchFlags(context);

    // Should send context in request body
    expect(fetchMock).toHaveBeenCalledWith(
      'http://localhost:8080/sdk/evaluate-all',
      expect.objectContaining({
        body: expect.stringContaining('user-123'),
      })
    );
  });

  it('should use different cache keys for different contexts', async () => {
    const fetchMock = vi.fn().mockResolvedValue(mockBulkApiResponse());
    global.fetch = fetchMock;

    // Prefetch for user1
    await provider.prefetchFlags({ targetingKey: 'user-1' });

    // Prefetch for user2
    await provider.prefetchFlags({ targetingKey: 'user-2' });

    // Should have called API twice
    expect(fetchMock).toHaveBeenCalledTimes(2);

    // Cache should have 6 entries (3 flags × 2 contexts)
    expect(cache.size).toBe(6);
  });

  it('should throw error when cache is not configured', async () => {
    const noCacheProvider = new SubflagNodeProvider({
      apiUrl: 'http://localhost:8080',
      apiKey: 'sdk-test-key',
      // No cache
    });

    await expect(noCacheProvider.prefetchFlags()).rejects.toThrow(
      'prefetchFlags requires caching to be enabled'
    );
  });

  it('should return results for inspection', async () => {
    global.fetch = vi.fn().mockResolvedValue(mockBulkApiResponse());

    const results = await provider.prefetchFlags();

    // Users can inspect what was prefetched
    expect(results.find((r) => r.flagKey === 'flag-a')?.value).toBe(true);
    expect(results.find((r) => r.flagKey === 'flag-b')?.value).toBe('hello');
    expect(results.find((r) => r.flagKey === 'flag-c')?.value).toBe(42);
  });
});
