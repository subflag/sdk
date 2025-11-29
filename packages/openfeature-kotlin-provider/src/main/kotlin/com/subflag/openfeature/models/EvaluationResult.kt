package com.subflag.openfeature.models

/**
 * Result of a flag evaluation from the Subflag API.
 *
 * @property flagKey The flag key that was evaluated
 * @property value Flag value (type depends on flag's valueType). Can be Boolean, String, Number, or Map.
 * @property variant Selected variant name (e.g., "control", "treatment", "enabled")
 * @property reason Reason for this evaluation result
 *
 * @example
 * ```kotlin
 * val result = EvaluationResult(
 *     flagKey = "new-feature",
 *     value = true,
 *     variant = "enabled",
 *     reason = EvaluationReason.SEGMENT_MATCH
 * )
 * ```
 */
data class EvaluationResult(
    val flagKey: String,
    val value: Any?,
    val variant: String,
    val reason: EvaluationReason
)
