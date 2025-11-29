package com.subflag.openfeature

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.MockRequestHandleScope
import io.ktor.client.engine.mock.respond
import io.ktor.client.plugins.contentnegotiation.ContentNegotiation
import io.ktor.client.plugins.defaultRequest
import io.ktor.client.request.HttpRequestData
import io.ktor.client.request.HttpResponseData
import io.ktor.client.request.header
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import io.ktor.serialization.jackson.jackson

/**
 * Creates a mock HttpClient with standard configuration for testing.
 */
fun mockHttpClient(handler: MockRequestHandleScope.(HttpRequestData) -> HttpResponseData): HttpClient {
    val mockEngine = MockEngine { request -> handler(request) }
    return HttpClient(mockEngine) {
        install(ContentNegotiation) { jackson() }
        defaultRequest {
            header(HttpHeaders.ContentType, "application/json")
        }
    }
}

/**
 * Creates a mock HttpClient that returns a successful JSON response.
 */
fun mockHttpClientWithResponse(json: String): HttpClient = mockHttpClient {
    respond(
        content = json,
        headers = headersOf(HttpHeaders.ContentType, "application/json")
    )
}

/**
 * Creates a mock HttpClient that returns an error response.
 */
fun mockHttpClientWithError(statusCode: Int, json: String): HttpClient = mockHttpClient {
    respond(
        content = json,
        status = HttpStatusCode.fromValue(statusCode),
        headers = headersOf(HttpHeaders.ContentType, "application/json")
    )
}
