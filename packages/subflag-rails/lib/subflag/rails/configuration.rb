# frozen_string_literal: true

module Subflag
  module Rails
    # Configuration for Subflag Rails integration
    #
    # @example Basic configuration
    #   Subflag::Rails.configure do |config|
    #     config.api_key = Rails.application.credentials.subflag_api_key
    #   end
    #
    # @example With user context
    #   Subflag::Rails.configure do |config|
    #     config.api_key = Rails.application.credentials.subflag_api_key
    #     config.user_context do |user|
    #       {
    #         targeting_key: user.id.to_s,
    #         email: user.email,
    #         plan: user.subscription&.plan_name,
    #         admin: user.admin?
    #       }
    #     end
    #   end
    #
    class Configuration
      VALID_BACKENDS = %i[subflag active_record memory].freeze

      # @return [Symbol] Backend to use (:subflag, :active_record, :memory)
      #   - :subflag — Subflag Cloud SaaS (default)
      #   - :active_record — Self-hosted, flags stored in your database
      #   - :memory — In-memory store for testing
      attr_reader :backend

      # @return [String, nil] The Subflag API key
      attr_accessor :api_key

      # @return [String] The Subflag API URL (defaults to production)
      attr_accessor :api_url

      # @return [Boolean] Whether to log flag evaluations
      attr_accessor :logging_enabled

      # @return [Symbol] Log level for flag evaluations (:debug, :info, :warn)
      attr_accessor :log_level

      # @return [Integer, ActiveSupport::Duration, nil] TTL for cross-request caching
      #   When set, prefetched flags are cached in Rails.cache for this duration.
      #   Set to nil to disable cross-request caching (default).
      attr_accessor :cache_ttl

      # @return [Proc, nil] Admin authentication callback for the admin UI
      attr_reader :admin_auth_callback

      def initialize
        @backend = :subflag
        @api_key = nil
        @api_url = "https://api.subflag.com"
        @user_context_block = nil
        @logging_enabled = false
        @log_level = :debug
        @cache_ttl = nil
        @admin_auth_callback = nil
      end

      # Set the backend with validation
      #
      # @param value [Symbol] The backend to use
      # @raise [ArgumentError] If the backend is invalid
      def backend=(value)
        value = value.to_sym
        unless VALID_BACKENDS.include?(value)
          raise ArgumentError, "Invalid backend: #{value}. Use one of: #{VALID_BACKENDS.join(', ')}"
        end

        @backend = value
      end

      # Check if cross-request caching via Rails.cache is enabled
      #
      # @return [Boolean]
      def rails_cache_enabled?
        return false unless @cache_ttl && @cache_ttl.to_i > 0
        return false unless defined?(::Rails.cache) && ::Rails.cache.present?

        true
      end

      # Configure how to extract context from a user object
      #
      # @yield [user] Block that receives a user object and returns context hash
      # @yieldparam user [Object] The user object passed to flag methods
      # @yieldreturn [Hash] Context hash with targeting_key and attributes
      #
      # @example
      #   config.user_context do |user|
      #     {
      #       targeting_key: user.id.to_s,
      #       email: user.email,
      #       plan: user.plan
      #     }
      #   end
      def user_context(&block)
        @user_context_block = block if block_given?
        @user_context_block
      end

      # Check if user context is configured
      #
      # @return [Boolean]
      def user_context_configured?
        !@user_context_block.nil?
      end

      # Build context from a user object using the configured block
      #
      # @param user [Object] The user object
      # @return [Hash, nil] The context hash or nil if no user/block
      def build_user_context(user)
        return nil unless user && @user_context_block

        @user_context_block.call(user)
      end

      # Configure authentication for the admin UI
      #
      # @yield [controller] Block called before each admin action
      # @yieldparam controller [ActionController::Base] The controller instance
      #
      # @example Require admin role
      #   config.admin_auth do
      #     redirect_to main_app.root_path unless current_user&.admin?
      #   end
      #
      # @example Use Devise authenticate
      #   config.admin_auth do
      #     authenticate_user!
      #   end
      def admin_auth(&block)
        @admin_auth_callback = block if block_given?
        @admin_auth_callback
      end
    end
  end
end
