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
      # @return [String, nil] The Subflag API key
      attr_accessor :api_key

      # @return [String] The Subflag API URL (defaults to production)
      attr_accessor :api_url

      # @return [Boolean] Whether to log flag evaluations
      attr_accessor :logging_enabled

      # @return [Symbol] Log level for flag evaluations (:debug, :info, :warn)
      attr_accessor :log_level

      def initialize
        @api_key = nil
        @api_url = "https://api.subflag.com"
        @user_context_block = nil
        @logging_enabled = false
        @log_level = :debug
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
    end
  end
end
