# frozen_string_literal: true

module Subflag
  module Rails
    module Backends
      # In-memory provider for testing and development
      #
      # Flags are stored in a hash and reset when the process restarts.
      # Useful for unit tests and local development without external dependencies.
      #
      # @example In tests
      #   Subflag::Rails.configure do |config|
      #     config.backend = :memory
      #   end
      #
      #   # Set flags directly
      #   Subflag::Rails.provider.set(:new_checkout, true)
      #   Subflag::Rails.provider.set(:max_projects, 100)
      #
      #   # Use them
      #   subflag_enabled?(:new_checkout)  # => true
      #
      class MemoryProvider
        def initialize
          @flags = {}
        end

        def metadata
          { name: "Subflag Memory Provider" }
        end

        def init; end
        def shutdown; end

        # Set a flag value programmatically
        #
        # @param key [String, Symbol] The flag key (underscores converted to dashes)
        # @param value [Object] The flag value
        # @param enabled [Boolean] Whether the flag is enabled (default: true)
        def set(key, value, enabled: true)
          @flags[normalize_key(key)] = { value: value, enabled: enabled }
        end

        # Clear all flags
        def clear
          @flags.clear
        end

        # Get all flags (for debugging)
        def all
          @flags.dup
        end

        def fetch_boolean_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value)
        end

        def fetch_string_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value)
        end

        def fetch_number_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value)
        end

        def fetch_integer_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value)
        end

        def fetch_float_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value)
        end

        def fetch_object_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value)
        end

        private

        def normalize_key(key)
          key.to_s.tr("_", "-")
        end

        def resolve(flag_key, default_value)
          flag = @flags[flag_key.to_s]

          unless flag && flag[:enabled]
            return resolution(default_value, reason: :default)
          end

          resolution(flag[:value], reason: :static, variant: "default")
        end

        def resolution(value, reason:, variant: nil)
          OpenFeature::SDK::Provider::ResolutionDetails.new(
            value: value,
            reason: reason,
            variant: variant
          )
        end
      end
    end
  end
end
