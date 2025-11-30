# @subflag/openfeature-web-provider

OpenFeature web provider for [Subflag](https://github.com/subflag/subflag) feature flags.

**How it works:** This provider pre-fetches all flags during initialization and serves them synchronously from an in-memory cache. Flags are fetched once when the provider is set, making flag evaluations instant with zero network latency.

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

// Initialize the provider
const provider = new SubflagWebProvider({
  apiUrl: 'http://localhost:8080',
  apiKey: 'sdk-production-my-app-your-key-here',
});

// Set provider and wait for it to be ready
await OpenFeature.setProviderAndWait(provider);

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

## Getting an API Key

See [Team Management → API Keys](https://docs.subflag.com/admin/team-management#api-keys) in the docs for instructions on creating API keys.

## How It Works: Flag Caching

The web provider uses a **pre-fetch and cache** strategy:

1. **Initialization**: When `setProviderAndWait()` is called, the provider fetches ALL flags from the server using `/sdk/evaluate-all`
2. **Caching**: All flags are stored in an in-memory Map by flag key
3. **Synchronous Evaluation**: Flag lookups are instant - no network calls during evaluation
4. **Refresh**: Call `await provider.initialize()` again to refresh the cache

This approach provides:
- ✅ **Zero-latency flag evaluations** (synchronous, no await needed)
- ✅ **Reduced server load** (one bulk request vs N individual requests)
- ✅ **Offline capability** (flags work even if server becomes unreachable)
- ⚠️ **Eventual consistency** (flags may be stale until next refresh)

## Usage with React

```typescript
import { useEffect, useState } from 'react';
import { OpenFeature } from '@openfeature/web-sdk';
import { SubflagWebProvider } from '@subflag/openfeature-web-provider';

function App() {
  const [client, setClient] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function initializeProvider() {
      try {
        const provider = new SubflagWebProvider({
          apiUrl: import.meta.env.VITE_SUBFLAG_API_URL,
          apiKey: import.meta.env.VITE_SUBFLAG_API_KEY,
        });

        // This pre-fetches all flags from the server
        await OpenFeature.setProviderAndWait(provider);
        setClient(OpenFeature.getClient());
      } catch (error) {
        console.error('Failed to initialize provider:', error);
      } finally {
        setLoading(false);
      }
    }

    initializeProvider();
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

### Refreshing Flags

To update flags without reloading the page:

```typescript
import { OpenFeature } from '@openfeature/web-sdk';

// Get the current provider
const provider = OpenFeature.getProviderForClient();

// Re-fetch all flags from the server
await provider.initialize();

// Flags are now updated in the cache
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
