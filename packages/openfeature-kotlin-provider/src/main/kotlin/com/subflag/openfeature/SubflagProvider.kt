package com.subflag.openfeature

import com.subflag.openfeature.exceptions.*
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
import java.time.Duration

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
 *
 * @example Kotlin
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
    private val client: SubflagClient
) : FeatureProvider {

    @JvmOverloads
    constructor(
        apiUrl: String,
        apiKey: String,
        timeout: Duration = Duration.ofSeconds(5)
    ) : this(SubflagClient(apiUrl, apiKey, timeout))

    constructor(
        apiUrl: String,
        apiKey: String,
        httpClient: HttpClient
    ) : this(SubflagClient(apiUrl, apiKey, httpClient))

    override fun getMetadata(): Metadata = Metadata { "Subflag Kotlin Provider" }

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
            val result = runBlocking {
                client.evaluate(key, context?.toSubflagContext())
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
