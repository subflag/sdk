# frozen_string_literal: true

module Subflag
  module Rails
    module Backends
      # Provider that reads flags from your Rails database with targeting support.
      #
      # Stores flags in a `subflag_flags` table with typed values and optional
      # targeting rules for showing different values to different users.
      #
      # @example Basic setup
      #   Subflag::Rails.configure do |config|
      #     config.backend = :active_record
      #   end
      #
      # @example Create a simple flag
      #   Subflag::Rails::Flag.create!(
      #     key: "max-projects",
      #     value: "100",
      #     value_type: "integer"
      #   )
      #
      # @example Create a flag with targeting rules
      #   Subflag::Rails::Flag.create!(
      #     key: "new-dashboard",
      #     value: "false",
      #     value_type: "boolean",
      #     targeting_rules: [
      #       { "value" => "true", "conditions" => { "type" => "AND", "conditions" => [{ "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" }] } }
      #     ]
      #   )
      #
      class ActiveRecordProvider
        def metadata
          { name: "Subflag ActiveRecord Provider" }
        end

        def init; end
        def shutdown; end

        def fetch_boolean_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :boolean, evaluation_context)
        end

        def fetch_string_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :string, evaluation_context)
        end

        def fetch_number_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :number, evaluation_context)
        end

        def fetch_integer_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :integer, evaluation_context)
        end

        def fetch_float_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :float, evaluation_context)
        end

        def fetch_object_value(flag_key:, default_value:, evaluation_context: nil)
          resolve(flag_key, default_value, :object, evaluation_context)
        end

        private

        def resolve(flag_key, default_value, expected_type, evaluation_context)
          flag = Subflag::Rails::Flag.find_by(key: flag_key)

          unless flag&.enabled?
            return resolution(default_value, reason: :default)
          end

          # Convert OpenFeature context to hash for targeting evaluation
          context = context_to_hash(evaluation_context)
          value = flag.evaluate(context: context, expected_type: expected_type)

          # Determine if targeting matched
          reason = flag.targeting_rules.present? && context.present? ? :targeting_match : :static
          resolution(value, reason: reason, variant: "default")
        end

        def context_to_hash(evaluation_context)
          return nil if evaluation_context.nil?

          # OpenFeature::SDK::EvaluationContext stores fields as instance variables
          # We need to extract them into a hash for our targeting engine
          if evaluation_context.respond_to?(:to_h)
            evaluation_context.to_h
          elsif evaluation_context.respond_to?(:fields)
            evaluation_context.fields
          else
            # Fallback: extract instance variables
            hash = {}
            evaluation_context.instance_variables.each do |var|
              key = var.to_s.delete("@")
              hash[key] = evaluation_context.instance_variable_get(var)
            end
            hash
          end
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
