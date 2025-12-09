package com.subflag.openfeature

import com.subflag.openfeature.cache.CacheConfig
import com.subflag.openfeature.cache.InMemoryCache
import com.subflag.openfeature.cache.SubflagCache
import com.subflag.openfeature.models.EvaluationReason
import com.subflag.openfeature.models.EvaluationResult
import com.subflag.openfeature.models.SubflagEvaluationContext
import dev.openfeature.sdk.ImmutableContext
import dev.openfeature.sdk.Value
import io.ktor.client.engine.mock.*
import io.ktor.http.*
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import java.time.Duration
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class CacheTest {

    private var cache: InMemoryCache? = null

    @AfterEach
    fun tearDown() {
        cache?.destroy()
    }

    // ============ InMemoryCache Tests ============

    @Test
    fun `InMemoryCache stores and retrieves values`() {
        cache = InMemoryCache()
        val result = createResult("test-flag", true)

        cache!!.set("key1", result, 60_000)
        val retrieved = cache!!.get("key1")

        assertNotNull(retrieved)
        assertEquals("test-flag", retrieved.flagKey)
        assertEquals(true, retrieved.value)
    }

    @Test
    fun `InMemoryCache returns null for missing keys`() {
        cache = InMemoryCache()

        val result = cache!!.get("nonexistent")

        assertNull(result)
    }

    @Test
    fun `InMemoryCache expires entries after TTL`() {
        cache = InMemoryCache()
        val result = createResult("test-flag", true)

        cache!!.set("key1", result, 50) // 50ms TTL
        Thread.sleep(100) // Wait for expiry

        val retrieved = cache!!.get("key1")
        assertNull(retrieved)
    }

    @Test
    fun `InMemoryCache delete removes entry`() {
        cache = InMemoryCache()
        val result = createResult("test-flag", true)

        cache!!.set("key1", result, 60_000)
        cache!!.delete("key1")

        assertNull(cache!!.get("key1"))
    }

    @Test
    fun `InMemoryCache clear removes all entries`() {
        cache = InMemoryCache()

        cache!!.set("key1", createResult("flag1", true), 60_000)
        cache!!.set("key2", createResult("flag2", false), 60_000)
        cache!!.clear()

        assertNull(cache!!.get("key1"))
        assertNull(cache!!.get("key2"))
        assertEquals(0, cache!!.size)
    }

    // ============ Provider Caching Tests ============

    @Test
    fun `provider returns cached value on second call`() {
        cache = InMemoryCache()
        var apiCallCount = 0

        val httpClient = mockHttpClient {
            apiCallCount++
            respond(
                content = """{"flagKey": "cached-flag", "value": true, "variant": "on", "reason": "DEFAULT"}""",
                headers = headersOf(HttpHeaders.ContentType, "application/json")
            )
        }

        val provider = SubflagProvider(
            apiUrl = "https://api.example.com",
            apiKey = "test-key",
            httpClient = httpClient,
            cache = CacheConfig(cache = cache!!, ttl = Duration.ofSeconds(60))
        )

        // First call - hits API
        val result1 = provider.getBooleanEvaluation("cached-flag", false, null)
        assertEquals(true, result1.value)
        assertEquals(1, apiCallCount)

        // Second call - should use cache
        val result2 = provider.getBooleanEvaluation("cached-flag", false, null)
        assertEquals(true, result2.value)
        assertEquals(1, apiCallCount) // Still 1, no new API call
    }

    @Test
    fun `provider fetches again after cache expires`() {
        cache = InMemoryCache()
        var apiCallCount = 0

        val httpClient = mockHttpClient {
            apiCallCount++
            respond(
                content = """{"flagKey": "expiring-flag", "value": true, "variant": "on", "reason": "DEFAULT"}""",
                headers = headersOf(HttpHeaders.ContentType, "application/json")
            )
        }

        val provider = SubflagProvider(
            apiUrl = "https://api.example.com",
            apiKey = "test-key",
            httpClient = httpClient,
            cache = CacheConfig(cache = cache!!, ttl = Duration.ofMillis(50))
        )

        // First call
        provider.getBooleanEvaluation("expiring-flag", false, null)
        assertEquals(1, apiCallCount)

        // Wait for expiry
        Thread.sleep(100)

        // Second call - should hit API again
        provider.getBooleanEvaluation("expiring-flag", false, null)
        assertEquals(2, apiCallCount)
    }

    @Test
    fun `provider uses different cache keys for different contexts`() {
        cache = InMemoryCache()
        var apiCallCount = 0

        val httpClient = mockHttpClient {
            apiCallCount++
            respond(
                content = """{"flagKey": "context-flag", "value": true, "variant": "on", "reason": "DEFAULT"}""",
                headers = headersOf(HttpHeaders.ContentType, "application/json")
            )
        }

        val provider = SubflagProvider(
            apiUrl = "https://api.example.com",
            apiKey = "test-key",
            httpClient = httpClient,
            cache = CacheConfig(cache = cache!!, ttl = Duration.ofSeconds(60))
        )

        val context1 = ImmutableContext("user-1")
        val context2 = ImmutableContext("user-2")

        // Different contexts should cause separate API calls
        provider.getBooleanEvaluation("context-flag", false, context1)
        assertEquals(1, apiCallCount)

        provider.getBooleanEvaluation("context-flag", false, context2)
        assertEquals(2, apiCallCount)

        // Same context should use cache
        provider.getBooleanEvaluation("context-flag", false, context1)
        assertEquals(2, apiCallCount) // Still 2
    }

    @Test
    fun `provider treats null and empty context the same`() {
        cache = InMemoryCache()
        var apiCallCount = 0

        val httpClient = mockHttpClient {
            apiCallCount++
            respond(
                content = """{"flagKey": "null-context-flag", "value": true, "variant": "on", "reason": "DEFAULT"}""",
                headers = headersOf(HttpHeaders.ContentType, "application/json")
            )
        }

        val provider = SubflagProvider(
            apiUrl = "https://api.example.com",
            apiKey = "test-key",
            httpClient = httpClient,
            cache = CacheConfig(cache = cache!!, ttl = Duration.ofSeconds(60))
        )

        // Call with null context
        provider.getBooleanEvaluation("null-context-flag", false, null)
        assertEquals(1, apiCallCount)

        // Call with empty context (no targeting key, no attributes)
        val emptyContext = ImmutableContext()
        provider.getBooleanEvaluation("null-context-flag", false, emptyContext)
        assertEquals(1, apiCallCount) // Should use cache
    }

    // ============ Prefetch Tests ============

    @Test
    fun `prefetchFlags throws when cache not configured`() {
        val httpClient = mockHttpClientWithResponse("""[]""")
        val provider = SubflagProvider("https://api.example.com", "test-key", httpClient)

        val exception = assertThrows<IllegalStateException> {
            provider.prefetchFlags()
        }

        assertEquals(
            "prefetchFlags requires caching to be enabled. " +
            "Configure the provider with a cache: CacheConfig(cache = InMemoryCache(), ttl = Duration.ofSeconds(30))",
            exception.message
        )
    }

    @Test
    fun `prefetchFlags caches all returned flags`() {
        cache = InMemoryCache()
        var evaluateAllCalled = false
        var singleEvaluateCalled = false

        val httpClient = mockHttpClient { request ->
            when {
                request.url.encodedPath.endsWith("/evaluate-all") -> {
                    evaluateAllCalled = true
                    respond(
                        content = """[
                            {"flagKey": "flag-a", "value": true, "variant": "on", "reason": "DEFAULT"},
                            {"flagKey": "flag-b", "value": "blue", "variant": "treatment", "reason": "SEGMENT_MATCH"},
                            {"flagKey": "flag-c", "value": 42, "variant": "high", "reason": "DEFAULT"}
                        ]""",
                        headers = headersOf(HttpHeaders.ContentType, "application/json")
                    )
                }
                else -> {
                    singleEvaluateCalled = true
                    respond(
                        content = """{"flagKey": "unexpected", "value": false, "variant": "off", "reason": "DEFAULT"}""",
                        headers = headersOf(HttpHeaders.ContentType, "application/json")
                    )
                }
            }
        }

        val provider = SubflagProvider(
            apiUrl = "https://api.example.com",
            apiKey = "test-key",
            httpClient = httpClient,
            cache = CacheConfig(cache = cache!!, ttl = Duration.ofSeconds(60))
        )

        // Prefetch
        val results = provider.prefetchFlags()
        assertEquals(3, results.size)
        assertEquals(true, evaluateAllCalled)

        // Subsequent evaluations should use cache
        val flagA = provider.getBooleanEvaluation("flag-a", false, null)
        val flagB = provider.getStringEvaluation("flag-b", "red", null)
        val flagC = provider.getIntegerEvaluation("flag-c", 0, null)

        assertEquals(true, flagA.value)
        assertEquals("blue", flagB.value)
        assertEquals(42, flagC.value)
        assertEquals(false, singleEvaluateCalled) // No individual API calls
    }

    @Test
    fun `prefetchFlags with context caches for that context`() {
        cache = InMemoryCache()
        var apiCallCount = 0

        val httpClient = mockHttpClient { request ->
            apiCallCount++
            when {
                request.url.encodedPath.endsWith("/evaluate-all") -> {
                    respond(
                        content = """[{"flagKey": "user-flag", "value": true, "variant": "on", "reason": "TARGETING_MATCH"}]""",
                        headers = headersOf(HttpHeaders.ContentType, "application/json")
                    )
                }
                else -> {
                    respond(
                        content = """{"flagKey": "user-flag", "value": false, "variant": "off", "reason": "DEFAULT"}""",
                        headers = headersOf(HttpHeaders.ContentType, "application/json")
                    )
                }
            }
        }

        val provider = SubflagProvider(
            apiUrl = "https://api.example.com",
            apiKey = "test-key",
            httpClient = httpClient,
            cache = CacheConfig(cache = cache!!, ttl = Duration.ofSeconds(60))
        )

        val userContext = ImmutableContext("user-123", mapOf("plan" to Value("premium")))

        // Prefetch for specific user
        provider.prefetchFlags(userContext)
        assertEquals(1, apiCallCount)

        // Evaluation with same context uses cache
        val result = provider.getBooleanEvaluation("user-flag", false, userContext)
        assertEquals(true, result.value)
        assertEquals(1, apiCallCount) // No new call

        // Different context triggers new API call
        val otherContext = ImmutableContext("user-456")
        provider.getBooleanEvaluation("user-flag", false, otherContext)
        assertEquals(2, apiCallCount)
    }

    // ============ Custom Key Generator Tests ============

    @Test
    fun `provider uses custom key generator when provided`() {
        cache = InMemoryCache()
        var generatorCalled = false

        val httpClient = mockHttpClientWithResponse(
            """{"flagKey": "custom-key-flag", "value": true, "variant": "on", "reason": "DEFAULT"}"""
        )

        val provider = SubflagProvider(
            apiUrl = "https://api.example.com",
            apiKey = "test-key",
            httpClient = httpClient,
            cache = CacheConfig(
                cache = cache!!,
                ttl = Duration.ofSeconds(60),
                keyGenerator = { flagKey, context ->
                    generatorCalled = true
                    "custom:$flagKey:${context?.targetingKey ?: "anon"}"
                }
            )
        )

        val context = ImmutableContext("user-xyz")
        provider.getBooleanEvaluation("custom-key-flag", false, context)

        assertEquals(true, generatorCalled)
        // Verify the custom key was used
        assertNotNull(cache!!.get("custom:custom-key-flag:user-xyz"))
    }

    // ============ Custom Cache Implementation Tests ============

    @Test
    fun `provider works with custom cache implementation`() {
        val customCache = object : SubflagCache {
            private val store = mutableMapOf<String, EvaluationResult>()

            override fun get(key: String): EvaluationResult? = store[key]
            override fun set(key: String, value: EvaluationResult, ttlMillis: Long) {
                store[key] = value
            }
            override fun delete(key: String) {
                store.remove(key)
            }
            override fun clear() {
                store.clear()
            }
        }

        var apiCallCount = 0
        val httpClient = mockHttpClient {
            apiCallCount++
            respond(
                content = """{"flagKey": "custom-cache-flag", "value": true, "variant": "on", "reason": "DEFAULT"}""",
                headers = headersOf(HttpHeaders.ContentType, "application/json")
            )
        }

        val provider = SubflagProvider(
            apiUrl = "https://api.example.com",
            apiKey = "test-key",
            httpClient = httpClient,
            cache = CacheConfig(cache = customCache, ttl = Duration.ofSeconds(60))
        )

        // First call
        provider.getBooleanEvaluation("custom-cache-flag", false, null)
        assertEquals(1, apiCallCount)

        // Second call - uses custom cache
        provider.getBooleanEvaluation("custom-cache-flag", false, null)
        assertEquals(1, apiCallCount)
    }

    // ============ Helper Functions ============

    private fun createResult(flagKey: String, value: Any): EvaluationResult {
        return EvaluationResult(
            flagKey = flagKey,
            value = value,
            variant = "test-variant",
            reason = EvaluationReason.DEFAULT
        )
    }
}
