package com.subflag.openfeature

import dev.openfeature.sdk.ErrorCode
import dev.openfeature.sdk.ImmutableContext
import dev.openfeature.sdk.Value
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.headersOf
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

class SubflagProviderTest {

    @Test
    fun `getMetadata returns provider name`() {
        val provider = providerWithResponse("""{"flagKey": "test", "value": true, "variant": "v", "reason": "DEFAULT"}""")

        assertEquals("Subflag Kotlin Provider", provider.metadata.name)
    }

    @Test
    fun `getBooleanEvaluation returns boolean value`() {
        val provider = providerWithResponse(
            """{"flagKey": "bool-flag", "value": true, "variant": "enabled", "reason": "DEFAULT"}"""
        )

        val result = provider.getBooleanEvaluation("bool-flag", false, null)

        assertEquals(true, result.value)
        assertEquals("enabled", result.variant)
        assertEquals("DEFAULT", result.reason)
        assertNull(result.errorCode)
    }

    @Test
    fun `getBooleanEvaluation returns default on type mismatch`() {
        val provider = providerWithResponse(
            """{"flagKey": "string-flag", "value": "not-a-boolean", "variant": "v", "reason": "DEFAULT"}"""
        )

        val result = provider.getBooleanEvaluation("string-flag", false, null)

        assertEquals(false, result.value)
        assertEquals(ErrorCode.TYPE_MISMATCH, result.errorCode)
        assertEquals("ERROR", result.reason)
    }

    @Test
    fun `getStringEvaluation returns string value`() {
        val provider = providerWithResponse(
            """{"flagKey": "color", "value": "blue", "variant": "treatment", "reason": "SEGMENT_MATCH"}"""
        )

        val result = provider.getStringEvaluation("color", "red", null)

        assertEquals("blue", result.value)
        assertEquals("treatment", result.variant)
        assertEquals("SEGMENT_MATCH", result.reason)
    }

    @Test
    fun `getStringEvaluation returns default on type mismatch`() {
        val provider = providerWithResponse(
            """{"flagKey": "num-flag", "value": 123, "variant": "v", "reason": "DEFAULT"}"""
        )

        val result = provider.getStringEvaluation("num-flag", "default", null)

        assertEquals("default", result.value)
        assertEquals(ErrorCode.TYPE_MISMATCH, result.errorCode)
    }

    @Test
    fun `getIntegerEvaluation returns integer value`() {
        val provider = providerWithResponse(
            """{"flagKey": "limit", "value": 100, "variant": "high", "reason": "OVERRIDE"}"""
        )

        val result = provider.getIntegerEvaluation("limit", 10, null)

        assertEquals(100, result.value)
        assertEquals("high", result.variant)
        assertEquals("OVERRIDE", result.reason)
    }

    @Test
    fun `getIntegerEvaluation coerces double to integer`() {
        val provider = providerWithResponse(
            """{"flagKey": "limit", "value": 99.9, "variant": "v", "reason": "DEFAULT"}"""
        )

        val result = provider.getIntegerEvaluation("limit", 10, null)

        assertEquals(99, result.value)
    }

    @Test
    fun `getDoubleEvaluation returns double value`() {
        val provider = providerWithResponse(
            """{"flagKey": "rate", "value": 0.75, "variant": "v", "reason": "PERCENTAGE_ROLLOUT"}"""
        )

        val result = provider.getDoubleEvaluation("rate", 0.5, null)

        assertEquals(0.75, result.value)
        assertEquals("PERCENTAGE_ROLLOUT", result.reason)
    }

    @Test
    fun `getDoubleEvaluation coerces integer to double`() {
        val provider = providerWithResponse(
            """{"flagKey": "rate", "value": 100, "variant": "v", "reason": "DEFAULT"}"""
        )

        val result = provider.getDoubleEvaluation("rate", 0.0, null)

        assertEquals(100.0, result.value)
    }

    @Test
    fun `getObjectEvaluation returns object value`() {
        val provider = providerWithResponse(
            """{"flagKey": "config", "value": {"theme": "dark", "limit": 50}, "variant": "v1", "reason": "DEFAULT"}"""
        )

        val result = provider.getObjectEvaluation("config", Value.objectToValue(emptyMap<String, Any>()), null)

        assertEquals("v1", result.variant)
        val structure = result.value.asStructure()
        assertNotNull(structure)
        assertEquals("dark", structure.getValue("theme").asString())
        assertEquals(50, structure.getValue("limit").asInteger())
    }

    @Test
    fun `evaluation passes context to API`() {
        var requestMade = false

        val httpClient = mockHttpClient {
            requestMade = true
            respond(
                content = """{"flagKey": "test", "value": true, "variant": "v", "reason": "TARGETING_MATCH"}""",
                headers = headersOf(HttpHeaders.ContentType, "application/json")
            )
        }
        val provider = SubflagProvider("https://api.example.com", "test-key", httpClient)

        val context = ImmutableContext("user-123", mapOf("plan" to Value("premium")))
        val result = provider.getBooleanEvaluation("test", false, context)

        assertEquals(true, requestMade)
        assertEquals("TARGETING_MATCH", result.reason)
    }

    @Test
    fun `evaluation returns default on 401 error`() {
        val provider = providerWithError(401, """{"error": "Unauthorized"}""")

        val result = provider.getBooleanEvaluation("test", true, null)

        assertEquals(true, result.value)
        assertEquals(ErrorCode.INVALID_CONTEXT, result.errorCode)
        assertEquals("ERROR", result.reason)
    }

    @Test
    fun `evaluation returns default on 404 error`() {
        val provider = providerWithError(404, """{"error": "Not Found"}""")

        val result = provider.getStringEvaluation("missing", "fallback", null)

        assertEquals("fallback", result.value)
        assertEquals(ErrorCode.FLAG_NOT_FOUND, result.errorCode)
    }

    @Test
    fun `evaluation returns default on 500 error`() {
        val provider = providerWithError(500, """{"error": "Internal Server Error"}""")

        val result = provider.getIntegerEvaluation("test", 42, null)

        assertEquals(42, result.value)
        assertEquals(ErrorCode.GENERAL, result.errorCode)
    }

    // Helper functions

    private fun providerWithResponse(json: String) =
        SubflagProvider("https://api.example.com", "test-key", mockHttpClientWithResponse(json))

    private fun providerWithError(statusCode: Int, json: String) =
        SubflagProvider("https://api.example.com", "test-key", mockHttpClientWithError(statusCode, json))
}
