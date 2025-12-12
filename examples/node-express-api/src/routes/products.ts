import express from 'express';
import { OpenFeature } from '@openfeature/server-sdk';

const router = express.Router();
const client = OpenFeature.getClient();

/**
 * Mock product database
 */
const products = [
  {
    id: 1,
    name: 'Laptop Pro',
    description: 'High-performance laptop',
    basePrice: 1299.99,
  },
  {
    id: 2,
    name: 'Wireless Mouse',
    description: 'Ergonomic wireless mouse',
    basePrice: 49.99,
  },
  {
    id: 3,
    name: 'Mechanical Keyboard',
    description: 'RGB mechanical keyboard',
    basePrice: 149.99,
  },
];

/**
 * GET /api/products
 *
 * Demonstrates all 5 OpenFeature flag types with evaluation context:
 * - BOOLEAN: Feature toggles
 * - STRING: Dynamic text/labels
 * - INTEGER: Numeric limits/thresholds
 * - DOUBLE: Pricing multipliers
 * - OBJECT: Complex configuration
 */
router.get('/', async (req, res) => {
  try {
    // Simulate a user session with rich context attributes
    // This will show up in the Contexts UI!
    const sessionId = req.headers['x-session-id'] as string || `session-${Date.now()}`;
    const userEmail = req.query.user as string || 'guest@example.com';
    const isPremium = req.query.premium === 'true';

    const evaluationContext = {
      targetingKey: sessionId,
      kind: 'session',
      attributes: {
        email: userEmail,
        subscriptionTier: isPremium ? 'premium' : 'free',
        country: req.headers['x-country'] as string || 'US',
        device: req.headers['user-agent']?.includes('Mobile') ? 'mobile' : 'desktop',
        timestamp: new Date().toISOString(),
        requestCount: Math.floor(Math.random() * 50) + 1,
      },
    };

    console.log('📋 Evaluation context:', evaluationContext);

    // 1. BOOLEAN FLAG: Feature toggle for checkout
    // Controls whether the "Add to Cart" button is enabled
    const checkoutEnabled = await client.getBooleanValue('enable-checkout', false, evaluationContext);
    console.log(`🎯 Boolean flag 'enable-checkout': ${checkoutEnabled}`);

    // 2. STRING FLAG: Dynamic button text
    // A/B test different call-to-action text
    const buttonText = await client.getStringValue('button-text', 'View Details', evaluationContext);
    console.log(`🎯 String flag 'button-text': ${buttonText}`);

    // 3. INTEGER FLAG: Rate limiting
    // Control API request limits dynamically
    const rateLimit = await client.getNumberValue('rate-limit', 100, evaluationContext);
    console.log(`🎯 Integer flag 'rate-limit': ${rateLimit}`);

    // 4. DOUBLE FLAG: Discount multiplier
    // Apply dynamic pricing discounts (0.0 to 1.0)
    const discountRate = await client.getNumberValue('discount-rate', 0.0, evaluationContext);
    console.log(`🎯 Double flag 'discount-rate': ${discountRate}`);

    // 5. OBJECT FLAG: Payment configuration
    // Complex feature configuration
    const paymentConfig = await client.getObjectValue('payment-config', {
      provider: 'none',
      features: [],
    }, evaluationContext);
    console.log(`🎯 Object flag 'payment-config':`, JSON.stringify(paymentConfig));

    // Apply discount to product prices
    const productsWithPricing = products.map(product => ({
      ...product,
      originalPrice: product.basePrice,
      discountedPrice: product.basePrice * (1 - discountRate),
      discount: discountRate * 100, // Convert to percentage
    }));

    // Build response with all flag-controlled features
    res.json({
      success: true,
      metadata: {
        checkoutEnabled,
        buttonText,
        rateLimit,
        discountRate,
        paymentConfig,
      },
      products: productsWithPricing,
      message: checkoutEnabled
        ? 'Checkout is enabled - happy shopping!'
        : 'Checkout is currently disabled',
    });

  } catch (error) {
    console.error('❌ Error evaluating flags:', error);

    // Graceful degradation: Return default values if flag evaluation fails
    res.status(200).json({
      success: true,
      metadata: {
        checkoutEnabled: false,
        buttonText: 'View Details',
        rateLimit: 100,
        discountRate: 0.0,
        paymentConfig: { provider: 'none', features: [] },
      },
      products: products.map(p => ({
        ...p,
        originalPrice: p.basePrice,
        discountedPrice: p.basePrice,
        discount: 0,
      })),
      message: 'Using default feature flags (Subflag unavailable)',
      error: 'Failed to evaluate feature flags',
    });
  }
});

/**
 * GET /api/products/:id
 *
 * Demonstrates per-request flag evaluation with user context
 */
router.get('/:id', async (req, res) => {
  try {
    const productId = parseInt(req.params.id);
    const product = products.find(p => p.id === productId);

    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found',
      });
    }

    // Simulate an authenticated user with rich attributes
    // This creates a "user" context type in the Contexts UI
    const userId = req.query.userId as string || `user-${Math.floor(Math.random() * 1000)}`;
    const userEmail = req.query.email as string || `${userId}@example.com`;

    const userContext = {
      targetingKey: userId,
      kind: 'user',
      attributes: {
        email: userEmail,
        name: `User ${userId.split('-')[1]}`,
        accountAge: Math.floor(Math.random() * 365) + 1, // days
        lifetimeValue: Math.floor(Math.random() * 5000),
        country: req.headers['x-country'] as string || 'US',
        isPremium: req.query.premium === 'true',
        emailVerified: true,
        lastLogin: new Date().toISOString(),
        favoriteCategory: ['electronics', 'accessories', 'peripherals'][productId - 1] || 'general',
      },
    };

    console.log(`📋 User context for product ${productId}:`, userContext);

    // Evaluate flags with user context
    const checkoutEnabled = await client.getBooleanValue('enable-checkout', false, userContext);
    const buttonText = await client.getStringValue('button-text', 'View Details', userContext);
    const discountRate = await client.getNumberValue('discount-rate', 0.0, userContext);

    res.json({
      success: true,
      product: {
        ...product,
        originalPrice: product.basePrice,
        discountedPrice: product.basePrice * (1 - discountRate),
        discount: discountRate * 100,
      },
      features: {
        checkoutEnabled,
        buttonText,
        discountRate,
      },
    });

  } catch (error) {
    console.error('❌ Error fetching product:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch product',
    });
  }
});

export default router;
