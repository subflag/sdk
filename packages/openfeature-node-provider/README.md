# @subflag/openfeature-node-provider

OpenFeature Node.js provider for [Subflag](https://github.com/subflag/subflag) feature flags.

## Installation

```bash
npm install @subflag/openfeature-node-provider @openfeature/server-sdk
```

or with pnpm:

```bash
pnpm add @subflag/openfeature-node-provider @openfeature/server-sdk
```

## Quick Start

```typescript
import { OpenFeature } from '@openfeature/server-sdk';
import { SubflagNodeProvider } from '@subflag/openfeature-node-provider';

// Initialize the provider
const provider = new SubflagNodeProvider({
  apiUrl: 'http://localhost:8080',
  apiKey: 'sdk-production-my-app-your-key-here',
});

// Set provider and wait for it to be ready
await OpenFeature.setProviderAndWait(provider);

// Get a client
const client = OpenFeature.getClient();

// Evaluate flags
const isEnabled = await client.getBooleanValue('new-feature', false);
const bannerText = await client.getStringValue('banner-text', 'Welcome!');
const maxItems = await client.getNumberValue('max-items', 10);
const config = await client.getObjectValue('ui-config', { theme: 'light' });
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

## Usage with Express.js

```typescript
import express from 'express';
import { OpenFeature } from '@openfeature/server-sdk';
import { SubflagNodeProvider } from '@subflag/openfeature-node-provider';

const app = express();

// Initialize provider on startup
const provider = new SubflagNodeProvider({
  apiUrl: process.env.SUBFLAG_API_URL || 'http://localhost:8080',
  apiKey: process.env.SUBFLAG_API_KEY || '',
});

await OpenFeature.setProviderAndWait(provider);

// Get a client (can be reused across requests)
const featureClient = OpenFeature.getClient();

app.get('/api/data', async (req, res) => {
  // Check feature flag
  const usePagination = await featureClient.getBooleanValue('use-pagination', false);

  if (usePagination) {
    const pageSize = await featureClient.getNumberValue('page-size', 20);
    // Return paginated data
    res.json({ items: [], pageSize });
  } else {
    // Return all data
    res.json({ items: [] });
  }
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

## Environment Variables

Store your configuration in environment variables:

```bash
# .env
SUBFLAG_API_URL=http://localhost:8080
SUBFLAG_API_KEY=sdk-production-web-app-xQ7mK9nP2wR5tY8uI1oA3sD4
```

Then use a package like `dotenv`:

```typescript
import 'dotenv/config';
import { OpenFeature } from '@openfeature/server-sdk';
import { SubflagNodeProvider } from '@subflag/openfeature-node-provider';

const provider = new SubflagNodeProvider({
  apiUrl: process.env.SUBFLAG_API_URL!,
  apiKey: process.env.SUBFLAG_API_KEY!,
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
const value = await client.getBooleanValue('missing-flag', false);

// You can also get detailed evaluation information
const details = await client.getBooleanDetails('my-flag', false);
console.log(details.reason); // 'STATIC', 'DEFAULT', or 'ERROR'
console.log(details.variant); // Variant name (e.g., 'control', 'treatment')
console.log(details.errorCode); // Error code if reason is 'ERROR'
```

## CommonJS Support

This package supports both ESM and CommonJS:

```javascript
// ESM
import { SubflagNodeProvider } from '@subflag/openfeature-node-provider';

// CommonJS
const { SubflagNodeProvider } = require('@subflag/openfeature-node-provider');
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
