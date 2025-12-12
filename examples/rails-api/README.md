# Subflag Rails API Example

Feature flags in Ruby on Rails using [subflag-rails](../../sdk/packages/subflag-rails).

## Quick Start

```bash
bundle install
cp .env.example .env
# Add your SUBFLAG_API_KEY to .env
bin/rails server -p 3002
```

## Endpoints

```bash
curl http://localhost:3002/
curl http://localhost:3002/api/products
curl http://localhost:3002/api/products/1
curl http://localhost:3002/api/health
```

## Flags Used

| Flag | Type |
|------|------|
| `enable-checkout` | Boolean |
| `button-text` | String |
| `rate-limit` | Integer |
| `discount-rate` | Double |
| `payment-config` | Object |
| `premium-features` | Boolean |
| `api-enabled` | Boolean |
| `maintenance-mode` | Boolean |
