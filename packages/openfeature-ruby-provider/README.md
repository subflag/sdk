# Subflag OpenFeature Provider for Ruby

Ruby provider for [OpenFeature](https://openfeature.dev) that integrates with [Subflag](https://subflag.com) feature flag management.

## Installation

```ruby
gem 'subflag-openfeature-provider'
```

Or with Bundler:

```bash
bundle add subflag-openfeature-provider
```

## Usage

### With OpenFeature SDK

```ruby
require "open_feature/sdk"
require "subflag"

# Configure the provider
provider = Subflag::Provider.new(
  api_url: ENV["SUBFLAG_API_URL"],
  api_key: ENV["SUBFLAG_API_KEY"]
)

OpenFeature::SDK.configure do |config|
  config.set_provider(provider)
end

# Get a client and evaluate flags
client = OpenFeature::SDK.build_client

# Boolean flag
if client.fetch_boolean_value(flag_key: "dark-mode", default_value: false)
  enable_dark_mode
end

# String flag
theme = client.fetch_string_value(flag_key: "theme", default_value: "light")

# Number flag
limit = client.fetch_integer_value(flag_key: "rate-limit", default_value: 100)

# Object flag
config = client.fetch_object_value(flag_key: "feature-config", default_value: {})
```

### With Evaluation Context

```ruby
context = {
  targeting_key: "user-123",
  plan: "premium",
  country: "US"
}

enabled = client.fetch_boolean_value(
  flag_key: "premium-feature",
  default_value: false,
  evaluation_context: context
)
```

### Direct Client Usage

You can also use the Subflag client directly without OpenFeature:

```ruby
require "subflag"

client = Subflag::Client.new(
  api_url: "https://api.subflag.com",
  api_key: "sdk-production-abc123"
)

result = client.evaluate("my-flag")
puts result.value    # => true
puts result.variant  # => "enabled"
puts result.reason   # => "DEFAULT"

# Bulk evaluation
results = client.evaluate_all
```

## Configuration

| Option | Description | Default |
|--------|-------------|---------|
| `api_url` | Subflag API base URL | Required |
| `api_key` | SDK API key (`sdk-{env}-{random}`) | Required |
| `timeout` | Request timeout in seconds | 5 |

## Error Handling

The provider returns default values on errors, following OpenFeature conventions:

```ruby
result = client.fetch_boolean_value(flag_key: "unknown", default_value: false)
# result[:value] => false (default)
# result[:reason] => :error
# result[:error_code] => :flag_not_found
```

## Requirements

- Ruby >= 3.1
- openfeature-sdk >= 0.3

## License

MIT
