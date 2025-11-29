package com.subflag.openfeature.exceptions

/**
 * Base exception for all Subflag SDK errors.
 *
 * @property statusCode HTTP status code (0 for non-HTTP errors like timeouts)
 * @property error Short error identifier
 * @property details Optional detailed error message
 */
open class SubflagException(
    val statusCode: Int,
    val error: String,
    val details: String? = null
) : Exception("$error${details?.let { ": $it" } ?: ""}")

/**
 * Thrown when API key authentication fails (401/403).
 */
class AuthenticationException(
    statusCode: Int,
    details: String? = null
) : SubflagException(statusCode, "Authentication failed", details)

/**
 * Thrown when a requested flag is not found (404).
 */
class FlagNotFoundException(
    val flagKey: String,
    details: String? = null
) : SubflagException(404, "Flag not found: $flagKey", details)

/**
 * Thrown when the returned value type doesn't match the expected type.
 */
class TypeMismatchException(
    val expectedType: String,
    val actualType: String
) : SubflagException(0, "Type mismatch", "Expected $expectedType but got $actualType")

/**
 * Thrown when a network error occurs (connection failed, DNS error, etc).
 */
class NetworkException(
    details: String? = null
) : SubflagException(0, "Network error", details)

/**
 * Thrown when a request times out.
 */
class TimeoutException(
    val timeoutMs: Long
) : SubflagException(0, "Request timeout", "Request exceeded ${timeoutMs}ms")
