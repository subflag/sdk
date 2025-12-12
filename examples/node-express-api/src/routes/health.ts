import express from 'express';
import { OpenFeature } from '@openfeature/server-sdk';

const router = express.Router();
const client = OpenFeature.getClient();

/**
 * GET /api/health
 *
 * Demonstrates using boolean flags as kill switches with device context
 */
router.get('/', async (req, res) => {
  try {
    // Extract device information from request headers
    const userAgent = req.headers['user-agent'] || 'unknown';
    const deviceId = req.headers['x-device-id'] as string || `device-${Date.now()}`;

    // Create device context - this will show up as a "device" type in Contexts UI
    const deviceContext = {
      targetingKey: deviceId,
      kind: 'device',
      attributes: {
        userAgent: userAgent,
        platform: userAgent.includes('Windows') ? 'Windows'
          : userAgent.includes('Mac') ? 'Mac'
          : userAgent.includes('Linux') ? 'Linux'
          : 'Unknown',
        browser: userAgent.includes('Chrome') ? 'Chrome'
          : userAgent.includes('Firefox') ? 'Firefox'
          : userAgent.includes('Safari') ? 'Safari'
          : 'Unknown',
        isMobile: userAgent.includes('Mobile'),
        screenResolution: req.headers['x-screen-resolution'] as string || '1920x1080',
        language: req.headers['accept-language']?.split(',')[0] || 'en-US',
      },
    };

    console.log('📋 Device context:', deviceContext);

    // Check if the API is enabled via feature flag with device context
    // This acts as a kill switch - you can disable the entire API in an emergency
    const apiEnabled = await client.getBooleanValue('api-enabled', true, deviceContext);

    if (!apiEnabled) {
      return res.status(503).json({
        status: 'disabled',
        message: 'API is currently disabled via feature flag',
        timestamp: new Date().toISOString(),
      });
    }

    // Check various system components with flags
    const databaseEnabled = await client.getBooleanValue('database-enabled', true, deviceContext);
    const cacheEnabled = await client.getBooleanValue('cache-enabled', true, deviceContext);

    // Calculate overall health
    const isHealthy = apiEnabled && databaseEnabled && cacheEnabled;

    res.status(isHealthy ? 200 : 503).json({
      status: isHealthy ? 'healthy' : 'degraded',
      timestamp: new Date().toISOString(),
      checks: {
        api: {
          enabled: apiEnabled,
          status: apiEnabled ? 'ok' : 'disabled',
        },
        database: {
          enabled: databaseEnabled,
          status: databaseEnabled ? 'ok' : 'disabled',
        },
        cache: {
          enabled: cacheEnabled,
          status: cacheEnabled ? 'ok' : 'disabled',
        },
      },
      features: {
        checkoutEnabled: await client.getBooleanValue('enable-checkout', false, deviceContext),
      },
    });

  } catch (error) {
    console.error('❌ Error in health check:', error);

    // Even if flag evaluation fails, return a degraded health status
    res.status(503).json({
      status: 'degraded',
      message: 'Unable to evaluate feature flags',
      timestamp: new Date().toISOString(),
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});

export default router;
