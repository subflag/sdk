# frozen_string_literal: true

module Subflag
  module Rails
    module Backends
      # Provider that reads flags from your Rails database
      #
      # Stores flags in a `subflag_flags` table with typed values.
      # Perfect for teams who want self-hosted feature flags without external dependencies.
      #
      # @example
      #   Subflag::Rails.configure do |config|
      #     config.backend = :active_record
      #   end
      #
      #   # Create a flag
      #   Subflag::Rails::Flag.create!(
      #     key: "max-projects",
      #     value: "100",
      #     value_type: "integer",
      #     enabled: true
      #   )
      #
      #   # Use it
      #   subflag_value(:max_projects, default: 3)  # => 100
      #
      class ActiveRecordProvider
        def metadata
          { name: "Subflag ActiveRecord Provider" }
        end

        def init; end
        def shutdown; end

        def fetch_boolean_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :boolean)
        end

        def fetch_string_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :string)
        end

        def fetch_number_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :number)
        end

        def fetch_integer_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :integer)
        end

        def fetch_float_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :float)
        end

        def fetch_object_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :object)
        end

        private

        def resolve(flag_key, default_value, expected_type)
          flag = Subflag::Rails::Flag.find_by(key: flag_key)

          unless flag&.enabled?
            return resolution(default_value, reason: :default)
          end

          value = flag.typed_value(expected_type)
          resolution(value, reason: :static, variant: "default")
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
