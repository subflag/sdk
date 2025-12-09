package com.subflag.openfeature.cache

import com.subflag.openfeature.models.EvaluationResult

/**
 * Pluggable cache interface for caching flag evaluation results.
 *
 * Implement this interface to use custom caching solutions like Redis, Memcached,
 * or any other caching system. For simple use cases, use the built-in [InMemoryCache].
 *
 * All methods are synchronous for Java compatibility. If your cache client is async,
 * block within your implementation or use a sync wrapper.
 *
 * @example Kotlin - Redis implementation
 * ```kotlin
 * class RedisCache(private val jedis: Jedis) : SubflagCache {
 *     private val mapper = jacksonObjectMapper()
 *
 *     override fun get(key: String): EvaluationResult? {
 *         val data = jedis.get(key) ?: return null
 *         return mapper.readValue(data, EvaluationResult::class.java)
 *     }
 *
 *     override fun set(key: String, value: EvaluationResult, ttlMillis: Long) {
 *         val data = mapper.writeValueAsString(value)
 *         jedis.psetex(key, ttlMillis, data)
 *     }
 * }
 * ```
 *
 * @example Java - Redis implementation
 * ```java
 * public class RedisCache implements SubflagCache {
 *     private final Jedis jedis;
 *     private final ObjectMapper mapper = new ObjectMapper();
 *
 *     @Override
 *     public EvaluationResult get(String key) {
 *         String data = jedis.get(key);
 *         if (data == null) return null;
 *         return mapper.readValue(data, EvaluationResult.class);
 *     }
 *
 *     @Override
 *     public void set(String key, EvaluationResult value, long ttlMillis) {
 *         jedis.psetex(key, ttlMillis, mapper.writeValueAsString(value));
 *     }
 * }
 * ```
 */
interface SubflagCache {
    /**
     * Retrieve a cached evaluation result.
     *
     * @param key The cache key
     * @return The cached result, or null if not found or expired
     */
    fun get(key: String): EvaluationResult?

    /**
     * Store an evaluation result in the cache.
     *
     * @param key The cache key
     * @param value The evaluation result to cache
     * @param ttlMillis Time-to-live in milliseconds
     */
    fun set(key: String, value: EvaluationResult, ttlMillis: Long)

    /**
     * Remove a specific entry from the cache.
     * Optional - default implementation is a no-op.
     *
     * @param key The cache key to remove
     */
    fun delete(key: String) {}

    /**
     * Clear all entries from the cache.
     * Optional - default implementation is a no-op.
     */
    fun clear() {}
}
