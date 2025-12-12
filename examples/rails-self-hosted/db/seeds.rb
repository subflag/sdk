# frozen_string_literal: true

# Seed feature flags for the self-hosted example
#
# Run with: rails db:seed

puts "Seeding feature flags..."

# Simple boolean flag - no targeting
Subflag::Rails::Flag.find_or_create_by!(key: "enable-checkout") do |flag|
  flag.value = "true"
  flag.value_type = "boolean"
  flag.description = "Enable the checkout flow"
end

# String flag with targeting - internal team sees different text
Subflag::Rails::Flag.find_or_create_by!(key: "button-text") do |flag|
  flag.value = "Buy Now"
  flag.value_type = "string"
  flag.description = "CTA button text (A/B test)"
  flag.targeting_rules = [
    {
      "value" => "🚀 Ship It!",
      "conditions" => {
        "type" => "OR",
        "conditions" => [
          { "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" },
          { "attribute" => "role", "operator" => "IN", "value" => %w[admin developer qa] }
        ]
      }
    }
  ]
end

# Integer flag with progressive rollout
Subflag::Rails::Flag.find_or_create_by!(key: "rate-limit") do |flag|
  flag.value = "100"
  flag.value_type = "integer"
  flag.description = "API rate limit per minute"
  flag.targeting_rules = [
    {
      "value" => "10000",
      "conditions" => {
        "type" => "AND",
        "conditions" => [
          { "attribute" => "role", "operator" => "EQUALS", "value" => "admin" }
        ]
      }
    },
    {
      "value" => "1000",
      "conditions" => {
        "type" => "AND",
        "conditions" => [
          { "attribute" => "plan", "operator" => "EQUALS", "value" => "enterprise" }
        ]
      }
    },
    {
      "value" => "500",
      "conditions" => {
        "type" => "AND",
        "conditions" => [
          { "attribute" => "plan", "operator" => "EQUALS", "value" => "pro" }
        ]
      }
    }
  ]
end

# Float flag - discount rate
Subflag::Rails::Flag.find_or_create_by!(key: "discount-rate") do |flag|
  flag.value = "0.0"
  flag.value_type = "float"
  flag.description = "Discount percentage (0.0 - 1.0)"
  flag.targeting_rules = [
    {
      "value" => "0.2",
      "conditions" => {
        "type" => "AND",
        "conditions" => [
          { "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" }
        ]
      }
    }
  ]
end

# Object flag - payment config
Subflag::Rails::Flag.find_or_create_by!(key: "payment-config") do |flag|
  flag.value = { "provider" => "stripe", "currency" => "USD" }.to_json
  flag.value_type = "object"
  flag.description = "Payment provider configuration"
end

# Boolean flag - feature gate
Subflag::Rails::Flag.find_or_create_by!(key: "premium-features") do |flag|
  flag.value = "false"
  flag.value_type = "boolean"
  flag.description = "Enable premium features"
  flag.targeting_rules = [
    {
      "value" => "true",
      "conditions" => {
        "type" => "OR",
        "conditions" => [
          { "attribute" => "plan", "operator" => "IN", "value" => %w[pro enterprise] },
          { "attribute" => "role", "operator" => "EQUALS", "value" => "admin" }
        ]
      }
    }
  ]
end

puts "Created #{Subflag::Rails::Flag.count} feature flags"
puts ""
puts "Visit http://localhost:3001/subflag to manage flags"
