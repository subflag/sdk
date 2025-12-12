# frozen_string_literal: true

# Subflag configuration
#
# API key is auto-loaded from:
# 1. SUBFLAG_API_KEY environment variable
# 2. Rails credentials (subflag.api_key)

Subflag::Rails.configure do |config|
  # Backend: :subflag (cloud), :active_record (self-hosted), :memory (testing)
  config.backend = :subflag

  # Enable logging in development
  config.logging_enabled = Rails.env.development?
  config.log_level = :debug

  # Configure user context for targeting
  # This enables per-user flag values (e.g., different limits by plan)
  #
  # config.user_context do |user|
  #   {
  #     targeting_key: user.id.to_s,
  #     email: user.email,
  #     plan: user.subscription&.plan_name || "free",
  #     admin: user.admin?
  #   }
  # end
end
