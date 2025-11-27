// Re-export types from the generated API types package
export type { EvaluationContext, EvaluationResult } from '@subflag/api-types';

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
