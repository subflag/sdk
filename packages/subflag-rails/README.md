# Subflag Rails

Typed feature flags for Rails. Booleans, strings, numbers, and JSON — with pluggable backends.

[Subflag](https://subflag.com)

## Backends

Choose where your flags live:

| Backend | Use Case | Flags Stored In |
|---------|----------|-----------------|
| `:subflag` | Production with dashboard, environments, targeting | Subflag Cloud |
| `:active_record` | Self-hosted, no external dependencies, [built-in admin UI](#admin-ui-activerecord) | Your database |
| `:memory` | Testing and development | In-memory hash |

**Same API regardless of backend:**

```ruby
subflag_enabled?(:new_checkout)           # Works with any backend
subflag_value(:max_projects, default: 3)  # Works with any backend
```

## Installation

Add to your Gemfile:

```ruby
gem 'subflag-rails'

# If using Subflag Cloud (backend: :subflag), also add:
gem 'subflag-openfeature-provider'
```

### Option 1: Subflag Cloud (Default)

Dashboard, environments, percentage rollouts, and user targeting.

```bash
rails generate subflag:install
```

Add your API key to Rails credentials:

```bash
rails credentials:edit
```

```yaml
subflag:
  api_key: sdk-production-your-key-here
```

Or set the `SUBFLAG_API_KEY` environment variable.

### Option 2: ActiveRecord (Self-Hosted)

Flags stored in your database. No external dependencies.

```bash
rails generate subflag:install --backend=active_record
rails db:migrate
```

Create flags directly:

```ruby
Subflag::Rails::Flag.create!(key: "new-checkout", value: "true", value_type: "boolean")
Subflag::Rails::Flag.create!(key: "max-projects", value: "100", value_type: "integer")
Subflag::Rails::Flag.create!(key: "welcome-message", value: "Hello!", value_type: "string")
```

### Option 3: Memory (Testing)

In-memory flags for tests and local development.

```bash
rails generate subflag:install --backend=memory
```

Set flags programmatically:

```ruby
Subflag::Rails.provider.set(:new_checkout, true)
Subflag::Rails.provider.set(:max_projects, 100)
```

## Usage

### Controllers & Views

Helpers are automatically available and scoped to `current_user`:

```ruby
# Controller
class ProjectsController < ApplicationController
  def index
    if subflag_enabled?(:new_dashboard)
      # show new dashboard
    end

    @max_projects = subflag_value(:max_projects, default: 3)
  end
end
```

```erb
<!-- View -->
<% if subflag_enabled?(:new_checkout) %>
  <%= render "new_checkout" %>
<% end %>

<h1><%= subflag_value(:headline, default: "Welcome") %></h1>

<p>You can create <%= subflag_value(:max_projects, default: 3) %> projects</p>
```

### Flag Accessor DSL

For multiple flag checks, use the flag accessor:

```ruby
flags = subflag_for  # auto-scoped to current_user

if flags.beta_feature?
  headline = flags.welcome_message(default: "Hello!")
  max = flags.max_projects(default: 3)
end
```

Or use `Subflag.flags` directly:

```ruby
# With user context
flags = Subflag.flags(user: current_user)
flags.new_checkout?              # => true/false
flags.max_projects(default: 3)   # => 100

# Bracket access for exact flag names
flags["my-exact-flag", default: "value"]

# Full evaluation details
result = flags.evaluate(:max_projects, default: 3)
result.value    # => 100
result.variant  # => "premium"
result.reason   # => :targeting_match
```

### Flag Types

The default value determines the expected type:

```ruby
# Boolean (? suffix, default optional)
subflag_enabled?(:new_checkout)           # default: false
subflag_enabled?(:new_checkout, default: true)

# String
subflag_value(:headline, default: "Welcome")

# Integer
subflag_value(:max_projects, default: 3)

# Float
subflag_value(:tax_rate, default: 0.08)

# Hash/Object
subflag_value(:feature_limits, default: { max_items: 10 })
```

### User Targeting

Configure how to extract context from user objects:

```ruby
# config/initializers/subflag.rb
Subflag::Rails.configure do |config|
  config.user_context do |user|
    {
      targeting_key: user.id.to_s,
      email: user.email,
      plan: user.subscription&.plan_name || "free",
      admin: user.admin?
    }
  end
end
```

Now flags can return different values based on user attributes:

```ruby
# In Subflag dashboard: max-projects returns 3 for "free", 100 for "premium"
subflag_value(:max_projects, default: 3)  # => 3 or 100 based on user's plan
```

### Override User Context

```ruby
# No user context
subflag_enabled?(:public_feature, user: nil)

# Different user
subflag_value(:max_projects, user: admin_user, default: 3)
```

## Flag Naming

Flag names use lowercase letters, numbers, and dashes:
- Valid: `new-checkout`, `max-api-requests`, `feature1`
- Invalid: `new_checkout`, `NewCheckout`, `my flag`

In Ruby, use underscores — they're automatically converted to dashes:

```ruby
subflag_enabled?(:new_checkout)  # looks up "new-checkout"
```

## Request Caching

Enable per-request caching to avoid multiple API calls for the same flag:

```ruby
# config/application.rb
config.middleware.use Subflag::Rails::RequestCache::Middleware
```

Now multiple checks for the same flag in one request hit the API only once:

```ruby
# Without caching: 3 API calls
# With caching: 1 API call (cached for subsequent checks)
subflag_enabled?(:new_checkout)  # API call
subflag_enabled?(:new_checkout)  # Cache hit
subflag_enabled?(:new_checkout)  # Cache hit
```

## Cross-Request Caching

By default, prefetched flags are only cached for the current request. To cache across multiple requests using `Rails.cache`, set a TTL:

```ruby
# config/initializers/subflag.rb
Subflag::Rails.configure do |config|
  config.api_key = Rails.application.credentials.subflag_api_key
  config.cache_ttl = 30.seconds  # Cache flags in Rails.cache for 30 seconds
end
```

With `cache_ttl` set:
- First request fetches from API and stores in `Rails.cache`
- Subsequent requests (within TTL) read from `Rails.cache` — no API call
- After TTL expires, next request fetches fresh data

This significantly reduces API load for high-traffic applications. Choose a TTL that balances freshness with performance — 30 seconds is a good starting point.

## Bulk Flag Evaluation (Prefetch)

For optimal performance, prefetch all flags for a user in a single API call. This is especially useful when your page checks multiple flags:

```ruby
# config/application.rb (required)
config.middleware.use Subflag::Rails::RequestCache::Middleware
```

```ruby
class ApplicationController < ActionController::Base
  before_action :prefetch_feature_flags

  private

  def prefetch_feature_flags
    subflag_prefetch  # Fetches all flags for current_user in one API call
  end
end
```

Now all subsequent flag lookups use the cache — no additional API calls:

```ruby
# In your controller/view - all lookups are instant (cache hits)
subflag_enabled?(:new_checkout)           # Cache hit
subflag_value(:max_projects, default: 3)  # Cache hit
subflag_value(:headline, default: "Hi")   # Cache hit
```

### How It Works

1. **Single API call**: `subflag_prefetch` calls `/sdk/evaluate-all` to fetch all flags
2. **Per-request cache**: Results are stored in `RequestCache` for the duration of the request
3. **Zero-latency lookups**: Subsequent `subflag_enabled?` and `subflag_value` calls read from cache

### Prefetch Without current_user

```ruby
# No user context
subflag_prefetch(nil)

# With specific user
subflag_prefetch(admin_user)

# With additional context
subflag_prefetch(current_user, context: { device: "mobile" })
```

### Direct API

You can also use the module method directly:

```ruby
Subflag.prefetch_flags(user: current_user)
# or
Subflag::Rails.prefetch_flags(user: current_user)
```

## Configuration

```ruby
Subflag::Rails.configure do |config|
  # Backend: :subflag (cloud), :active_record (self-hosted), :memory (testing)
  config.backend = :subflag

  # API key - required for :subflag backend
  config.api_key = "sdk-production-..."

  # API URL (default: https://api.subflag.com)
  config.api_url = "https://api.subflag.com"

  # Cross-request caching via Rails.cache (optional, :subflag backend only)
  # When set, prefetched flags are cached for this duration
  config.cache_ttl = 30.seconds

  # Logging
  config.logging_enabled = Rails.env.development?
  config.log_level = :debug  # :debug, :info, :warn

  # User context - works with all backends
  config.user_context do |user|
    { targeting_key: user.id.to_s, plan: user.plan }
  end
end
```

### ActiveRecord Flag Model

When using `backend: :active_record`, flags are stored in the `subflag_flags` table:

| Column | Type | Description |
|--------|------|-------------|
| `key` | string | Flag name (lowercase, dashes, e.g., `new-checkout`) |
| `value` | text | Default value (what everyone gets) |
| `value_type` | string | Type: `boolean`, `string`, `integer`, `float`, `object` |
| `enabled` | boolean | Whether the flag is active (default: true) |
| `description` | text | Optional description |
| `targeting_rules` | json | Optional rules for showing different values to different users |

```ruby
# Create flags
Subflag::Rails::Flag.create!(key: "max-projects", value: "100", value_type: "integer")

# Query flags
Subflag::Rails::Flag.enabled.find_each { |f| puts "#{f.key}: #{f.typed_value}" }

# Disable a flag
Subflag::Rails::Flag.find_by(key: "new-checkout")&.update!(enabled: false)
```

### Targeting Rules (ActiveRecord)

Show different flag values to different users based on their attributes. Perfect for internal testing before wider rollout.

> **Tip:** Use the [Admin UI](#admin-ui-activerecord) to manage targeting rules visually instead of editing JSON.

**First, configure user context:**

```ruby
# config/initializers/subflag.rb
Subflag::Rails.configure do |config|
  config.backend = :active_record

  config.user_context do |user|
    {
      targeting_key: user.id.to_s,
      email: user.email,
      role: user.role,           # e.g., "admin", "developer", "qa"
      plan: user.plan            # e.g., "free", "pro", "enterprise"
    }
  end
end
```

**Create flags with targeting rules:**

```ruby
# Internal team sees new feature, everyone else sees old
Subflag::Rails::Flag.create!(
  key: "new-dashboard",
  value: "false",                    # Default: everyone gets false
  value_type: "boolean",
  targeting_rules: [
    {
      "value" => "true",             # Internal team gets true
      "conditions" => {
        "type" => "OR",
        "conditions" => [
          { "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@yourcompany.com" },
          { "attribute" => "role", "operator" => "IN", "value" => ["admin", "developer", "qa"] }
        ]
      }
    }
  ]
)
```

**Progressive rollout with multiple rules (first match wins):**

```ruby
Subflag::Rails::Flag.create!(
  key: "max-projects",
  value: "5",                        # Default: everyone gets 5
  value_type: "integer",
  targeting_rules: [
    { "value" => "1000", "conditions" => { "type" => "AND", "conditions" => [{ "attribute" => "role", "operator" => "EQUALS", "value" => "admin" }] } },
    { "value" => "100", "conditions" => { "type" => "AND", "conditions" => [{ "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@yourcompany.com" }] } },
    { "value" => "25", "conditions" => { "type" => "AND", "conditions" => [{ "attribute" => "plan", "operator" => "EQUALS", "value" => "pro" }] } }
  ]
)
```

**Supported operators:**

| Operator | Example | Description |
|----------|---------|-------------|
| `EQUALS` | `{ "attribute" => "role", "operator" => "EQUALS", "value" => "admin" }` | Exact match |
| `NOT_EQUALS` | `{ "attribute" => "env", "operator" => "NOT_EQUALS", "value" => "prod" }` | Not equal |
| `IN` | `{ "attribute" => "role", "operator" => "IN", "value" => ["admin", "qa"] }` | Value in list |
| `NOT_IN` | `{ "attribute" => "country", "operator" => "NOT_IN", "value" => ["RU", "CN"] }` | Value not in list |
| `CONTAINS` | `{ "attribute" => "email", "operator" => "CONTAINS", "value" => "test" }` | String contains |
| `NOT_CONTAINS` | `{ "attribute" => "email", "operator" => "NOT_CONTAINS", "value" => "spam" }` | String doesn't contain |
| `STARTS_WITH` | `{ "attribute" => "user_id", "operator" => "STARTS_WITH", "value" => "test-" }` | String prefix |
| `ENDS_WITH` | `{ "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" }` | String suffix |
| `GREATER_THAN` | `{ "attribute" => "age", "operator" => "GREATER_THAN", "value" => 18 }` | Numeric > |
| `LESS_THAN` | `{ "attribute" => "items", "operator" => "LESS_THAN", "value" => 100 }` | Numeric < |
| `GREATER_THAN_OR_EQUAL` | `{ "attribute" => "score", "operator" => "GREATER_THAN_OR_EQUAL", "value" => 80 }` | Numeric >= |
| `LESS_THAN_OR_EQUAL` | `{ "attribute" => "score", "operator" => "LESS_THAN_OR_EQUAL", "value" => 50 }` | Numeric <= |
| `MATCHES` | `{ "attribute" => "email", "operator" => "MATCHES", "value" => ".*@company\\.com$" }` | Regex match |

**Combining conditions:**

```ruby
# OR: any condition matches
{
  "type" => "OR",
  "conditions" => [
    { "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" },
    { "attribute" => "role", "operator" => "EQUALS", "value" => "admin" }
  ]
}

# AND: all conditions must match
{
  "type" => "AND",
  "conditions" => [
    { "attribute" => "plan", "operator" => "EQUALS", "value" => "enterprise" },
    { "attribute" => "country", "operator" => "IN", "value" => ["US", "CA"] }
  ]
}
```

**How evaluation works:**

1. Flag disabled? → return code default
2. For each rule (in order): if context matches → return rule's value
3. No rules matched? → return flag's default `value`

This lets you progressively widen access by adding rules, without changing existing ones.

### Admin UI (ActiveRecord)

Mount the admin UI to manage flags and targeting rules visually:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Subflag::Rails::Engine => "/subflag"
  # ... your other routes
end
```

The admin UI provides:
- List, create, edit, and delete flags
- Toggle flags enabled/disabled
- Visual targeting rule builder (no JSON editing)
- Test rules against sample contexts

**Secure the admin UI:**

```ruby
# config/initializers/subflag.rb
Subflag::Rails.configure do |config|
  config.backend = :active_record

  # Require authentication for admin UI
  config.admin_auth do
    redirect_to main_app.root_path unless current_user&.admin?
  end
end
```

Visit `/subflag` in your browser to access the admin UI.

## Testing

Stub flags in your tests:

```ruby
# spec/rails_helper.rb (RSpec)
require "subflag/rails/test_helpers"
RSpec.configure do |config|
  config.include Subflag::Rails::TestHelpers
end

# test/test_helper.rb (Minitest)
require "subflag/rails/test_helpers"
class ActiveSupport::TestCase
  include Subflag::Rails::TestHelpers
end
```

```ruby
# In your specs/tests
it "shows new checkout when enabled" do
  stub_subflag(:new_checkout, true)
  stub_subflag(:max_projects, 100)

  visit checkout_path
  expect(page).to have_content("New Checkout")
end

# Stub multiple at once
stub_subflags(
  new_checkout: true,
  max_projects: 100,
  headline: "Welcome!"
)
```

## Documentation

- [Subflag Docs](https://docs.subflag.com)
- [Rails Guide](https://docs.subflag.com/rails)

## License

MIT
