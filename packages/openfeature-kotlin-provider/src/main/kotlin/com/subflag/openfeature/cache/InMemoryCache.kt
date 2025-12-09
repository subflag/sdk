package com.subflag.openfeature.cache

import com.subflag.openfeature.models.EvaluationResult
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

/**
 * Thread-safe in-memory cache implementation with automatic TTL expiration.
 *
 * This cache stores flag evaluation results in memory with configurable TTL.
 * Expired entries are cleaned up automatically by a background thread.
 *
 * @param cleanupIntervalMs Interval between cleanup runs in milliseconds (default: 60 seconds)
 *
 * @example Kotlin
 * ```kotlin
 * val provider = SubflagProvider(
 *     apiUrl = "https://api.subflag.com",
 *     apiKey = "sdk-prod-...",
 *     cache = CacheConfig(
 *         cache = InMemoryCache(),
 *         ttl = Duration.ofSeconds(30)
 *     )
 * )
 * ```
 *
 * @example Java
 * ```java
 * SubflagProvider provider = new SubflagProvider(
 *     "https://api.subflag.com",
 *     "sdk-prod-...",
 *     new CacheConfig(
 *         new InMemoryCache(),
 *         Duration.ofSeconds(30),
 *         null
 *     )
 * );
 * ```
 */
class InMemoryCache @JvmOverloads constructor(
    cleanupIntervalMs: Long = 60_000L
) : SubflagCache {

    private data class CacheEntry(
        val value: EvaluationResult,
        val expiresAt: Long
    ) {
        fun isExpired(): Boolean = System.currentTimeMillis() > expiresAt
    }

    private val cache = ConcurrentHashMap<String, CacheEntry>()
    private val scheduler: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor { runnable ->
        Thread(runnable, "subflag-cache-cleanup").apply {
            isDaemon = true
        }
    }

    init {
        scheduler.scheduleAtFixedRate(
            ::cleanup,
            cleanupIntervalMs,
            cleanupIntervalMs,
            TimeUnit.MILLISECONDS
        )
    }

    override fun get(key: String): EvaluationResult? {
        val entry = cache[key] ?: return null
        if (entry.isExpired()) {
            cache.remove(key)
            return null
        }
        return entry.value
    }

    override fun set(key: String, value: EvaluationResult, ttlMillis: Long) {
        val expiresAt = System.currentTimeMillis() + ttlMillis
        cache[key] = CacheEntry(value, expiresAt)
    }

    override fun delete(key: String) {
        cache.remove(key)
    }

    override fun clear() {
        cache.clear()
    }

    /**
     * Get the current number of entries in the cache (including possibly expired ones).
     */
    val size: Int
        get() = cache.size

    /**
     * Shutdown the cache and stop the cleanup scheduler.
     * Call this when the cache is no longer needed to release resources.
     */
    fun destroy() {
        scheduler.shutdown()
        try {
            if (!scheduler.awaitTermination(1, TimeUnit.SECONDS)) {
                scheduler.shutdownNow()
            }
        } catch (e: InterruptedException) {
            scheduler.shutdownNow()
            Thread.currentThread().interrupt()
        }
        cache.clear()
    }

    private fun cleanup() {
        val now = System.currentTimeMillis()
        cache.entries.removeIf { it.value.expiresAt < now }
    }
}
