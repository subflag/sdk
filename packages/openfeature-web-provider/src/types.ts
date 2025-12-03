/**
 * Configuration options for the Subflag provider.
 */
export interface SubflagProviderConfig {
  /**
   * The Subflag API URL (e.g., "http://localhost:8080" or "https://api.subflag.com")
   */
  apiUrl: string;

  /**
   * The API key for SDK authentication (format: sdk-{env}-{random})
   */
  apiKey: string;

  /**
   * Optional timeout for API requests in milliseconds (default: 5000)
   */
  timeout?: number;
}

/**
 * Evaluation context for flag targeting.
 */
export interface EvaluationContext {
  targetingKey?: string | null;
  kind: string | null;
  attributes?: Record<string, unknown> | null;
}

/**
 * Reason for flag evaluation result
 */
export type EvaluationReason =
  | 'DEFAULT'
  | 'OVERRIDE'
  | 'SEGMENT_MATCH'
  | 'PERCENTAGE_ROLLOUT'
  | 'TARGETING_MATCH'
  | 'ERROR';

/**
 * Lifecycle status of a flag.
 */
export type FlagStatus = 'ACTIVE' | 'DEPRECATED';

/**
 * Result of a flag evaluation.
 */
export interface EvaluationResult {
  flagKey: string;
  value: unknown;
  variant: string;
  reason: EvaluationReason;
  flagStatus?: FlagStatus;
}
