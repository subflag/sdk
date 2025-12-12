# Subflag Examples

This directory contains example applications demonstrating how to use Subflag's OpenFeature SDK providers in real-world scenarios.

## Available Examples

### 1. [Node.js/Express API Server](./node-express-api)
A backend API server demonstrating server-side feature flag evaluation using `@subflag/openfeature-node-provider`.

**Demonstrates:**
- Express.js integration with OpenFeature
- All 5 flag types (boolean, string, integer, double, object)
- Feature-gated API endpoints
- Error handling and fallback patterns
- Middleware for flag evaluation

**Use cases:**
- Feature toggles for API endpoints
- Dynamic rate limiting
- A/B testing backend logic
- Configuration management

### 2. [React Web App](./react-web-app)
A frontend web application demonstrating client-side feature flag evaluation using `@subflag/openfeature-web-provider`.

**Demonstrates:**
- React + Vite integration with OpenFeature
- Custom React hooks for type-safe flag access
- All 5 flag types in UI components
- Error boundaries and graceful degradation
- Loading states and fallback values

**Use cases:**
- Feature-gated UI components
- A/B testing UI variants
- Dynamic pricing display
- Theme and styling configuration

### 3. [Rails API](./rails-api)
A Ruby on Rails API demonstrating server-side feature flags using `subflag-rails`.

**Demonstrates:**
- Rails integration with `subflag_enabled?` and `subflag_value` helpers
- All 5 flag types in controllers
- Kill switches for maintenance mode
- User targeting configuration

**Use cases:**
- Feature toggles in Rails controllers
- Dynamic pricing and rate limiting
- Maintenance mode and kill switches
- Per-user feature rollouts

## Prerequisites

Before running these examples, you need:

1. **Subflag Server Running**
   ```bash
   cd server
   ./gradlew run
   ```
   Server should be accessible at `http://localhost:8080`

2. **Database Setup**
   - PostgreSQL running with Subflag schema
   - Or use the seeded development database:
     ```bash
     cd server
     ./gradlew seedDatabase
     ```

3. **API Key Created**
   - Log in to the Subflag web UI at `http://localhost:3000`
   - Create an organization and project
   - Navigate to Applications and create an SDK key
   - Copy the API key (shown only once!)

4. **Node.js & pnpm** (for Node/React examples)
   - Node.js 18+
   - pnpm 8+ (`npm install -g pnpm`)

5. **Ruby & Bundler** (for Rails example)
   - Ruby 3.1+
   - Bundler 2+ (`gem install bundler`)

## Quick Start

### Node.js/Express Example

```bash
# Navigate to the example
cd examples/node-express-api

# Install dependencies
pnpm install

# Configure environment
cp .env.example .env
# Edit .env and add your API key

# Run the server
pnpm dev

# Test the API
curl http://localhost:3001/api/products
```

### React Web App Example

```bash
# Navigate to the example
cd examples/react-web-app

# Install dependencies
pnpm install

# Configure environment
cp .env.example .env
# Edit .env and add your API key

# Run the dev server
pnpm dev

# Open browser to http://localhost:5173
```

### Rails API Example

```bash
# Navigate to the example
cd examples/rails-api

# Install dependencies
bundle install

# Configure environment
cp .env.example .env
# Edit .env and add your API key

# Run the server
bin/rails server -p 3002

# Test the API
curl http://localhost:3002/api/products
```

## Creating Flags for Examples

To get the most out of these examples, create the following flags in your Subflag project:

### Boolean Flags
- `enable-checkout` - Toggle checkout feature on/off
- `show-beta-banner` - Display beta features banner

### String Flags
- `button-text` - Dynamic button text (variants: "Buy Now", "Add to Cart", "Purchase")
- `hero-title` - Homepage hero title text

### Integer Flags
- `rate-limit` - API rate limit per minute (e.g., 100, 1000)
- `items-per-page` - Pagination size (e.g., 10, 25, 50)

### Double Flags
- `discount-rate` - Pricing discount multiplier (e.g., 0.1, 0.25, 0.5)
- `shipping-multiplier` - Shipping cost adjustment

### Object Flags
- `payment-config` - Payment provider settings
  ```json
  {
    "provider": "stripe",
    "publicKey": "pk_test_...",
    "features": ["applePay", "googlePay"]
  }
  ```
- `theme-config` - UI theme configuration
  ```json
  {
    "primaryColor": "#7c3aed",
    "darkMode": true,
    "borderRadius": "lg"
  }
  ```

## Architecture Overview

Both examples follow the same pattern:

```
┌─────────────────┐
│   Your App      │
│                 │
│  ┌───────────┐  │
│  │OpenFeature│  │
│  │   SDK     │  │
│  └─────┬─────┘  │
│        │        │
│  ┌─────▼──────┐ │
│  │  Subflag   │ │
│  │  Provider  │ │
│  └─────┬──────┘ │
└────────┼────────┘
         │
    HTTP │ (with API key)
         │
┌────────▼────────┐
│ Subflag Server  │
│                 │
│  - Evaluates    │
│  - Returns      │
│    variants     │
└─────────────────┘
```

## Key Concepts

### OpenFeature Standard
Both examples use the [OpenFeature](https://openfeature.dev/) standard for feature flagging. This means:
- **Provider-agnostic**: Switch between Subflag, LaunchDarkly, Split.io without changing application code
- **Vendor-neutral API**: Standard methods like `getBooleanValue()`, `getStringValue()`
- **Type-safe**: Strong typing for all flag evaluations

### Subflag Providers

**Node Provider** (`@subflag/openfeature-node-provider`):
- Makes HTTP requests to Subflag server for each evaluation
- Suitable for server-side applications
- Real-time flag updates (no caching by default)

**Web Provider** (`@subflag/openfeature-web-provider`):
- Pre-fetches all flags on initialization
- Zero-latency synchronous evaluation from in-memory cache
- Suitable for browser applications
- Refresh capability for manual updates

### Error Handling

Both examples demonstrate:
- **Fallback values**: Default values when flags fail to evaluate
- **Graceful degradation**: Application continues working even if Subflag is unreachable
- **Error logging**: Visibility into flag evaluation failures
- **Type safety**: TypeScript prevents runtime type errors

## Common Issues

### "API key not found" error
- Ensure your API key is correctly set in `.env`
- Verify the API key hasn't been disabled in Subflag UI
- Check that the API key has access to the project/environment

### "Connection refused" error
- Verify Subflag server is running on `http://localhost:8080`
- Check `SUBFLAG_API_URL` in `.env` matches your server URL

### Flags returning default values
- Ensure flags exist in your Subflag project
- Verify flags have variants created
- Check that variants are selected for the target environment
- Confirm API key is scoped to the correct environment

### CORS errors (web example)
- Subflag server allows `localhost:3000` and `localhost:3001` by default
- If running on a different port, update CORS config in `server/app/src/main/kotlin/com/subflag/utils/CORSConfiguration.kt`

## Learn More

- [Subflag Documentation](../README.md)
- [OpenFeature Documentation](https://openfeature.dev/)
- [Node Provider README](../sdk/packages/openfeature-node-provider/README.md)
- [Web Provider README](../sdk/packages/openfeature-web-provider/README.md)

## Contributing

Found an issue or want to improve these examples? PRs welcome!

## License

MIT
