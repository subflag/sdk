import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { SubflagWebProvider } from '../src/SubflagWebProvider';
import { ProviderStatus, ErrorCode } from '@openfeature/web-sdk';

describe('SubflagWebProvider', () => {
  let provider: SubflagWebProvider;

  beforeEach(() => {
    provider = new SubflagWebProvider({
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
      expect(provider.metadata.name).toBe('Subflag Web Provider');
    });
  });

  describe('lifecycle: initialize()', () => {
    it('should fetch all flags and populate cache', async () => {
      const mockFlags = [
        { flagKey: 'flag1', value: true, variant: 'on', reason: 'STATIC' },
        { flagKey: 'flag2', value: 'hello', variant: 'greeting', reason: 'STATIC' },
        { flagKey: 'flag3', value: 42, variant: 'answer', reason: 'STATIC' },
      ];

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => mockFlags,
      });

      await provider.initialize();

      expect(provider.status).toBe(ProviderStatus.READY);
      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8080/sdk/evaluate-all',
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'X-Subflag-API-Key': 'sdk-test-12345678901234567890',
          }),
        })
      );

      // Verify flags are cached
      const result = provider.resolveBooleanEvaluation('flag1', false, {}, {} as any);
      expect(result.value).toBe(true);
    });

    it('should set status to ERROR on failure', async () => {
      global.fetch = vi.fn().mockRejectedValue(new Error('Network failure'));

      await expect(provider.initialize()).rejects.toThrow('Network failure');
      expect(provider.status).toBe(ProviderStatus.ERROR);
    });

    it('should start with NOT_READY status', () => {
      expect(provider.status).toBe(ProviderStatus.NOT_READY);
    });

    it('should clear cache on re-initialization', async () => {
      // First initialization
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => [
          { flagKey: 'old-flag', value: true, variant: 'on', reason: 'STATIC' },
        ],
      });

      await provider.initialize();

      // Second initialization with different flags
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => [
          { flagKey: 'new-flag', value: false, variant: 'off', reason: 'STATIC' },
        ],
      });

      await provider.initialize();

      // Old flag should not be in cache
      const result = provider.resolveBooleanEvaluation('old-flag', true, {}, {} as any);
      expect(result.errorCode).toBe(ErrorCode.FLAG_NOT_FOUND);

      // New flag should be in cache
      const result2 = provider.resolveBooleanEvaluation('new-flag', true, {}, {} as any);
      expect(result2.value).toBe(false);
    });
  });

  describe('lifecycle: onClose()', () => {
    it('should clear cache and reset status', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => [
          { flagKey: 'test', value: true, variant: 'on', reason: 'STATIC' },
        ],
      });

      await provider.initialize();
      expect(provider.status).toBe(ProviderStatus.READY);

      await provider.onClose();

      expect(provider.status).toBe(ProviderStatus.NOT_READY);

      // Cache should be empty
      const result = provider.resolveBooleanEvaluation('test', false, {}, {} as any);
      expect(result.errorCode).toBe(ErrorCode.FLAG_NOT_FOUND);
    });
  });

  describe('resolveBooleanEvaluation', () => {
    beforeEach(async () => {
      // Pre-populate cache
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => [
          { flagKey: 'bool-flag', value: true, variant: 'enabled', reason: 'STATIC' },
          { flagKey: 'string-flag', value: 'hello', variant: 'greeting', reason: 'STATIC' },
        ],
      });
      await provider.initialize();
    });

    it('should return boolean value from cache', () => {
      const result = provider.resolveBooleanEvaluation('bool-flag', false, {}, {} as any);

      expect(result.value).toBe(true);
      expect(result.variant).toBe('enabled');
      expect(result.reason).toBe('STATIC');
    });

    it('should return default value when flag not found in cache', () => {
      const result = provider.resolveBooleanEvaluation('missing-flag', false, {}, {} as any);

      expect(result.value).toBe(false);
      expect(result.reason).toBe('DEFAULT');
      expect(result.errorCode).toBe(ErrorCode.FLAG_NOT_FOUND);
      expect(result.errorMessage).toContain('not found in cache');
    });

    it('should return error on type mismatch', () => {
      const result = provider.resolveBooleanEvaluation('string-flag', false, {}, {} as any);

      expect(result.value).toBe(false);
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.TYPE_MISMATCH);
      expect(result.errorMessage).toContain('Expected boolean but got string');
    });
  });

  describe('resolveStringEvaluation', () => {
    beforeEach(async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => [
          { flagKey: 'banner-text', value: 'Welcome!', variant: 'friendly', reason: 'STATIC' },
          { flagKey: 'empty-string', value: '', variant: 'empty', reason: 'DEFAULT' },
        ],
      });
      await provider.initialize();
    });

    it('should return string value from cache', () => {
      const result = provider.resolveStringEvaluation('banner-text', 'default', {}, {} as any);

      expect(result.value).toBe('Welcome!');
      expect(result.variant).toBe('friendly');
      expect(result.reason).toBe('STATIC');
    });

    it('should handle empty strings', () => {
      const result = provider.resolveStringEvaluation('empty-string', 'default', {}, {} as any);

      expect(result.value).toBe('');
      expect(result.variant).toBe('empty');
      expect(result.reason).toBe('DEFAULT');
    });
  });

  describe('resolveNumberEvaluation', () => {
    beforeEach(async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => [
          { flagKey: 'max-items', value: 42, variant: 'high', reason: 'STATIC' },
          { flagKey: 'zero-value', value: 0, variant: 'zero', reason: 'STATIC' },
          { flagKey: 'negative', value: -10, variant: 'neg', reason: 'STATIC' },
          { flagKey: 'decimal', value: 3.14, variant: 'pi', reason: 'STATIC' },
        ],
      });
      await provider.initialize();
    });

    it('should return number value from cache', () => {
      const result = provider.resolveNumberEvaluation('max-items', 10, {}, {} as any);

      expect(result.value).toBe(42);
      expect(result.variant).toBe('high');
      expect(result.reason).toBe('STATIC');
    });

    it('should handle zero values', () => {
      const result = provider.resolveNumberEvaluation('zero-value', 100, {}, {} as any);

      expect(result.value).toBe(0);
      expect(result.variant).toBe('zero');
    });

    it('should handle negative numbers', () => {
      const result = provider.resolveNumberEvaluation('negative', 0, {}, {} as any);

      expect(result.value).toBe(-10);
      expect(result.variant).toBe('neg');
    });

    it('should handle decimal numbers', () => {
      const result = provider.resolveNumberEvaluation('decimal', 0, {}, {} as any);

      expect(result.value).toBeCloseTo(3.14);
      expect(result.variant).toBe('pi');
    });
  });

  describe('resolveObjectEvaluation', () => {
    beforeEach(async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => [
          {
            flagKey: 'ui-config',
            value: { theme: 'dark', fontSize: 14 },
            variant: 'custom',
            reason: 'STATIC',
          },
          {
            flagKey: 'nested-object',
            value: { user: { name: 'John', prefs: { lang: 'en' } } },
            variant: 'nested',
            reason: 'STATIC',
          },
          {
            flagKey: 'array-value',
            value: { items: [1, 2, 3] },
            variant: 'array',
            reason: 'STATIC',
          },
          {
            flagKey: 'empty-object',
            value: {},
            variant: 'empty',
            reason: 'DEFAULT',
          },
        ],
      });
      await provider.initialize();
    });

    it('should return object value from cache', () => {
      const result = provider.resolveObjectEvaluation('ui-config', {}, {}, {} as any);

      expect(result.value).toEqual({ theme: 'dark', fontSize: 14 });
      expect(result.variant).toBe('custom');
      expect(result.reason).toBe('STATIC');
    });

    it('should handle nested objects', () => {
      const result = provider.resolveObjectEvaluation('nested-object', {}, {}, {} as any);

      expect(result.value).toEqual({ user: { name: 'John', prefs: { lang: 'en' } } });
    });

    it('should handle objects with arrays', () => {
      const result = provider.resolveObjectEvaluation('array-value', {}, {}, {} as any);

      expect(result.value).toEqual({ items: [1, 2, 3] });
    });

    it('should handle empty objects', () => {
      const result = provider.resolveObjectEvaluation('empty-object', { fallback: true }, {}, {} as any);

      expect(result.value).toEqual({});
      expect(result.variant).toBe('empty');
    });

    it('should return error when value is null', async () => {
      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => [
          { flagKey: 'null-value', value: null, variant: 'null', reason: 'STATIC' },
        ],
      });
      await provider.initialize();

      const result = provider.resolveObjectEvaluation('null-value', {}, {}, {} as any);

      expect(result.value).toEqual({});
      expect(result.reason).toBe('ERROR');
      expect(result.errorCode).toBe(ErrorCode.TYPE_MISMATCH);
    });
  });

  describe('configuration', () => {
    it('should use custom API URL', async () => {
      const customProvider = new SubflagWebProvider({
        apiUrl: 'https://api.example.com',
        apiKey: 'test-key',
      });

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => [],
      });

      await customProvider.initialize();

      expect(global.fetch).toHaveBeenCalledWith(
        'https://api.example.com/sdk/evaluate-all',
        expect.any(Object)
      );
    });

    it('should strip trailing slash from API URL', async () => {
      const customProvider = new SubflagWebProvider({
        apiUrl: 'http://localhost:8080/',
        apiKey: 'test-key',
      });

      global.fetch = vi.fn().mockResolvedValue({
        ok: true,
        json: async () => [],
      });

      await customProvider.initialize();

      expect(global.fetch).toHaveBeenCalledWith(
        'http://localhost:8080/sdk/evaluate-all',
        expect.any(Object)
      );
    });
  });
});
