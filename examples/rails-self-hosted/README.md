# Subflag Rails Self-Hosted Example

Self-hosted feature flags with ActiveRecord backend and admin UI.

No external dependencies — flags are stored in your database.

## Quick Start

```bash
bundle install
bin/rails db:migrate
bin/rails db:seed
bin/rails server -p 3001
```

## Admin UI

Visit **http://localhost:3001/subflag** to:

- Create, edit, and delete flags
- Toggle flags on/off
- Build targeting rules visually
- Test rules against sample contexts

## Targeting Rules

The seed data includes flags with targeting rules:

| Flag | Default | Targeting |
|------|---------|-----------|
| `button-text` | "Buy Now" | "🚀 Ship It!" for @company.com emails or admin/developer/qa roles |
| `rate-limit` | 100 | 10000 for admins, 1000 for enterprise, 500 for pro |
| `discount-rate` | 0.0 | 0.2 (20% off) for @company.com emails |
| `premium-features` | false | true for pro/enterprise plans or admin role |

## API Endpoints

```bash
curl http://localhost:3001/
curl http://localhost:3001/api/products
curl http://localhost:3001/api/products/1
curl http://localhost:3001/api/health
```

## How It Works

1. **No API key needed** — flags are in your local SQLite database
2. **Targeting rules** — JSON stored in `targeting_rules` column
3. **Admin UI** — Rails engine mounted at `/subflag`

## Files

- `config/initializers/subflag.rb` — Backend config + user context
- `config/routes.rb` — Mounts the admin UI engine
- `db/seeds.rb` — Sample flags with targeting rules

## Security

In production, secure the admin UI:

```ruby
# config/initializers/subflag.rb
Subflag::Rails.configure do |config|
  config.admin_auth do
    redirect_to main_app.root_path unless current_user&.admin?
  end
end
```
