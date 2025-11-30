# frozen_string_literal: true

# Subflag configuration
#
# API key is automatically loaded from:
# 1. Rails credentials (subflag.api_key or subflag_api_key)
# 2. SUBFLAG_API_KEY environment variable

Subflag::Rails.configure do |config|
  # Uncomment to manually set API key
  # config.api_key = Rails.application.credentials.dig(:subflag, :api_key)

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
