package com.subflag.openfeature

import com.subflag.openfeature.exceptions.AuthenticationException
import com.subflag.openfeature.exceptions.FlagNotFoundException
import com.subflag.openfeature.exceptions.SubflagException
import com.subflag.openfeature.models.EvaluationReason
import com.subflag.openfeature.models.SubflagEvaluationContext
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.headersOf
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class SubflagClientTest {

    @Test
    fun `evaluate returns successful result for boolean flag`() = runTest {
        val client = clientWithResponse(
            """{"flagKey": "test-flag", "value": true, "variant": "enabled", "reason": "DEFAULT"}"""
        )

        val result = client.evaluate("test-flag")

        assertEquals("test-flag", result.flagKey)
        assertEquals(true, result.value)
        assertEquals("enabled", result.variant)
        assertEquals(EvaluationReason.DEFAULT, result.reason)
    }

    @Test
    fun `evaluate returns successful result for string flag`() = runTest {
        val client = clientWithResponse(
            """{"flagKey": "color-flag", "value": "blue", "variant": "treatment", "reason": "SEGMENT_MATCH"}"""
        )

        val result = client.evaluate("color-flag")

        assertEquals("color-flag", result.flagKey)
        assertEquals("blue", result.value)
        assertEquals("treatment", result.variant)
        assertEquals(EvaluationReason.SEGMENT_MATCH, result.reason)
    }

    @Test
    fun `evaluate returns successful result for integer flag`() = runTest {
        val client = clientWithResponse(
            """{"flagKey": "limit-flag", "value": 100, "variant": "high", "reason": "PERCENTAGE_ROLLOUT"}"""
        )

        val result = client.evaluate("limit-flag")

        assertEquals("limit-flag", result.flagKey)
        assertEquals(100, result.value)
        assertEquals("high", result.variant)
        assertEquals(EvaluationReason.PERCENTAGE_ROLLOUT, result.reason)
    }

    @Test
    fun `evaluate returns successful result for object flag`() = runTest {
        val client = clientWithResponse(
            """{"flagKey": "config-flag", "value": {"key": "value"}, "variant": "v1", "reason": "OVERRIDE"}"""
        )

        val result = client.evaluate("config-flag")

        assertEquals("config-flag", result.flagKey)
        assertEquals(mapOf("key" to "value"), result.value)
        assertEquals("v1", result.variant)
        assertEquals(EvaluationReason.OVERRIDE, result.reason)
    }

    @Test
    fun `evaluate sends context in request body`() = runTest {
        var requestMade = false

        val httpClient = mockHttpClient {
            requestMade = true
            respond(
                content = """{"flagKey": "test", "value": true, "variant": "on", "reason": "DEFAULT"}""",
                headers = headersOf(HttpHeaders.ContentType, "application/json")
            )
        }
        val client = SubflagClient("https://api.example.com", "test-key", httpClient)

        client.evaluate(
            "test",
            SubflagEvaluationContext(
                targetingKey = "user-123",
                kind = "user",
                attributes = mapOf("plan" to "premium")
            )
        )

        assertTrue(requestMade)
    }

    @Test
    fun `evaluate sends API key header`() = runTest {
        var capturedApiKey: String? = null

        val httpClient = mockHttpClient { request ->
            capturedApiKey = request.headers["X-Subflag-API-Key"]
            respond(
                content = """{"flagKey": "test", "value": true, "variant": "on", "reason": "DEFAULT"}""",
                headers = headersOf(HttpHeaders.ContentType, "application/json")
            )
        }

        val client = SubflagClient("https://api.example.com", "sdk-test-key-123", httpClient)
        client.evaluate("test")

        assertEquals("sdk-test-key-123", capturedApiKey)
    }

    @Test
    fun `evaluate throws AuthenticationException on 401`() = runTest {
        val client = clientWithError(401, """{"error": "Unauthorized", "message": "Invalid API key"}""")

        val exception = assertThrows<AuthenticationException> {
            client.evaluate("test-flag")
        }

        assertEquals(401, exception.statusCode)
    }

    @Test
    fun `evaluate throws AuthenticationException on 403`() = runTest {
        val client = clientWithError(403, """{"error": "Forbidden", "message": "API key disabled"}""")

        val exception = assertThrows<AuthenticationException> {
            client.evaluate("test-flag")
        }

        assertEquals(403, exception.statusCode)
    }

    @Test
    fun `evaluate throws FlagNotFoundException on 404`() = runTest {
        val client = clientWithError(404, """{"error": "Not Found", "message": "Flag not found"}""")

        val exception = assertThrows<FlagNotFoundException> {
            client.evaluate("missing-flag")
        }

        assertEquals("missing-flag", exception.flagKey)
    }

    @Test
    fun `evaluate throws SubflagException on 500`() = runTest {
        val client = clientWithError(500, """{"error": "Internal Server Error"}""")

        val exception = assertThrows<SubflagException> {
            client.evaluate("test-flag")
        }

        assertEquals(500, exception.statusCode)
    }

    @Test
    fun `evaluateAll returns list of results`() = runTest {
        val client = clientWithResponse(
            """[
                {"flagKey": "flag1", "value": true, "variant": "on", "reason": "DEFAULT"},
                {"flagKey": "flag2", "value": "blue", "variant": "b", "reason": "SEGMENT_MATCH"}
            ]"""
        )

        val results = client.evaluateAll()

        assertEquals(2, results.size)
        assertEquals("flag1", results[0].flagKey)
        assertEquals(true, results[0].value)
        assertEquals("flag2", results[1].flagKey)
        assertEquals("blue", results[1].value)
    }

    @Test
    fun `evaluate handles all reason types`() = runTest {
        val reasons = listOf(
            "DEFAULT" to EvaluationReason.DEFAULT,
            "OVERRIDE" to EvaluationReason.OVERRIDE,
            "SEGMENT_MATCH" to EvaluationReason.SEGMENT_MATCH,
            "PERCENTAGE_ROLLOUT" to EvaluationReason.PERCENTAGE_ROLLOUT,
            "TARGETING_MATCH" to EvaluationReason.TARGETING_MATCH,
            "ERROR" to EvaluationReason.ERROR
        )

        for ((jsonReason, expectedReason) in reasons) {
            val client = clientWithResponse(
                """{"flagKey": "test", "value": true, "variant": "v", "reason": "$jsonReason"}"""
            )

            val result = client.evaluate("test")
            assertEquals(expectedReason, result.reason, "Failed for reason: $jsonReason")
        }
    }

    @Test
    fun `evaluate URL-encodes flag key`() = runTest {
        var capturedUrl: String? = null

        val httpClient = mockHttpClient { request ->
            capturedUrl = request.url.toString()
            respond(
                content = """{"flagKey": "flag/with/slashes", "value": true, "variant": "v", "reason": "DEFAULT"}""",
                headers = headersOf(HttpHeaders.ContentType, "application/json")
            )
        }
        val client = SubflagClient("https://api.example.com", "test-key", httpClient)

        client.evaluate("flag/with/slashes")

        assertTrue(capturedUrl?.contains("flag%2Fwith%2Fslashes") == true)
    }

    // Helper functions

    private fun clientWithResponse(json: String) =
        SubflagClient("https://api.example.com", "test-key", mockHttpClientWithResponse(json))

    private fun clientWithError(statusCode: Int, json: String) =
        SubflagClient("https://api.example.com", "test-key", mockHttpClientWithError(statusCode, json))
}
