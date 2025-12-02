import type {
  EvaluationContext as OpenFeatureContext,
  JsonValue,
  Logger,
  Provider,
  ResolutionDetails,
} from '@openfeature/server-sdk';
import { ErrorCode } from '@openfeature/server-sdk';
import { SubflagHttpClient, SubflagApiError } from './http-client';
import type { SubflagProviderConfig } from './types';
import type { EvaluationResult } from '@subflag/api-types';

/**
 * OpenFeature provider for Subflag feature flags (Node.js/Server).
 *
 * @example
 * ```typescript
 * import { OpenFeature } from '@openfeature/server-sdk';
 * import { SubflagNodeProvider } from '@subflag/openfeature-node-provider';
 *
 * const provider = new SubflagNodeProvider({
 *   apiUrl: 'http://localhost:8080',
 *   apiKey: 'sdk-prod-...'
 * });
 *
 * await OpenFeature.setProviderAndWait(provider);
 *
 * const client = OpenFeature.getClient();
 * const enabled = await client.getBooleanValue('my-flag', false);
 * ```
 */
export class SubflagNodeProvider implements Provider {
  public readonly metadata = {
    name: 'Subflag Node Provider',
  };

  private readonly httpClient: SubflagHttpClient;

  constructor(config: SubflagProviderConfig) {
    this.httpClient = new SubflagHttpClient(config);
  }

  /**
   * Resolve a boolean flag value.
   */
  async resolveBooleanEvaluation(
    flagKey: string,
    defaultValue: boolean,
    context: OpenFeatureContext,
    logger: Logger
  ): Promise<ResolutionDetails<boolean>> {
    try {
      const result = await this.httpClient.evaluateFlag(flagKey, context);
      this.warnIfDeprecated(result, logger);

      if (typeof result.value !== 'boolean') {
        return {
          value: defaultValue,
          reason: 'ERROR',
          errorCode: ErrorCode.TYPE_MISMATCH,
          errorMessage: `Expected boolean but got ${typeof result.value}`,
        };
      }

      return {
        value: result.value,
        variant: result.variant,
        reason: result.reason,
      };
    } catch (error) {
      return this.handleError(error, defaultValue);
    }
  }

  /**
   * Resolve a string flag value.
   */
  async resolveStringEvaluation(
    flagKey: string,
    defaultValue: string,
    context: OpenFeatureContext,
    logger: Logger
  ): Promise<ResolutionDetails<string>> {
    try {
      const result = await this.httpClient.evaluateFlag(flagKey, context);
      this.warnIfDeprecated(result, logger);

      if (typeof result.value !== 'string') {
        return {
          value: defaultValue,
          reason: 'ERROR',
          errorCode: ErrorCode.TYPE_MISMATCH,
          errorMessage: `Expected string but got ${typeof result.value}`,
        };
      }

      return {
        value: result.value,
        variant: result.variant,
        reason: result.reason,
      };
    } catch (error) {
      return this.handleError(error, defaultValue);
    }
  }

  /**
   * Resolve a number flag value.
   */
  async resolveNumberEvaluation(
    flagKey: string,
    defaultValue: number,
    context: OpenFeatureContext,
    logger: Logger
  ): Promise<ResolutionDetails<number>> {
    try {
      const result = await this.httpClient.evaluateFlag(flagKey, context);
      this.warnIfDeprecated(result, logger);

      if (typeof result.value !== 'number') {
        return {
          value: defaultValue,
          reason: 'ERROR',
          errorCode: ErrorCode.TYPE_MISMATCH,
          errorMessage: `Expected number but got ${typeof result.value}`,
        };
      }

      return {
        value: result.value,
        variant: result.variant,
        reason: result.reason,
      };
    } catch (error) {
      return this.handleError(error, defaultValue);
    }
  }

  /**
   * Resolve an object flag value.
   */
  async resolveObjectEvaluation<T extends JsonValue>(
    flagKey: string,
    defaultValue: T,
    context: OpenFeatureContext,
    logger: Logger
  ): Promise<ResolutionDetails<T>> {
    try {
      const result = await this.httpClient.evaluateFlag(flagKey, context);
      this.warnIfDeprecated(result, logger);

      if (typeof result.value !== 'object' || result.value === null) {
        return {
          value: defaultValue,
          reason: 'ERROR',
          errorCode: ErrorCode.TYPE_MISMATCH,
          errorMessage: `Expected object but got ${typeof result.value}`,
        };
      }

      return {
        value: result.value as T,
        variant: result.variant,
        reason: result.reason,
      };
    } catch (error) {
      return this.handleError(error, defaultValue);
    }
  }

  /**
   * Handle errors from API calls and convert to ResolutionDetails.
   */
  private handleError<T>(error: unknown, defaultValue: T): ResolutionDetails<T> {
    if (error instanceof SubflagApiError) {
      // Map HTTP status codes to OpenFeature error codes
      let errorCode: ErrorCode;
      if (error.statusCode === 401 || error.statusCode === 403) {
        errorCode = ErrorCode.INVALID_CONTEXT;
      } else if (error.statusCode === 404) {
        errorCode = ErrorCode.FLAG_NOT_FOUND;
      } else if (error.statusCode === 410) {
        // 410 Gone indicates archived flag
        errorCode = ErrorCode.FLAG_NOT_FOUND;
      } else {
        errorCode = ErrorCode.GENERAL;
      }

      return {
        value: defaultValue,
        reason: 'ERROR',
        errorCode,
        errorMessage: error.message,
      };
    }

    return {
      value: defaultValue,
      reason: 'ERROR',
      errorCode: ErrorCode.GENERAL,
      errorMessage: error instanceof Error ? error.message : 'Unknown error',
    };
  }

  /**
   * Log a warning if the flag is deprecated.
   */
  private warnIfDeprecated(result: EvaluationResult, logger: Logger): void {
    if (result.flagStatus === 'DEPRECATED') {
      logger.warn(
        `Flag "${result.flagKey}" is deprecated and scheduled for removal. ` +
        `Please migrate away from this flag.`
      );
    }
  }
}
