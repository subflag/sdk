# frozen_string_literal: true

module Subflag
  module Rails
    module Backends
      # Provider wrapper for Subflag Cloud SaaS
      #
      # Delegates to the standalone subflag-openfeature-provider gem.
      # This is the default backend when using Subflag::Rails.
      #
      # @example
      #   Subflag::Rails.configure do |config|
      #     config.backend = :subflag
      #     config.api_key = "sdk-production-..."
      #   end
      #
      class SubflagProvider
        def initialize(api_key:, api_url:)
          require "subflag"
          @provider = ::Subflag::Provider.new(api_key: api_key, api_url: api_url)
        end

        def metadata
          @provider.metadata
        end

        def init
          @provider.init
        end

        def shutdown
          @provider.shutdown
        end

        def fetch_boolean_value(flag_key:, default_value:, evaluation_context: nil)
          @provider.fetch_boolean_value(
            flag_key: flag_key,
            default_value: default_value,
            evaluation_context: evaluation_context
          )
        end

        def fetch_string_value(flag_key:, default_value:, evaluation_context: nil)
          @provider.fetch_string_value(
            flag_key: flag_key,
            default_value: default_value,
            evaluation_context: evaluation_context
          )
        end

        def fetch_number_value(flag_key:, default_value:, evaluation_context: nil)
          @provider.fetch_number_value(
            flag_key: flag_key,
            default_value: default_value,
            evaluation_context: evaluation_context
          )
        end

        def fetch_integer_value(flag_key:, default_value:, evaluation_context: nil)
          @provider.fetch_integer_value(
            flag_key: flag_key,
            default_value: default_value,
            evaluation_context: evaluation_context
          )
        end

        def fetch_float_value(flag_key:, default_value:, evaluation_context: nil)
          @provider.fetch_float_value(
            flag_key: flag_key,
            default_value: default_value,
            evaluation_context: evaluation_context
          )
        end

        def fetch_object_value(flag_key:, default_value:, evaluation_context: nil)
          @provider.fetch_object_value(
            flag_key: flag_key,
            default_value: default_value,
            evaluation_context: evaluation_context
          )
        end
      end
    end
  end
end
