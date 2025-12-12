import { OpenFeature } from '@openfeature/web-sdk';

/**
 * Custom hook for type-safe feature flag evaluation
 *
 * This hook provides a simple interface to OpenFeature's client.
 * Since the WebProvider pre-fetches all flags, these calls are synchronous
 * and have zero latency.
 */

const client = OpenFeature.getClient();

export function useFeatureFlag() {
  return {
    /**
     * Get a boolean flag value
     * @param flagKey - The flag key to evaluate
     * @param defaultValue - Fallback value if flag doesn't exist
     */
    getBoolean: (flagKey: string, defaultValue: boolean): boolean => {
      try {
        return client.getBooleanValue(flagKey, defaultValue);
      } catch (error) {
        console.error(`Error evaluating boolean flag '${flagKey}':`, error);
        return defaultValue;
      }
    },

    /**
     * Get a string flag value
     * @param flagKey - The flag key to evaluate
     * @param defaultValue - Fallback value if flag doesn't exist
     */
    getString: (flagKey: string, defaultValue: string): string => {
      try {
        return client.getStringValue(flagKey, defaultValue);
      } catch (error) {
        console.error(`Error evaluating string flag '${flagKey}':`, error);
        return defaultValue;
      }
    },

    /**
     * Get a number flag value (integer or double)
     * @param flagKey - The flag key to evaluate
     * @param defaultValue - Fallback value if flag doesn't exist
     */
    getNumber: (flagKey: string, defaultValue: number): number => {
      try {
        return client.getNumberValue(flagKey, defaultValue);
      } catch (error) {
        console.error(`Error evaluating number flag '${flagKey}':`, error);
        return defaultValue;
      }
    },

    /**
     * Get an object flag value
     * @param flagKey - The flag key to evaluate
     * @param defaultValue - Fallback value if flag doesn't exist
     */
    getObject: <T = Record<string, unknown>>(
      flagKey: string,
      defaultValue: T
    ): T => {
      try {
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        return client.getObjectValue(flagKey, defaultValue as any) as T;
      } catch (error) {
        console.error(`Error evaluating object flag '${flagKey}':`, error);
        return defaultValue;
      }
    },
  };
}
