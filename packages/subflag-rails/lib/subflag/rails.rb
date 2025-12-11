# frozen_string_literal: true

require "open_feature/sdk"

require_relative "rails/version"
require_relative "rails/configuration"
require_relative "rails/context_builder"
require_relative "rails/evaluation_result"
require_relative "rails/request_cache"
require_relative "rails/client"
require_relative "rails/flag_accessor"
require_relative "rails/helpers"
require_relative "rails/railtie" if defined?(Rails::Railtie)
require_relative "rails/engine" if defined?(Rails::Engine)

# Test helpers are loaded separately: require "subflag/rails/test_helpers"

module Subflag
  module Rails
    class << self
      # Access the configuration
      #
      # @return [Configuration]
      def configuration
        @configuration ||= Configuration.new
      end

      # Configure Subflag for Rails
      #
      # @example Using Subflag Cloud (SaaS)
      #   Subflag::Rails.configure do |config|
      #     config.backend = :subflag
      #     config.api_key = Rails.application.credentials.subflag_api_key
      #     config.user_context do |user|
      #       { targeting_key: user.id.to_s, email: user.email, plan: user.plan }
      #     end
      #   end
      #
      # @example Using ActiveRecord (self-hosted)
      #   Subflag::Rails.configure do |config|
      #     config.backend = :active_record
      #   end
      #
      # @example Using Memory (testing)
      #   Subflag::Rails.configure do |config|
      #     config.backend = :memory
      #   end
      #
      # @yield [Configuration]
      def configure
        yield(configuration)
        setup_provider
      end

      # Access the client for flag evaluation
      #
      # @return [Client]
      def client
        @client ||= Client.new
      end

      # Access the current provider instance
      #
      # Useful for the Memory backend where you can set flags directly:
      #   Subflag::Rails.provider.set(:my_flag, true)
      #
      # @return [Object] The current OpenFeature provider
      def provider
        @provider
      end

      # Prefetch all flags for a user/context in a single API call
      #
      # Call this early in a request to fetch all flags at once.
      # Subsequent flag lookups will use the cached values.
      #
      # @param user [Object, nil] The user object for targeting
      # @param context [Hash, nil] Additional context attributes
      # @return [Array<Hash>] Array of prefetched flag results (for inspection)
      #
      # @example Prefetch in a controller
      #   before_action :prefetch_flags
      #
      #   def prefetch_flags
      #     Subflag::Rails.prefetch_flags(user: current_user)
      #   end
      #
      def prefetch_flags(user: nil, context: nil)
        client.prefetch_all(user: user, context: context)
      end

      # Reset configuration (primarily for testing)
      def reset!
        @configuration = Configuration.new
        @client = nil
        @provider = nil
      end

      private

      def setup_provider
        @provider = build_provider
        return unless @provider

        OpenFeature::SDK.configure do |config|
          config.set_provider(@provider)
        end
      end

      def build_provider
        case configuration.backend
        when :subflag
          build_subflag_provider
        when :active_record
          build_active_record_provider
        when :memory
          build_memory_provider
        else
          raise ArgumentError, "Unknown backend: #{configuration.backend}. Use :subflag, :active_record, or :memory"
        end
      end

      def build_subflag_provider
        return nil unless configuration.api_key

        require_relative "rails/backends/subflag_provider"
        Backends::SubflagProvider.new(
          api_key: configuration.api_key,
          api_url: configuration.api_url
        )
      end

      def build_active_record_provider
        require_relative "rails/targeting"
        require_relative "rails/backends/active_record_provider"
        require_relative "rails/models/flag"
        Backends::ActiveRecordProvider.new
      end

      def build_memory_provider
        require_relative "rails/backends/memory_provider"
        Backends::MemoryProvider.new
      end
    end
  end

  # Top-level convenience method for flag access
  class << self
    # Get a flag accessor for evaluating flags
    #
    # @param user [Object, nil] The user object for targeting
    # @param context [Hash, nil] Additional context attributes
    # @return [FlagAccessor] A flag accessor with method_missing DSL
    #
    # @example Basic usage
    #   Subflag.flags.new_checkout?(default: false)
    #   Subflag.flags.homepage_headline(default: "Welcome")
    #
    # @example With user targeting
    #   Subflag.flags(user: current_user).max_projects(default: 3)
    #
    # @example Bracket access for exact flag names
    #   Subflag.flags["my-exact-flag", default: "value"]
    #
    def flags(user: nil, context: nil)
      Rails::FlagAccessor.new(user: user, context: context)
    end

    # Prefetch all flags for a user/context in a single API call
    #
    # @param user [Object, nil] The user object for targeting
    # @param context [Hash, nil] Additional context attributes
    # @return [Array<Hash>] Array of prefetched flag results
    #
    # @example
    #   Subflag.prefetch_flags(user: current_user)
    #   # Subsequent lookups use cache
    #   Subflag.flags(user: current_user).new_feature?(default: false)
    #
    def prefetch_flags(user: nil, context: nil)
      Rails.prefetch_flags(user: user, context: context)
    end
  end
end
