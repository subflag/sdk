package com.subflag.openfeature.cache

import com.subflag.openfeature.models.SubflagEvaluationContext
import java.time.Duration

/**
 * Configuration for the caching layer.
 *
 * @property cache The cache implementation to use (e.g., [InMemoryCache] or a custom Redis cache)
 * @property ttl Time-to-live for cached entries (default: 60 seconds)
 * @property keyGenerator Optional custom function to generate cache keys.
 *                        If not provided, uses the default format: `subflag:{flagKey}:{contextHash}`
 *
 * @example Kotlin - Basic usage
 * ```kotlin
 * val config = CacheConfig(
 *     cache = InMemoryCache(),
 *     ttl = Duration.ofSeconds(30)
 * )
 * ```
 *
 * @example Kotlin - Custom key generator
 * ```kotlin
 * val config = CacheConfig(
 *     cache = InMemoryCache(),
 *     ttl = Duration.ofMinutes(5),
 *     keyGenerator = { flagKey, context ->
 *         "myapp:flags:$flagKey:${context?.targetingKey ?: "anonymous"}"
 *     }
 * )
 * ```
 *
 * @example Java
 * ```java
 * CacheConfig config = new CacheConfig(
 *     new InMemoryCache(),
 *     Duration.ofSeconds(30),
 *     null  // use default key generator
 * );
 * ```
 */
data class CacheConfig @JvmOverloads constructor(
    val cache: SubflagCache,
    val ttl: Duration = Duration.ofSeconds(60),
    val keyGenerator: ((flagKey: String, context: SubflagEvaluationContext?) -> String)? = null
)
