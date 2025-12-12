# Subflag React Web App Example

A production-ready React application demonstrating how to use **@subflag/openfeature-web-provider** for client-side feature flag evaluation with zero-latency lookups.

## Features

This example demonstrates:

- ✅ **All 5 OpenFeature flag types**: Boolean, String, Integer, Double, Object
- ✅ **Async initialization**: Non-blocking OpenFeature provider setup with loading states
- ✅ **Zero-latency evaluation**: Synchronous flag lookups from pre-fetched in-memory cache
- ✅ **Real-world patterns**: A/B testing, dynamic pricing, feature toggles, theme configuration
- ✅ **Error handling**: Error boundaries and graceful degradation
- ✅ **TypeScript**: Fully typed custom hooks for type-safe flag access
- ✅ **React best practices**: Custom hooks, error boundaries, clean component architecture

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
# Edit .env and add your VITE_SUBFLAG_API_KEY

# Run the dev server
pnpm dev

# Open browser to http://localhost:5173
```

## How It Works

### 1. Async Provider Initialization with Context

Unlike server-side applications, this example initializes the OpenFeature provider **asynchronously** to avoid blocking the initial render. Context is passed during initialization for targeting:

```typescript
// src/App.tsx
useEffect(() => {
  async function initializeOpenFeature() {
    const provider = new SubflagWebProvider({
      apiUrl: SUBFLAG_API_URL,
      apiKey: SUBFLAG_API_KEY,
    });

    // Set provider with initial context for targeting
    // The context is sent to the server to evaluate flags based on targeting rules
    await OpenFeature.setProviderAndWait(provider, {
      targetingKey: getSessionId(),
    });
    setIsInitialized(true);
  }

  initializeOpenFeature();
}, []);
```

The app shows a loading spinner while the provider fetches flags, then renders the main UI once ready.

### Updating Context (User Login)

When the user context changes (e.g., after login), use `OpenFeature.setContext()` to re-evaluate all flags:

```typescript
// After user logs in
await OpenFeature.setContext({
  targetingKey: user.id,
  plan: user.plan,
  email: user.email,
});
```

### 2. Zero-Latency Flag Evaluation

The `SubflagWebProvider` pre-fetches all flags on initialization and caches them in memory. This means **all flag lookups are synchronous** with zero network latency:

```typescript
// src/hooks/useFeatureFlag.ts
const client = OpenFeature.getClient();

// These calls are synchronous and instant!
const isEnabled = client.getBooleanValue('enable-checkout', false);
const buttonText = client.getStringValue('button-text', 'Buy Now');
const discount = client.getNumberValue('discount-rate', 0.0);
```

### 3. Custom Hook for Type Safety

The `useFeatureFlag` hook provides a clean, type-safe interface:

```typescript
const flags = useFeatureFlag();

const checkoutEnabled = flags.getBoolean('enable-checkout', false);
const buttonText = flags.getString('button-text', 'View Details');
const stockLimit = flags.getNumber('stock-limit', 100);
const discountRate = flags.getNumber('discount-rate', 0.0);
const themeConfig = flags.getObject('theme-config', { primaryColor: '#7c3aed' });
```

All methods include error handling and return fallback values if flag evaluation fails.

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

**pricing-variant**
- Type: `STRING`
- Variants:
  - `monthly` = `"monthly"`
  - `annual` = `"annual"`
  - `lifetime` = `"lifetime"`
- Use case: Test different pricing presentations

### 3. Integer Flags

**stock-limit**
- Type: `INTEGER`
- Variants:
  - `low` = `50`
  - `medium` = `100`
  - `high` = `500`
- Use case: Control inventory display limits

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

**theme-config**
- Type: `OBJECT`
- Variants:
  - `purple`:
    ```json
    {
      "primaryColor": "#7c3aed",
      "showBadge": true
    }
    ```
  - `green`:
    ```json
    {
      "primaryColor": "#059669",
      "showBadge": false
    }
    ```
- Use case: Dynamic theme configuration

## Code Architecture

### Component Structure

```
src/
├── main.tsx                    # App entry point (renders immediately)
├── App.tsx                     # Root component with async initialization
├── index.css                   # Global styles
├── hooks/
│   └── useFeatureFlag.ts       # Custom hook for flag evaluation
└── components/
    ├── ProductCard.tsx         # Demonstrates all 5 flag types
    ├── PricingToggle.tsx       # A/B testing with string flags
    └── ErrorBoundary.tsx       # Error handling
```

### Key Components

#### App.tsx
- Handles async OpenFeature initialization
- Shows loading state while provider fetches flags
- Displays error state if initialization fails
- Renders main UI once ready

#### useFeatureFlag.ts
- Custom React hook wrapping OpenFeature client
- Type-safe methods for each flag type
- Built-in error handling with fallback values
- Zero external dependencies (just OpenFeature SDK)

#### ProductCard.tsx
- Demonstrates all 5 flag types in a single component
- Boolean: Feature toggles (checkout enabled)
- String: Dynamic text (button labels)
- Integer: Numeric limits (stock quantity)
- Double: Pricing multipliers (discount rate)
- Object: Complex configuration (theme settings)

#### PricingToggle.tsx
- Shows A/B testing pattern with string flags
- Demonstrates how to map flag values to UI variants
- Clean, maintainable pattern for variant selection

#### ErrorBoundary.tsx
- Catches React errors and displays fallback UI
- Provides error details in development
- Graceful degradation for production

## Key Patterns

### Async Initialization with Loading State

```typescript
const [isInitialized, setIsInitialized] = useState(false);

useEffect(() => {
  async function init() {
    // Pass context during initialization for targeting
    await OpenFeature.setProviderAndWait(provider, {
      targetingKey: getSessionId(),
    });
    setIsInitialized(true);
  }
  init();
}, []);

if (!isInitialized) {
  return <LoadingSpinner />;
}
```

This ensures the UI doesn't block while flags are being fetched.

### Type-Safe Flag Evaluation

```typescript
const flags = useFeatureFlag();

// Strongly typed - TypeScript knows these are the right types
const isEnabled: boolean = flags.getBoolean('flag-key', false);
const text: string = flags.getString('flag-key', 'default');
const count: number = flags.getNumber('flag-key', 0);
const config: MyConfig = flags.getObject<MyConfig>('flag-key', defaultConfig);
```

### Error Handling with Fallbacks

```typescript
try {
  return client.getBooleanValue(flagKey, defaultValue);
} catch (error) {
  console.error(`Error evaluating flag '${flagKey}':`, error);
  return defaultValue; // Graceful degradation
}
```

### A/B Testing Pattern

```typescript
const variant = flags.getString('pricing-variant', 'control');

const config = {
  control: { price: '$29', label: 'Monthly' },
  variant_a: { price: '$290', label: 'Annual' },
  variant_b: { price: '$499', label: 'Lifetime' },
}[variant];
```

## Architecture Diagram

```
┌─────────────────────┐
│   React App         │
│   (Browser)         │
│                     │
│  ┌───────────────┐  │
│  │ useFeatureFlag│  │
│  │     Hook      │  │
│  └───────┬───────┘  │
│          │          │
│  ┌───────▼───────┐  │
│  │ OpenFeature   │  │
│  │   Client      │  │
│  └───────┬───────┘  │
│          │          │
│  ┌───────▼───────┐  │
│  │   Subflag     │  │
│  │ Web Provider  │  │
│  │ (in-memory    │  │
│  │  cache)       │  │
│  └───────┬───────┘  │
└──────────┼──────────┘
           │
      HTTP │ POST /sdk/evaluate-all (on init)
           │ X-Subflag-API-Key: sdk-...
           │
┌──────────▼──────────┐
│  Subflag Server     │
│                     │
│  - Validates API    │
│  - Returns all flags│
│  - Provider caches  │
└─────────────────────┘

After initialization, all flag
lookups are SYNCHRONOUS from cache
```

## Performance Characteristics

### Initial Load
- **One HTTP request** on initialization to fetch all flags
- Non-blocking async initialization with loading state
- Flags cached in memory for instant access

### Flag Evaluation
- **Zero network latency** - all lookups are synchronous
- O(1) lookup time from in-memory cache
- Perfect for React re-renders (no useEffect needed)

### Memory Usage
- Minimal - stores only flag keys and values
- No additional state management library needed
- Efficient for hundreds of flags

## Troubleshooting

### "VITE_SUBFLAG_API_KEY environment variable is required"
- Copy `.env.example` to `.env`
- Add your API key to the `.env` file
- Restart the dev server (`pnpm dev`)

### App stuck on loading screen
- Check browser console for errors
- Verify Subflag server is running at `http://localhost:8080`
- Confirm API key is valid and not disabled

### Flags returning default values
- Create the flags in Subflag UI
- Add variants to the flags
- Select variants for your environment (e.g., "dev")
- Ensure API key is scoped to the correct environment

### CORS errors
- Subflag server allows `localhost:5173` by default (Vite's port)
- If using a different port, update CORS config in server

### TypeScript errors
- Run `pnpm typecheck` to see all type errors
- Ensure all dependencies are installed: `pnpm install`

## Next Steps

- Explore the [Node.js/Express example](../node-express-api) for server-side flags
- Read the [Web Provider documentation](../../sdk/packages/openfeature-web-provider)
- Check out [OpenFeature documentation](https://openfeature.dev/)

## Learn More

- [Subflag Documentation](../../README.md)
- [OpenFeature Web SDK](https://openfeature.dev/docs/reference/technologies/client/web)
- [React Documentation](https://react.dev/)
- [Vite Documentation](https://vitejs.dev/)
