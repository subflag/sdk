package com.subflag.openfeature

import com.fasterxml.jackson.module.kotlin.jacksonObjectMapper
import com.fasterxml.jackson.module.kotlin.readValue
import com.subflag.openfeature.exceptions.*
import com.subflag.openfeature.models.EvaluationReason
import com.subflag.openfeature.models.EvaluationResult
import com.subflag.openfeature.models.SubflagEvaluationContext
import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.engine.cio.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.jackson.*
import java.net.URLEncoder
import java.time.Duration

/**
 * HTTP client for communicating with the Subflag API.
 *
 * @param apiUrl Base URL of the Subflag API (e.g., "https://api.subflag.com")
 * @param apiKey SDK API key (format: "sdk-{env}-{app}-{random}")
 * @param timeout Request timeout duration (default: 5 seconds). Ignored if custom [httpClient] is provided.
 * @param httpClient Custom Ktor HttpClient for advanced configuration (logging, proxy, SSL, etc.)
 *
 * @example Custom HTTP client with logging
 * ```kotlin
 * val client = SubflagClient(
 *     apiUrl = "https://api.subflag.com",
 *     apiKey = "sdk-prod-...",
 *     httpClient = HttpClient(CIO) {
 *         install(Logging) { level = LogLevel.INFO }
 *         install(ContentNegotiation) { jackson() }
 *     }
 * )
 * ```
 */
class SubflagClient(
    private val apiUrl: String,
    private val apiKey: String,
    private val httpClient: HttpClient
) {
    @JvmOverloads
    constructor(
        apiUrl: String,
        apiKey: String,
        timeout: Duration = Duration.ofSeconds(5)
    ) : this(apiUrl, apiKey, defaultHttpClient(timeout))

    private val baseUrl = apiUrl.trimEnd('/')
    private val objectMapper = jacksonObjectMapper()

    /**
     * Evaluate a single flag.
     *
     * @param flagKey The key of the flag to evaluate
     * @param context Optional evaluation context for targeting
     * @return The evaluation result containing the flag value and metadata
     * @throws SubflagException if the API call fails
     */
    suspend fun evaluate(flagKey: String, context: SubflagEvaluationContext? = null): EvaluationResult {
        val response = httpClient.post("$baseUrl/sdk/evaluate/${flagKey.urlEncode()}") {
            header("X-Subflag-API-Key", apiKey)
            context?.let { setBody(it) }
        }

        return response.handleResponse(flagKey)
    }

    /**
     * Evaluate all flags in the environment (bulk evaluation).
     *
     * @param context Optional evaluation context for targeting
     * @return List of evaluation results for all flags
     * @throws SubflagException if the API call fails
     */
    suspend fun evaluateAll(context: SubflagEvaluationContext? = null): List<EvaluationResult> {
        val response = httpClient.post("$baseUrl/sdk/evaluate-all") {
            header("X-Subflag-API-Key", apiKey)
            context?.let { setBody(it) }
        }

        return response.handleResponseList()
    }

    /**
     * Close the HTTP client and release resources.
     */
    fun close() {
        httpClient.close()
    }

    private suspend fun HttpResponse.handleResponse(flagKey: String): EvaluationResult {
        if (!status.isSuccess()) {
            throwApiError(status.value, bodyAsText(), flagKey)
        }

        val data: Map<String, Any?> = body()
        return data.toEvaluationResult(fallbackFlagKey = flagKey)
    }

    private suspend fun HttpResponse.handleResponseList(): List<EvaluationResult> {
        if (!status.isSuccess()) {
            throwApiError(status.value, bodyAsText(), null)
        }

        val dataList: List<Map<String, Any?>> = body()
        return dataList.map { it.toEvaluationResult() }
    }

    private fun throwApiError(statusCode: Int, responseBody: String, flagKey: String?): Nothing {
        val errorData = runCatching {
            objectMapper.readValue<Map<String, Any?>>(responseBody)
        }.getOrNull()

        val message = errorData?.get("message") as? String
        val error = errorData?.get("error") as? String

        throw when (statusCode) {
            401, 403 -> AuthenticationException(statusCode, message ?: error)
            404 -> FlagNotFoundException(flagKey ?: "unknown", message)
            else -> SubflagException(statusCode, error ?: "HTTP $statusCode", message)
        }
    }

    private fun Map<String, Any?>.toEvaluationResult(fallbackFlagKey: String? = null) =
        EvaluationResult(
            flagKey = (this["flagKey"] as? String) ?: fallbackFlagKey
                ?: error("Missing flagKey in response"),
            value = this["value"],
            variant = (this["variant"] as? String)
                ?: error("Missing variant in response"),
            reason = (this["reason"] as? String).toEvaluationReason()
        )

    private fun String?.toEvaluationReason() = when (this) {
        "DEFAULT" -> EvaluationReason.DEFAULT
        "OVERRIDE" -> EvaluationReason.OVERRIDE
        "SEGMENT_MATCH" -> EvaluationReason.SEGMENT_MATCH
        "PERCENTAGE_ROLLOUT" -> EvaluationReason.PERCENTAGE_ROLLOUT
        "TARGETING_MATCH" -> EvaluationReason.TARGETING_MATCH
        "ERROR" -> EvaluationReason.ERROR
        else -> EvaluationReason.DEFAULT
    }

    private fun String.urlEncode(): String = URLEncoder.encode(this, "UTF-8")
}

private fun defaultHttpClient(timeout: Duration) = HttpClient(CIO) {
    install(ContentNegotiation) {
        jackson()
    }

    defaultRequest {
        contentType(ContentType.Application.Json)
    }

    install(HttpTimeout) {
        requestTimeoutMillis = timeout.toMillis()
        connectTimeoutMillis = timeout.toMillis()
        socketTimeoutMillis = timeout.toMillis()
    }
}
