# @subflag/openfeature-web-provider

OpenFeature web provider for [Subflag](https://github.com/subflag/subflag) feature flags.

**How it works:** This provider pre-fetches all flags during initialization and serves them synchronously from an in-memory cache. Flags are re-fetched automatically when you update context via `OpenFeature.setContext()`.

## Installation

```bash
npm install @subflag/openfeature-web-provider @openfeature/web-sdk
```

or with pnpm:

```bash
pnpm add @subflag/openfeature-web-provider @openfeature/web-sdk
```

## Quick Start

```typescript
import { OpenFeature } from '@openfeature/web-sdk';
import { SubflagWebProvider } from '@subflag/openfeature-web-provider';

// Create the provider
const provider = new SubflagWebProvider({
  apiUrl: 'http://localhost:8080',
  apiKey: 'sdk-production-my-app-your-key-here',
});

// Set provider with initial context for targeting
await OpenFeature.setProviderAndWait(provider, {
  targetingKey: 'user-123',  // Unique identifier for this user/session
  plan: 'premium',           // Custom attributes for targeting rules
  country: 'US',
});

// Get a client
const client = OpenFeature.getClient();

// Evaluate flags - synchronous, no network call!
const isEnabled = client.getBooleanValue('new-feature', false);
const bannerText = client.getStringValue('banner-text', 'Welcome!');
const maxItems = client.getNumberValue('max-items', 10);
const config = client.getObjectValue('ui-config', { theme: 'light' });
```

## Configuration

### SubflagProviderConfig

| Option | Type | Required | Description |
|--------|------|----------|-------------|
| `apiUrl` | `string` | Yes | The Subflag API URL (e.g., `"http://localhost:8080"`) |
| `apiKey` | `string` | Yes | Your SDK API key (format: `sdk-{env}-{random}`) |
| `timeout` | `number` | No | Request timeout in milliseconds (default: 5000) |

### Evaluation Context

Context is set via OpenFeature's standard API, not the provider config. Common context fields:

| Field | Type | Description |
|-------|------|-------------|
| `targetingKey` | `string` | Unique identifier for the context (user ID, session ID, etc.) |
| Any custom field | `any` | Custom attributes for targeting rules (plan, country, etc.) |

## Getting an API Key

See [Team Management → API Keys](https://docs.subflag.com/admin/team-management#api-keys) in the docs for instructions on creating API keys.

## How It Works: Flag Caching

The web provider uses a **pre-fetch and cache** strategy:

1. **Initialization**: When `setProviderAndWait()` is called, the provider fetches ALL flags from the server using `/sdk/evaluate-all` with the provided context
2. **Caching**: All flags are stored in an in-memory Map by flag key
3. **Synchronous Evaluation**: Flag lookups are instant - no network calls during evaluation
4. **Context Changes**: When `OpenFeature.setContext()` is called, flags are automatically re-fetched with the new context

This approach provides:
- ✅ **Zero-latency flag evaluations** (synchronous, no await needed)
- ✅ **Reduced server load** (one bulk request vs N individual requests)
- ✅ **Targeting support** (context is used to evaluate segments and rollouts)
- ✅ **Offline capability** (flags work even if server becomes unreachable)
- ⚠️ **Eventual consistency** (flags may be stale until next context change)

## Usage with React

```typescript
import { useEffect, useState, useCallback } from 'react';
import { OpenFeature } from '@openfeature/web-sdk';
import { SubflagWebProvider } from '@subflag/openfeature-web-provider';

// Generate or retrieve a session ID for anonymous users
function getSessionId(): string {
  const key = 'subflag_session_id';
  let sessionId = sessionStorage.getItem(key);
  if (!sessionId) {
    sessionId = `session-${crypto.randomUUID()}`;
    sessionStorage.setItem(key, sessionId);
  }
  return sessionId;
}

function App() {
  const [client, setClient] = useState(null);
  const [loading, setLoading] = useState(true);

  // Initialize provider with anonymous session context
  useEffect(() => {
    async function initializeProvider() {
      try {
        const provider = new SubflagWebProvider({
          apiUrl: import.meta.env.VITE_SUBFLAG_API_URL,
          apiKey: import.meta.env.VITE_SUBFLAG_API_KEY,
        });

        // Set provider with initial anonymous context
        await OpenFeature.setProviderAndWait(provider, {
          targetingKey: getSessionId(),
        });

        setClient(OpenFeature.getClient());
      } catch (error) {
        console.error('Failed to initialize provider:', error);
      } finally {
        setLoading(false);
      }
    }

    initializeProvider();
  }, []);

  // Update context when user logs in
  const handleLogin = useCallback(async (user: User) => {
    await OpenFeature.setContext({
      targetingKey: user.id,
      plan: user.plan,
      email: user.email,
    });
  }, []);

  // Revert to anonymous context on logout
  const handleLogout = useCallback(async () => {
    await OpenFeature.setContext({
      targetingKey: getSessionId(),
    });
  }, []);

  if (loading) return <div>Loading flags...</div>;
  if (!client) return <div>Error loading flags</div>;

  return <FeatureGatedComponent client={client} />;
}

function FeatureGatedComponent({ client }) {
  // Flags are evaluated synchronously from cache - no await needed!
  const enabled = client.getBooleanValue('new-feature', false);

  return enabled ? <NewFeature /> : <OldFeature />;
}
```

### Updating Context (User Login, Plan Changes, etc.)

When the user context changes (e.g., after login, plan upgrade), use `OpenFeature.setContext()` to re-evaluate all flags:

```typescript
// Initialize provider first
const provider = new SubflagWebProvider({ apiUrl, apiKey });
await OpenFeature.setProviderAndWait(provider);

// Later, when user logs in...
await OpenFeature.setContext({
  targetingKey: user.id,
  plan: user.plan,
  email: user.email,
  country: user.country,
});

// Flags are now re-evaluated for this user
const premiumFeature = client.getBooleanValue('premium-feature', false);
```

### Clearing Context (User Logout)

```typescript
// Revert to anonymous session context when user logs out
await OpenFeature.setContext({
  targetingKey: getSessionId(),
});
```

## Supported Flag Types

The provider supports all OpenFeature value types:

- **Boolean**: `getBooleanValue(flagKey, defaultValue)`
- **String**: `getStringValue(flagKey, defaultValue)`
- **Number**: `getNumberValue(flagKey, defaultValue)`
- **Object**: `getObjectValue(flagKey, defaultValue)`

## Error Handling

The provider handles errors gracefully and returns default values when:

- The flag doesn't exist (404)
- The API key is invalid (401/403)
- Network errors occur
- The flag value type doesn't match the requested type

```typescript
const client = OpenFeature.getClient();

// If 'missing-flag' doesn't exist, returns false
const value = client.getBooleanValue('missing-flag', false);

// You can also get detailed evaluation information
const details = client.getBooleanDetails('my-flag', false);
console.log(details.reason); // 'STATIC', 'DEFAULT', or 'ERROR'
console.log(details.variant); // Variant name (e.g., 'control', 'treatment')
console.log(details.errorCode); // Error code if reason is 'ERROR'
```

## Development

```bash
# Install dependencies
pnpm install

# Build the provider
pnpm build

# Run tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Type check
pnpm typecheck
```

## License

MIT
