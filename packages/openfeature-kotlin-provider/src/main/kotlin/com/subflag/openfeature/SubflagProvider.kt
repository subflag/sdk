package com.subflag.openfeature

import com.subflag.openfeature.cache.CacheConfig
import com.subflag.openfeature.exceptions.*
import com.subflag.openfeature.models.EvaluationResult
import com.subflag.openfeature.models.SubflagEvaluationContext
import dev.openfeature.sdk.EvaluationContext
import dev.openfeature.sdk.ErrorCode
import dev.openfeature.sdk.FeatureProvider
import dev.openfeature.sdk.ImmutableStructure
import dev.openfeature.sdk.Metadata
import dev.openfeature.sdk.ProviderEvaluation
import dev.openfeature.sdk.Value
import io.ktor.client.*
import kotlinx.coroutines.runBlocking
import java.security.MessageDigest
import java.time.Duration
import java.util.logging.Logger

/**
 * OpenFeature provider for Subflag feature flags.
 *
 * This provider implements the OpenFeature [FeatureProvider] interface, allowing
 * Subflag to be used with any OpenFeature-compatible SDK.
 *
 * @param apiUrl Base URL of the Subflag API (e.g., "https://api.subflag.com")
 * @param apiKey SDK API key (format: "sdk-{env}-{app}-{random}")
 * @param timeout Request timeout duration (default: 5 seconds). Ignored if custom [httpClient] is provided.
 * @param httpClient Custom Ktor HttpClient for advanced configuration (logging, proxy, SSL, etc.)
 * @param cache Optional cache configuration for caching flag evaluations
 *
 * @example Kotlin - Basic usage
 * ```kotlin
 * val provider = SubflagProvider(
 *     apiUrl = "https://api.subflag.com",
 *     apiKey = "sdk-prod-myapp-abc123..."
 * )
 *
 * OpenFeatureAPI.getInstance().setProvider(provider)
 * val client = OpenFeatureAPI.getInstance().client
 *
 * val isEnabled = client.getBooleanValue("new-feature", false)
 * ```
 *
 * @example Kotlin - With caching
 * ```kotlin
 * val provider = SubflagProvider(
 *     apiUrl = "https://api.subflag.com",
 *     apiKey = "sdk-prod-...",
 *     cache = CacheConfig(
 *         cache = InMemoryCache(),
 *         ttl = Duration.ofSeconds(30)
 *     )
 * )
 *
 * // Prefetch all flags for a user
 * provider.prefetchFlags(context)
 *
 * // Subsequent evaluations use cache
 * client.getBooleanValue("feature", false, context)
 * ```
 *
 * @example Java
 * ```java
 * SubflagProvider provider = new SubflagProvider(
 *     "https://api.subflag.com",
 *     "sdk-prod-myapp-abc123..."
 * );
 *
 * OpenFeatureAPI.getInstance().setProvider(provider);
 * Client client = OpenFeatureAPI.getInstance().getClient();
 *
 * boolean isEnabled = client.getBooleanValue("new-feature", false);
 * ```
 */
class SubflagProvider private constructor(
    private val client: SubflagClient,
    private val cacheConfig: CacheConfig?
) : FeatureProvider {

    companion object {
        private val logger = Logger.getLogger(SubflagProvider::class.java.name)
    }

    @JvmOverloads
    constructor(
        apiUrl: String,
        apiKey: String,
        timeout: Duration = Duration.ofSeconds(5),
        cache: CacheConfig? = null
    ) : this(SubflagClient(apiUrl, apiKey, timeout), cache)

    constructor(
        apiUrl: String,
        apiKey: String,
        httpClient: HttpClient,
        cache: CacheConfig? = null
    ) : this(SubflagClient(apiUrl, apiKey, httpClient), cache)

    // For testing - maintains backwards compatibility
    internal constructor(
        apiUrl: String,
        apiKey: String,
        httpClient: HttpClient
    ) : this(SubflagClient(apiUrl, apiKey, httpClient), null)

    override fun getMetadata(): Metadata = Metadata { "Subflag Kotlin Provider" }

    /**
     * Prefetch all flags for the given context and cache them.
     *
     * This fetches all flags in a single API call and stores them in the cache,
     * so subsequent flag evaluations can be served from cache without API calls.
     *
     * @param context Optional evaluation context for targeting
     * @return List of all evaluation results (for inspection)
     * @throws IllegalStateException if caching is not configured
     *
     * @example Kotlin
     * ```kotlin
     * val provider = SubflagProvider(
     *     apiUrl = "https://api.subflag.com",
     *     apiKey = "sdk-prod-...",
     *     cache = CacheConfig(cache = InMemoryCache(), ttl = Duration.ofSeconds(30))
     * )
     *
     * // Prefetch all flags for a user
     * val context = ImmutableContext("user-123")
     * val results = provider.prefetchFlags(context)
     *
     * // Subsequent evaluations use cached values (no API calls)
     * client.getBooleanValue("feature-a", false, context)
     * client.getBooleanValue("feature-b", false, context)
     * ```
     *
     * @example Java
     * ```java
     * List<EvaluationResult> results = provider.prefetchFlags(context);
     * ```
     */
    fun prefetchFlags(context: EvaluationContext? = null): List<EvaluationResult> {
        val config = cacheConfig ?: throw IllegalStateException(
            "prefetchFlags requires caching to be enabled. " +
            "Configure the provider with a cache: CacheConfig(cache = InMemoryCache(), ttl = Duration.ofSeconds(30))"
        )

        val subflagContext = context?.toSubflagContext()
        val results = runBlocking {
            client.evaluateAll(subflagContext)
        }

        val cache = config.cache
        val ttlMillis = config.ttl.toMillis()

        for (result in results) {
            val cacheKey = getCacheKey(result.flagKey, subflagContext)
            cache.set(cacheKey, result, ttlMillis)
        }

        return results
    }

    override fun getBooleanEvaluation(
        key: String,
        defaultValue: Boolean,
        context: EvaluationContext?
    ): ProviderEvaluation<Boolean> = evaluate(key, defaultValue, context) { value ->
        (value as? Boolean) ?: throw TypeMismatchException("Boolean", value?.javaClass?.simpleName ?: "null")
    }

    override fun getStringEvaluation(
        key: String,
        defaultValue: String,
        context: EvaluationContext?
    ): ProviderEvaluation<String> = evaluate(key, defaultValue, context) { value ->
        (value as? String) ?: throw TypeMismatchException("String", value?.javaClass?.simpleName ?: "null")
    }

    override fun getIntegerEvaluation(
        key: String,
        defaultValue: Int,
        context: EvaluationContext?
    ): ProviderEvaluation<Int> = evaluate(key, defaultValue, context) { value ->
        when (value) {
            is Int -> value
            is Number -> value.toInt()
            else -> throw TypeMismatchException("Integer", value?.javaClass?.simpleName ?: "null")
        }
    }

    override fun getDoubleEvaluation(
        key: String,
        defaultValue: Double,
        context: EvaluationContext?
    ): ProviderEvaluation<Double> = evaluate(key, defaultValue, context) { value ->
        when (value) {
            is Double -> value
            is Number -> value.toDouble()
            else -> throw TypeMismatchException("Double", value?.javaClass?.simpleName ?: "null")
        }
    }

    override fun getObjectEvaluation(
        key: String,
        defaultValue: Value,
        context: EvaluationContext?
    ): ProviderEvaluation<Value> = evaluate(key, defaultValue, context) { value ->
        value.toOpenFeatureValue()
    }

    private fun <T> evaluate(
        key: String,
        defaultValue: T,
        context: EvaluationContext?,
        typeConverter: (Any?) -> T
    ): ProviderEvaluation<T> {
        return try {
            val subflagContext = context?.toSubflagContext()
            val result = getOrFetch(key, subflagContext)

            // Warn if flag is deprecated
            if (result.isDeprecated) {
                logger.warning(
                    "Flag \"$key\" is deprecated and scheduled for removal. " +
                    "Please migrate away from this flag."
                )
            }

            val typedValue = try {
                typeConverter(result.value)
            } catch (e: TypeMismatchException) {
                return ProviderEvaluation.builder<T>()
                    .value(defaultValue)
                    .reason("ERROR")
                    .errorCode(ErrorCode.TYPE_MISMATCH)
                    .errorMessage(e.message)
                    .build()
            }

            ProviderEvaluation.builder<T>()
                .value(typedValue)
                .variant(result.variant)
                .reason(result.reason.name)
                .build()

        } catch (e: SubflagException) {
            ProviderEvaluation.builder<T>()
                .value(defaultValue)
                .reason("ERROR")
                .errorCode(e.toErrorCode())
                .errorMessage(e.message)
                .build()
        }
    }

    /**
     * Get evaluation result from cache or fetch from API.
     */
    private fun getOrFetch(flagKey: String, context: SubflagEvaluationContext?): EvaluationResult {
        // If no cache configured, fetch directly
        if (cacheConfig == null) {
            return runBlocking {
                client.evaluate(flagKey, context)
            }
        }

        val cacheKey = getCacheKey(flagKey, context)
        val cache = cacheConfig.cache

        // Try cache first
        val cached = cache.get(cacheKey)
        if (cached != null) {
            return cached
        }

        // Fetch from API
        val result = runBlocking {
            client.evaluate(flagKey, context)
        }

        // Store in cache
        cache.set(cacheKey, result, cacheConfig.ttl.toMillis())

        return result
    }

    /**
     * Generate a cache key for a flag evaluation.
     */
    private fun getCacheKey(flagKey: String, context: SubflagEvaluationContext?): String {
        // Use custom key generator if provided
        cacheConfig?.keyGenerator?.let { generator ->
            return generator(flagKey, context)
        }

        // Default key format: subflag:{flagKey}:{contextHash}
        // Treat empty context the same as no context
        val hasContext = context != null && !context.isEmpty()
        val contextHash = if (hasContext) hashContext(context!!) else "no_context"
        return "subflag:$flagKey:$contextHash"
    }

    /**
     * Check if context is effectively empty.
     * A context is empty if it has no targeting key and no attributes.
     * The default kind ("user") is not considered meaningful data.
     */
    private fun SubflagEvaluationContext.isEmpty(): Boolean {
        return targetingKey.isNullOrEmpty() && (attributes == null || attributes.isEmpty())
    }

    /**
     * Create a stable hash of the context for cache key generation.
     * Uses SHA-256 (truncated) for stability across JVM restarts.
     */
    private fun hashContext(context: SubflagEvaluationContext): String {
        val canonical = buildString {
            context.targetingKey?.let { append("tk=$it|") }
            context.kind?.let { append("k=$it|") }
            context.attributes?.toSortedMap()?.forEach { (k, v) ->
                append("$k=$v|")
            }
        }

        val digest = MessageDigest.getInstance("SHA-256")
        val hashBytes = digest.digest(canonical.toByteArray(Charsets.UTF_8))
        return hashBytes.take(8).joinToString("") { "%02x".format(it) }
    }

    private fun EvaluationContext.toSubflagContext() = SubflagEvaluationContext(
        targetingKey = targetingKey,
        kind = "user",
        attributes = asMap()
            .filterKeys { it != "targetingKey" }
            .mapValues { it.value.asObject() }
            .takeIf { it.isNotEmpty() }
    )

    private fun Any?.toOpenFeatureValue(): Value = when (this) {
        null -> Value(null as String?)
        is Boolean -> Value(this)
        is String -> Value(this)
        is Int -> Value(this)
        is Long -> Value(this.toInt())
        is Double -> Value(this)
        is Float -> Value(this.toDouble())
        is List<*> -> Value(this.map { it.toOpenFeatureValue() })
        is Map<*, *> -> Value(
            ImmutableStructure(
                this.entries.associate { (k, v) ->
                    k.toString() to v.toOpenFeatureValue()
                }
            )
        )
        else -> Value(this.toString())
    }

    private fun SubflagException.toErrorCode() = when (this) {
        is AuthenticationException -> ErrorCode.INVALID_CONTEXT
        is FlagNotFoundException -> ErrorCode.FLAG_NOT_FOUND
        is TypeMismatchException -> ErrorCode.TYPE_MISMATCH
        else -> ErrorCode.GENERAL
    }

    /**
     * Shutdown the provider and release resources.
     */
    override fun shutdown() {
        client.close()
    }
}
