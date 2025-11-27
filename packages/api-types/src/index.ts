/**
 * Subflag API Types
 *
 * Hand-written TypeScript types for the Subflag SDK API.
 * These types are kept minimal to reduce package size.
 */

/**
 * Evaluation context for flag targeting.
 * Used to provide user/session information for flag evaluation.
 *
 * @example
 * ```typescript
 * const context: EvaluationContext = {
 *   targetingKey: 'user-123',
 *   kind: 'user',
 *   attributes: {
 *     email: 'user@example.com',
 *     plan: 'premium'
 *   }
 * };
 * ```
 */
export interface EvaluationContext {
  /**
   * Unique identifier for the context (e.g., user ID, session ID, device ID)
   */
  targetingKey?: string | null;

  /**
   * Type of context (e.g., "user", "organization", "device", "session")
   * @default "user"
   */
  kind: string | null;

  /**
   * Custom attributes for targeting (e.g., email, country, tier, role)
   */
  attributes?: Record<string, unknown> | null;
}

/**
 * Reason for flag evaluation result
 */
export type EvaluationReason =
  | 'DEFAULT'           // No targeting rules matched, using default variant
  | 'OVERRIDE'          // Context-specific override applied
  | 'SEGMENT_MATCH'     // Matched a segment targeting rule
  | 'PERCENTAGE_ROLLOUT' // Matched a percentage rollout rule
  | 'TARGETING_MATCH'   // Matched a targeting rule (generic)
  | 'ERROR';            // Evaluation error occurred

/**
 * Result of a flag evaluation.
 *
 * @example
 * ```typescript
 * const result: EvaluationResult = {
 *   flagKey: 'new-feature',
 *   value: true,
 *   variant: 'enabled',
 *   reason: 'SEGMENT_MATCH'
 * };
 * ```
 */
export interface EvaluationResult {
  /**
   * The flag key that was evaluated
   */
  flagKey: string;

  /**
   * Flag value (type depends on flag's valueType)
   * Can be boolean, string, number, or object
   */
  value: unknown;

  /**
   * Selected variant name (e.g., "control", "treatment", "enabled")
   */
  variant: string;

  /**
   * Reason for this evaluation result
   */
  reason: EvaluationReason;
}
