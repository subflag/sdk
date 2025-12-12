# Subflag Node.js/Express Example

A production-ready example API server demonstrating how to use **@subflag/openfeature-node-provider** for server-side feature flag evaluation with Express.js.

## Features

This example demonstrates:

- ✅ **All 5 OpenFeature flag types**: Boolean, String, Integer, Double, Object
- ✅ **Real-world patterns**: Feature toggles, A/B testing, rate limiting, dynamic pricing
- ✅ **Evaluation contexts**: User, session, and device contexts with rich attributes
- ✅ **Context tracking**: Automatic context creation and attribute tracking in Subflag UI
- ✅ **Error handling**: Graceful degradation with fallback values
- ✅ **Kill switches**: Using flags to control system availability
- ✅ **TypeScript**: Fully typed for safety and developer experience

## Prerequisites

1. **Subflag server running** at `http://localhost:8080`
   ```bash
   cd ../../server
   ./gradlew run
   ```

2. **API key created** in Subflag UI:
   - Log in to http://localhost:3000
   - Create an organization and project
   - Navigate to Applications and create an SDK key
   - Copy the API key (shown only once!)

## Quick Start

```bash
# Install dependencies
pnpm install

# Configure environment
cp .env.example .env
# Edit .env and add your SUBFLAG_API_KEY

# Run the server
pnpm dev

# Server will start at http://localhost:3001
```

## API Endpoints

### Root Endpoint
```bash
GET http://localhost:3001/
```

Returns API information and available endpoints.

### Products API
```bash
GET http://localhost:3001/api/products
```

Demonstrates all 5 flag types:
- **Boolean**: `enable-checkout` - Toggle checkout feature
- **String**: `button-text` - Dynamic button labels
- **Integer**: `rate-limit` - API rate limiting
- **Double**: `discount-rate` - Pricing discounts (0.0-1.0)
- **Object**: `payment-config` - Payment provider settings

**Example response:**
```json
{
  "success": true,
  "metadata": {
    "checkoutEnabled": true,
    "buttonText": "Buy Now",
    "rateLimit": 1000,
    "discountRate": 0.15,
    "paymentConfig": {
      "provider": "stripe",
      "features": ["applePay", "googlePay"]
    }
  },
  "products": [
    {
      "id": 1,
      "name": "Laptop Pro",
      "originalPrice": 1299.99,
      "discountedPrice": 1104.99,
      "discount": 15
    }
  ]
}
```

### Individual Product
```bash
GET http://localhost:3001/api/products/1
```

Get a single product with flag-controlled pricing and features.

### Health Check
```bash
GET http://localhost:3001/api/health
```

Demonstrates using flags as kill switches for system health management.

## Testing with curl

```bash
# Get all products with feature flags
curl http://localhost:3001/api/products

# Get single product
curl http://localhost:3001/api/products/1

# Check system health
curl http://localhost:3001/api/health
```

## Testing Evaluation Contexts

This example includes rich evaluation contexts that automatically create and track user, session, and device information in the Subflag UI.

### Quick Test - Generate Sample Contexts

Run the included test script to generate various contexts:

```bash
./test-contexts.sh
```

This will create:
- **3 session contexts** with different subscription tiers and emails
- **3 user contexts** with account data and purchase history
- **3 device contexts** from Chrome, Safari, and Firefox browsers

### View Contexts in the UI

1. Open Subflag UI at http://localhost:3000
2. Navigate to your project
3. Click **"Contexts"** in the navigation
4. You'll see all evaluation contexts with their attributes
5. Filter by kind: `user`, `session`, or `device`
6. Click **"View"** on any context to see detailed attributes

### Manual Testing with Context Attributes

```bash
# Test with premium user session
curl "http://localhost:3001/api/products?user=alice@example.com&premium=true" \
  -H "X-Session-ID: session-premium-test" \
  -H "X-Country: CA"

# Test with specific user context
curl "http://localhost:3001/api/products/2?userId=user-123&email=bob@example.com&premium=false" \
  -H "X-Country: US"

# Test with mobile device context
curl http://localhost:3001/api/health \
  -H "X-Device-ID: my-iphone" \
  -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)" \
  -H "X-Screen-Resolution: 390x844"
```

### Context Attributes by Endpoint

**GET /api/products** → Creates **session** contexts with:
- `email` - User email
- `subscriptionTier` - "premium" or "free"
- `country` - User's country
- `device` - "mobile" or "desktop"
- `timestamp` - Request timestamp
- `requestCount` - Simulated request counter

**GET /api/products/:id** → Creates **user** contexts with:
- `email` - User email
- `name` - User display name
- `accountAge` - Account age in days
- `lifetimeValue` - Total customer value
- `country` - User's country
- `isPremium` - Premium subscription status
- `emailVerified` - Email verification status
- `lastLogin` - Last login timestamp
- `favoriteCategory` - Product category preference

**GET /api/health** → Creates **device** contexts with:
- `userAgent` - Full user agent string
- `platform` - OS (Windows, Mac, Linux)
- `browser` - Browser name (Chrome, Firefox, Safari)
- `isMobile` - Mobile device flag
- `screenResolution` - Screen resolution
- `language` - Browser language

## Creating Flags in Subflag

To see this example in action, create the following flags in your Subflag project:

### 1. Boolean Flags

**enable-checkout**
- Type: `BOOLEAN`
- Variants:
  - `enabled` = `true`
  - `disabled` = `false`
- Use case: Toggle checkout feature on/off

### 2. String Flags

**button-text**
- Type: `STRING`
- Variants:
  - `buy-now` = `"Buy Now"`
  - `add-to-cart` = `"Add to Cart"`
  - `purchase` = `"Purchase"`
- Use case: A/B test different call-to-action text

### 3. Integer Flags

**rate-limit**
- Type: `INTEGER`
- Variants:
  - `low` = `100`
  - `medium` = `1000`
  - `high` = `10000`
- Use case: Dynamic API rate limiting

### 4. Double Flags

**discount-rate**
- Type: `DOUBLE`
- Variants:
  - `no-discount` = `0.0`
  - `small` = `0.1` (10% off)
  - `medium` = `0.25` (25% off)
  - `large` = `0.5` (50% off)
- Use case: Dynamic pricing and promotions

### 5. Object Flags

**payment-config**
- Type: `OBJECT`
- Variants:
  - `stripe`:
    ```json
    {
      "provider": "stripe",
      "publicKey": "pk_test_...",
      "features": ["applePay", "googlePay"]
    }
    ```
  - `paypal`:
    ```json
    {
      "provider": "paypal",
      "clientId": "client_id_...",
      "features": ["paypalCheckout"]
    }
    ```
- Use case: Complex feature configuration

## Code Walkthrough

### 1. Provider Initialization (src/index.ts)

```typescript
import { OpenFeature } from '@openfeature/server-sdk';
import { SubflagNodeProvider } from '@subflag/openfeature-node-provider';

const provider = new SubflagNodeProvider({
  apiUrl: process.env.SUBFLAG_API_URL,
  apiKey: process.env.SUBFLAG_API_KEY,
});

await OpenFeature.setProviderAndWait(provider);
```

### 2. Flag Evaluation (src/routes/products.ts)

```typescript
const client = OpenFeature.getClient();

// Boolean flag
const checkoutEnabled = await client.getBooleanValue('enable-checkout', false);

// String flag
const buttonText = await client.getStringValue('button-text', 'View Details');

// Number flags (Integer or Double)
const rateLimit = await client.getNumberValue('rate-limit', 100);
const discountRate = await client.getNumberValue('discount-rate', 0.0);

// Object flag
const paymentConfig = await client.getObjectValue('payment-config', {
  provider: 'none',
  features: [],
});
```

### 3. Error Handling

The example demonstrates graceful degradation:

```typescript
try {
  const checkoutEnabled = await client.getBooleanValue('enable-checkout', false);
  // Use the flag value...
} catch (error) {
  console.error('Error evaluating flags:', error);
  // Application continues with fallback values
  const checkoutEnabled = false; // Safe default
}
```

## Architecture

```
┌─────────────────────┐
│  Express Server     │
│                     │
│  ┌───────────────┐  │
│  │ OpenFeature   │  │
│  │   Client      │  │
│  └───────┬───────┘  │
│          │          │
│  ┌───────▼───────┐  │
│  │   Subflag     │  │
│  │ Node Provider │  │
│  └───────┬───────┘  │
└──────────┼──────────┘
           │
      HTTP │ POST /sdk/evaluate/{flagKey}
           │ X-Subflag-API-Key: sdk-...
           │
┌──────────▼──────────┐
│  Subflag Server     │
│                     │
│  - Validates API    │
│  - Evaluates flags  │
│  - Returns variant  │
└─────────────────────┘
```

## Key Concepts

### OpenFeature Client

The `@openfeature/server-sdk` provides a standard interface for flag evaluation:

```typescript
const client = OpenFeature.getClient();

// Type-safe evaluation methods
await client.getBooleanValue(flagKey, defaultValue);
await client.getStringValue(flagKey, defaultValue);
await client.getNumberValue(flagKey, defaultValue);
await client.getObjectValue(flagKey, defaultValue);
```

### Subflag Node Provider

The `@subflag/openfeature-node-provider` implements the OpenFeature provider interface:

- Makes HTTP requests to Subflag server
- Authenticates with API key
- Handles errors and returns fallback values
- Suitable for server-side applications

### Flag Evaluation Flow

1. Your code calls `client.getBooleanValue('enable-checkout', false)`
2. OpenFeature routes to SubflagNodeProvider
3. Provider makes POST to `/sdk/evaluate/enable-checkout`
4. Subflag server validates API key and evaluates flag
5. Server returns selected variant for the environment
6. Provider returns the value to your code

If any step fails, the default value (`false`) is returned.

## Common Patterns

### Feature Toggle
```typescript
const newFeatureEnabled = await client.getBooleanValue('new-feature', false);

if (newFeatureEnabled) {
  // New implementation
} else {
  // Old implementation
}
```

### A/B Testing
```typescript
const variant = await client.getStringValue('button-variant', 'control');

const buttonText = {
  control: 'Buy Now',
  variant_a: 'Add to Cart',
  variant_b: 'Purchase',
}[variant];
```

### Dynamic Configuration
```typescript
const config = await client.getObjectValue('feature-config', {
  enabled: false,
  settings: {},
});

if (config.enabled) {
  configureFeature(config.settings);
}
```

### Kill Switch
```typescript
const apiEnabled = await client.getBooleanValue('api-enabled', true);

if (!apiEnabled) {
  return res.status(503).json({ message: 'Service temporarily unavailable' });
}
```

## Troubleshooting

### "SUBFLAG_API_KEY environment variable is required"
- Copy `.env.example` to `.env`
- Add your API key to the `.env` file

### "Failed to initialize OpenFeature provider"
- Ensure Subflag server is running at `http://localhost:8080`
- Verify your API key is valid
- Check that the API key hasn't been disabled

### Flags returning default values
- Create the flags in Subflag UI
- Add variants to the flags
- Select variants for your environment (e.g., "dev")
- Ensure API key is scoped to the correct environment

### Connection refused errors
- Check `SUBFLAG_API_URL` in `.env` matches your server
- Verify Subflag server is running: `curl http://localhost:8080/api/health`

## Next Steps

- Explore the [React Web App example](../react-web-app) for client-side flags
- Read the [Node Provider documentation](../../sdk/packages/openfeature-node-provider)
- Check out [OpenFeature documentation](https://openfeature.dev/)

## Learn More

- [Subflag Documentation](../../README.md)
- [OpenFeature Server SDK](https://openfeature.dev/docs/reference/concepts/provider)
- [Express.js Documentation](https://expressjs.com/)
