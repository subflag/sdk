# Subflag SDKs

[![npm @subflag/openfeature-web-provider](https://img.shields.io/npm/v/@subflag/openfeature-web-provider?label=web-provider)](https://www.npmjs.com/package/@subflag/openfeature-web-provider)
[![npm @subflag/openfeature-node-provider](https://img.shields.io/npm/v/@subflag/openfeature-node-provider?label=node-provider)](https://www.npmjs.com/package/@subflag/openfeature-node-provider)
[![gem subflag-openfeature-provider](https://img.shields.io/gem/v/subflag-openfeature-provider?label=ruby-provider)](https://rubygems.org/gems/subflag-openfeature-provider)

Official [OpenFeature](https://openfeature.dev)-compliant SDKs for [Subflag](https://subflag.com) feature flag management.

## Packages

| Package | Language | Install |
|---------|----------|---------|
| [@subflag/openfeature-web-provider](./packages/openfeature-web-provider) | TypeScript/JavaScript | `npm install @subflag/openfeature-web-provider` |
| [@subflag/openfeature-node-provider](./packages/openfeature-node-provider) | TypeScript/JavaScript | `npm install @subflag/openfeature-node-provider` |
| [subflag-openfeature-provider](./packages/openfeature-ruby-provider) | Ruby | `gem install subflag-openfeature-provider` |
| [@subflag/api-types](./packages/api-types) | TypeScript | `npm install @subflag/api-types` |

## Quick Start

### Web/Browser (React, Vue, vanilla JS)

```bash
npm install @subflag/openfeature-web-provider @openfeature/web-sdk
```

```typescript
import { OpenFeature } from '@openfeature/web-sdk';
import { SubflagWebProvider } from '@subflag/openfeature-web-provider';

const provider = new SubflagWebProvider({
  apiUrl: 'https://api.subflag.com',
  apiKey: 'sdk-prod-...',
});

await OpenFeature.setProviderAndWait(provider);
const client = OpenFeature.getClient();

// Flags are cached - synchronous evaluation, no network call
const enabled = client.getBooleanValue('new-feature', false);
```

### Node.js/Server (Express, Fastify, etc.)

```bash
npm install @subflag/openfeature-node-provider @openfeature/server-sdk
```

```typescript
import { OpenFeature } from '@openfeature/server-sdk';
import { SubflagNodeProvider } from '@subflag/openfeature-node-provider';

const provider = new SubflagNodeProvider({
  apiUrl: 'https://api.subflag.com',
  apiKey: 'sdk-prod-...',
});

await OpenFeature.setProviderAndWait(provider);
const client = OpenFeature.getClient();

// Each evaluation makes an API call - always gets latest value
const enabled = await client.getBooleanValue('new-feature', false);
```

### Ruby (Rails, Sinatra, etc.)

```bash
gem install subflag-openfeature-provider openfeature-sdk
```

```ruby
require "openfeature/sdk"
require "subflag"

provider = Subflag::Provider.new(
  api_url: "https://api.subflag.com",
  api_key: "sdk-prod-..."
)

OpenFeature::SDK.configure do |config|
  config.set_provider(provider)
end

client = OpenFeature::SDK.build_client
enabled = client.fetch_boolean_value(flag_key: "new-feature", default_value: false)
```

## What is OpenFeature?

[OpenFeature](https://openfeature.dev/) is an open standard for feature flag management, providing:

- **Vendor-neutral API** — Switch providers without changing application code
- **Standardized evaluation** — Consistent flag evaluation across platforms
- **Ecosystem integration** — Works with existing hooks, extensions, and tooling

## Supported Flag Types

All providers support the five OpenFeature value types:

| Type | TypeScript | Ruby |
|------|------------|------|
| Boolean | `getBooleanValue()` | `fetch_boolean_value()` |
| String | `getStringValue()` | `fetch_string_value()` |
| Integer | `getNumberValue()` | `fetch_integer_value()` |
| Float | `getNumberValue()` | `fetch_float_value()` |
| Object | `getObjectValue()` | `fetch_object_value()` |

## Getting Started with Subflag

1. **Sign up** at [subflag.com](https://subflag.com)
2. **Create a project** with environments (dev, staging, production)
3. **Create feature flags** and configure variants
4. **Generate an API key** (Settings → Applications → Create)
5. **Install an SDK** and start evaluating flags

API keys follow the format `sdk-{environment}-{app-name}-{random}` and are scoped to a specific project and environment.

## Documentation

- [Subflag Documentation](https://docs.subflag.com)
- [OpenFeature Specification](https://openfeature.dev/specification)

## Development

```bash
# Install dependencies
pnpm install

# Build all packages
pnpm build

# Run tests
pnpm test

# Type check
pnpm typecheck
```

### Project Structure

```
packages/
├── openfeature-web-provider/     # Browser/client-side provider
├── openfeature-node-provider/    # Node.js server provider
├── openfeature-ruby-provider/    # Ruby provider
└── api-types/                    # Shared TypeScript types
```

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

MIT
