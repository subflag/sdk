import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { SubflagNodeProvider } from '../src/SubflagNodeProvider';
import { ErrorCode } from '@openfeature/server-sdk';

describe('SubflagNodeProvider', () => {
  let provider: SubflagNodeProvider;

  beforeEach(() => {
    provider = new SubflagNodeProvider({
      apiUrl: 'http://localhost:8080',
      apiKey: 'sdk-test-12345678901234567890',
    });

    vi.restoreAllMocks();
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('metadata', () => {
    it('should have correct provider name', () => {
      expect(provider.metadata.name).toBe('Subflag Node Provider');
    });
  });

  describe('resolveBooleanEvaluation', () => {
    it('should return boolean value from API', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'test-flag',
          value: true,
          variant: 'enabled',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);

      expect(result.value).toBe(true);
      expect(result.variant).toBe('enabled');
      expect(result.reason).toBe('STATIC');
      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8080/sdk/evaluate/test-flag',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'X-Subflag-API-Key': 'sdk-test-12345678901234567890',
          }),
        })
      );
    });

    it('should return default value on type mismatch', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'test-flag',
          value: 'not-a-boolean',
          variant: 'control',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);

      expect(result.value).toBe(false);
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.TYPE_MISMATCH);
      expect(result.errorMessage).toContain('Expected boolean but got string');
    });

    it('should return default value on network error', async () => {
      global.fetch = vi.fn().mockRejectedValue(new Error('Network error'));

      const result = await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);

      expect(result.value).toBe(false);
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.GENERAL);
    });

    it('should handle 404 errors', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: false,
        status: 404,
        json: async () => ({ error: 'Flag not found' }),
      });

      const result = await provider.resolveBooleanEvaluation('missing-flag', false, {}, {} as any);

      expect(result.value).toBe(false);
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.FLAG_NOT_FOUND);
    });

    it('should handle 401 unauthorized errors', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: false,
        status: 401,
        json: async () => ({ error: 'Invalid API key' }),
      });

      const result = await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);

      expect(result.value).toBe(false);
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.INVALID_CONTEXT);
    });

    it('should send evaluation context to API', async () => {
      const fetchMock = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'test-flag',
          value: true,
          variant: 'on',
          reason: 'STATIC',
        }),
      });

      global.fetch = fetchMock;

      const context = { targetingKey: 'user-123' };
      await provider.resolveBooleanEvaluation('test-flag', false, context, {} as any);

      // Context is converted to Subflag API format with "kind" field
      expect(fetchMock).toHaveBeenCalledWith(
        'http://localhost:8080/sdk/evaluate/test-flag',
        expect.objectContaining({
          body: JSON.stringify({
            targetingKey: 'user-123',
            kind: 'user',
            attributes: { targetingKey: 'user-123' },
          }),
        })
      );
    });
  });

  describe('resolveStringEvaluation', () => {
    it('should return string value from API', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'banner-text',
          value: 'Welcome!',
          variant: 'friendly',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveStringEvaluation('banner-text', 'default', {}, {} as any);

      expect(result.value).toBe('Welcome!');
      expect(result.variant).toBe('friendly');
      expect(result.reason).toBe('STATIC');
    });

    it('should handle empty strings', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'empty-string',
          value: '',
          variant: 'empty',
          reason: 'DEFAULT',
        }),
      });

      const result = await provider.resolveStringEvaluation('empty-string', 'default', {}, {} as any);

      expect(result.value).toBe('');
      expect(result.variant).toBe('empty');
      expect(result.reason).toBe('DEFAULT');
    });

    it('should return error on type mismatch', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'number-flag',
          value: 42,
          variant: 'answer',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveStringEvaluation('number-flag', 'default', {}, {} as any);

      expect(result.value).toBe('default');
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.TYPE_MISMATCH);
      expect(result.errorMessage).toContain('Expected string but got number');
    });
  });

  describe('resolveNumberEvaluation', () => {
    it('should return number value from API', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'max-items',
          value: 42,
          variant: 'high',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveNumberEvaluation('max-items', 10, {}, {} as any);

      expect(result.value).toBe(42);
      expect(result.variant).toBe('high');
      expect(result.reason).toBe('STATIC');
    });

    it('should handle zero values', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'zero-value',
          value: 0,
          variant: 'zero',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveNumberEvaluation('zero-value', 100, {}, {} as any);

      expect(result.value).toBe(0);
      expect(result.variant).toBe('zero');
    });

    it('should handle negative numbers', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'negative',
          value: -10,
          variant: 'neg',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveNumberEvaluation('negative', 0, {}, {} as any);

      expect(result.value).toBe(-10);
      expect(result.variant).toBe('neg');
    });

    it('should handle decimal numbers', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'decimal',
          value: 3.14,
          variant: 'pi',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveNumberEvaluation('decimal', 0, {}, {} as any);

      expect(result.value).toBeCloseTo(3.14);
      expect(result.variant).toBe('pi');
    });

    it('should return error on type mismatch', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'string-flag',
          value: 'hello',
          variant: 'greeting',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveNumberEvaluation('string-flag', 0, {}, {} as any);

      expect(result.value).toBe(0);
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.TYPE_MISMATCH);
      expect(result.errorMessage).toContain('Expected number but got string');
    });
  });

  describe('resolveObjectEvaluation', () => {
    it('should return object value from API', async () => {
      const config = { theme: 'dark', fontSize: 14 };

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'ui-config',
          value: config,
          variant: 'custom',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveObjectEvaluation('ui-config', {}, {}, {} as any);

      expect(result.value).toEqual(config);
      expect(result.variant).toBe('custom');
      expect(result.reason).toBe('STATIC');
    });

    it('should handle nested objects', async () => {
      const nested = { user: { name: 'John', prefs: { lang: 'en' } } };

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'nested-object',
          value: nested,
          variant: 'nested',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveObjectEvaluation('nested-object', {}, {}, {} as any);

      expect(result.value).toEqual(nested);
    });

    it('should handle objects with arrays', async () => {
      const arrayObj = { items: [1, 2, 3] };

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'array-value',
          value: arrayObj,
          variant: 'array',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveObjectEvaluation('array-value', {}, {}, {} as any);

      expect(result.value).toEqual(arrayObj);
    });

    it('should handle empty objects', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'empty-object',
          value: {},
          variant: 'empty',
          reason: 'DEFAULT',
        }),
      });

      const result = await provider.resolveObjectEvaluation('empty-object', { fallback: true }, {}, {} as any);

      expect(result.value).toEqual({});
      expect(result.variant).toBe('empty');
    });

    it('should return error when value is null', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'null-value',
          value: null,
          variant: 'null',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveObjectEvaluation('null-value', {}, {}, {} as any);

      expect(result.value).toEqual({});
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.TYPE_MISMATCH);
    });

    it('should return error when value is primitive', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'string-value',
          value: 'not-an-object',
          variant: 'text',
          reason: 'STATIC',
        }),
      });

      const result = await provider.resolveObjectEvaluation('string-value', {}, {}, {} as any);

      expect(result.value).toEqual({});
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.TYPE_MISMATCH);
    });
  });

  describe('configuration', () => {
    it('should use custom API URL', async () => {
      const customProvider = new SubflagNodeProvider({
        apiUrl: 'https://api.example.com',
        apiKey: 'test-key',
      });

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'test',
          value: true,
          variant: 'on',
          reason: 'STATIC',
        }),
      });

      await customProvider.resolveBooleanEvaluation('test', false, {}, {} as any);

      expect(global.fetch).toHaveBeenCalledWith(
        'https://api.example.com/sdk/evaluate/test',
        expect.any(Object)
      );
    });

    it('should strip trailing slash from API URL', async () => {
      const customProvider = new SubflagNodeProvider({
        apiUrl: 'http://localhost:8080/',
        apiKey: 'test-key',
      });

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'test',
          value: true,
          variant: 'on',
          reason: 'STATIC',
        }),
      });

      await customProvider.resolveBooleanEvaluation('test', false, {}, {} as any);

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8080/sdk/evaluate/test',
        expect.any(Object)
      );
    });
  });

  describe('authentication', () => {
    it('should send API key in header', async () => {
      const fetchMock = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          flagKey: 'test',
          value: true,
          variant: 'on',
          reason: 'STATIC',
        }),
      });

      global.fetch = fetchMock;

      await provider.resolveBooleanEvaluation('test', false, {}, {} as any);

      expect(fetchMock).toHaveBeenCalledWith(
        expect.any(String),
        expect.objectContaining({
          headers: expect.objectContaining({
            'X-Subflag-API-Key': 'sdk-test-12345678901234567890',
          }),
        })
      );
    });
  });

  describe('error handling', () => {
    it('should handle timeout errors', async () => {
      global.fetch = vi.fn().mockImplementation(() => {
        return new Promise((_, reject) => {
          setTimeout(() => reject(new Error('Request timeout')), 10);
        });
      });

      const result = await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);

      expect(result.value).toBe(false);
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.GENERAL);
    });

    it('should handle invalid JSON responses', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => {
          throw new Error('Invalid JSON');
        },
      });

      const result = await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);

      expect(result.value).toBe(false);
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.GENERAL);
    });

    it('should handle 500 server errors', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: false,
        status: 500,
        json: async () => ({ error: 'Internal server error' }),
      });

      const result = await provider.resolveBooleanEvaluation('test-flag', false, {}, {} as any);

      expect(result.value).toBe(false);
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.GENERAL);
    });
  });
});
