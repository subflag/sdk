# frozen_string_literal: true

module Subflag
  module Rails
    # Railtie for automatic Rails integration
    #
    # This handles:
    # - Registering helpers in views AND controllers
    # - Auto-configuring from credentials if available
    #
    class Railtie < ::Rails::Railtie
      # Include helpers in views and controllers
      initializer "subflag.helpers" do
        ActiveSupport.on_load(:action_view) do
          include Subflag::Rails::Helpers
        end

        ActiveSupport.on_load(:action_controller_base) do
          include Subflag::Rails::Helpers
        end

        ActiveSupport.on_load(:action_controller_api) do
          include Subflag::Rails::Helpers
        end
      end

      # Auto-configure from credentials
      initializer "subflag.configure" do
        config.after_initialize do
          next if Subflag::Rails.configuration.api_key

          api_key = ::Rails.application.credentials.dig(:subflag, :api_key) ||
                    ::Rails.application.credentials.subflag_api_key ||
                    ENV["SUBFLAG_API_KEY"]

          if api_key
            Subflag::Rails.configure do |c|
              c.api_key = api_key
            end
          end
        end
      end
    end
  end
end
