package com.subflag.openfeature.models

/**
 * Lifecycle status of a flag.
 */
enum class FlagStatus {
    ACTIVE,
    DEPRECATED;

    companion object {
        fun fromString(value: String?): FlagStatus? {
            return when (value?.uppercase()) {
                "ACTIVE" -> ACTIVE
                "DEPRECATED" -> DEPRECATED
                else -> null
            }
        }
    }
}

/**
 * Result of a flag evaluation from the Subflag API.
 *
 * @property flagKey The flag key that was evaluated
 * @property value Flag value (type depends on flag's valueType). Can be Boolean, String, Number, or Map.
 * @property variant Selected variant name (e.g., "control", "treatment", "enabled")
 * @property reason Reason for this evaluation result
 * @property flagStatus Lifecycle status of the flag (only present when not ACTIVE)
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
    val reason: EvaluationReason,
    val flagStatus: FlagStatus? = null
) {
    /**
     * Check if the flag is deprecated.
     */
    val isDeprecated: Boolean
        get() = flagStatus == FlagStatus.DEPRECATED
}
