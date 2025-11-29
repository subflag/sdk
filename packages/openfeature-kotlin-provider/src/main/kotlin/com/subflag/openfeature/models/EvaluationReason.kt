package com.subflag.openfeature.models

/**
 * Reason for flag evaluation result.
 */
enum class EvaluationReason {
    /** No targeting rules matched, using default variant */
    DEFAULT,

    /** Context-specific override applied */
    OVERRIDE,

    /** Matched a segment targeting rule */
    SEGMENT_MATCH,

    /** Matched a percentage rollout rule */
    PERCENTAGE_ROLLOUT,

    /** Matched a targeting rule (generic) */
    TARGETING_MATCH,

    /** Evaluation error occurred */
    ERROR
}
