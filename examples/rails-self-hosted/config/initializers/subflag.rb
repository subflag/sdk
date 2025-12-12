# frozen_string_literal: true

# Subflag configuration - Self-hosted with ActiveRecord backend
#
# Flags are stored in your database (subflag_flags table).
# No external API calls, no cloud dependency.

Subflag::Rails.configure do |config|
  # Use ActiveRecord backend - flags stored in your database
  config.backend = :active_record

  # Enable logging in development
  config.logging_enabled = Rails.env.development?
  config.log_level = :debug

  # Configure user context for targeting
  # This example uses a simple hash for demo purposes
  # In a real app, you'd extract from your User model
  config.user_context do |user|
    {
      targeting_key: user[:id].to_s,
      email: user[:email],
      role: user[:role],
      plan: user[:plan]
    }
  end

  # Secure the admin UI (optional)
  # Uncomment in production to require authentication
  # config.admin_auth do
  #   redirect_to main_app.root_path unless current_user&.admin?
  # end
end
