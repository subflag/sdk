package com.subflag.openfeature.models

import com.fasterxml.jackson.annotation.JsonInclude

/**
 * Evaluation context for flag targeting.
 * Used to provide user/session information for flag evaluation.
 *
 * @property targetingKey Unique identifier for the context (e.g., user ID, session ID, device ID)
 * @property kind Type of context (e.g., "user", "organization", "device", "session"). Defaults to "user".
 * @property attributes Custom attributes for targeting (e.g., email, country, tier, role)
 *
 * @example
 * ```kotlin
 * val context = SubflagEvaluationContext(
 *     targetingKey = "user-123",
 *     kind = "user",
 *     attributes = mapOf(
 *         "email" to "user@example.com",
 *         "plan" to "premium"
 *     )
 * )
 * ```
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
data class SubflagEvaluationContext(
    val targetingKey: String? = null,
    val kind: String? = "user",
    val attributes: Map<String, Any?>? = null
)
