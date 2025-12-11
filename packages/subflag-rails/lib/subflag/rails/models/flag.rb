# frozen_string_literal: true

module Subflag
  module Rails
    # ActiveRecord model for storing feature flags in your database.
    #
    # Supports targeting rules to show different values to different users.
    # Perfect for internal testing before wider rollout.
    #
    # @example Simple flag (everyone gets the same value)
    #   Subflag::Rails::Flag.create!(
    #     key: "new-checkout",
    #     value: "true",
    #     value_type: "boolean"
    #   )
    #
    # @example Flag with targeting rules (internal team gets different value)
    #   Subflag::Rails::Flag.create!(
    #     key: "new-dashboard",
    #     value: "false",
    #     value_type: "boolean",
    #     targeting_rules: [
    #       {
    #         "value" => "true",
    #         "conditions" => {
    #           "type" => "OR",
    #           "conditions" => [
    #             { "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" },
    #             { "attribute" => "role", "operator" => "IN", "value" => ["admin", "developer", "qa"] }
    #           ]
    #         }
    #       }
    #     ]
    #   )
    #
    # @example Progressive rollout (first match wins)
    #   Subflag::Rails::Flag.create!(
    #     key: "max-projects",
    #     value: "5",
    #     value_type: "integer",
    #     targeting_rules: [
    #       { "value" => "1000", "conditions" => { "type" => "AND", "conditions" => [{ "attribute" => "role", "operator" => "EQUALS", "value" => "admin" }] } },
    #       { "value" => "100", "conditions" => { "type" => "AND", "conditions" => [{ "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" }] } },
    #       { "value" => "25", "conditions" => { "type" => "AND", "conditions" => [{ "attribute" => "plan", "operator" => "EQUALS", "value" => "pro" }] } }
    #     ]
    #   )
    #
    class Flag < ::ActiveRecord::Base
      self.table_name = "subflag_flags"

      VALUE_TYPES = %w[boolean string integer float object].freeze

      validates :key, presence: true,
                      uniqueness: true,
                      format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, and dashes" }
      validates :value_type, inclusion: { in: VALUE_TYPES }
      validates :value, presence: true
      validate :validate_targeting_rules

      scope :enabled, -> { where(enabled: true) }

      # Evaluate the flag for a given context
      #
      # Returns the matched rule's value if context matches targeting rules,
      # otherwise returns the default value.
      #
      # @param context [Hash, nil] Evaluation context with user attributes
      # @param expected_type [Symbol, String, nil] Override the value_type for casting
      # @return [Object] The evaluated value, cast to the appropriate type
      def evaluate(context: nil, expected_type: nil)
        rules = parsed_targeting_rules
        raw_value = if rules.present? && context.present?
                      matched = TargetingEngine.evaluate(rules, context)
                      matched || value
                    else
                      value
                    end

        cast_value(raw_value, expected_type)
      end

      # Get the flag's default value cast to its declared type (ignores targeting)
      #
      # @param expected_type [Symbol, String, nil] Override the value_type for casting
      # @return [Object] The typed value
      def typed_value(expected_type = nil)
        cast_value(value, expected_type)
      end

      private

      def cast_value(raw_value, expected_type = nil)
        type = expected_type&.to_s || value_type

        case type.to_s
        when "boolean"
          ActiveModel::Type::Boolean.new.cast(raw_value)
        when "string"
          raw_value.to_s
        when "integer"
          raw_value.to_i
        when "float", "number"
          raw_value.to_f
        when "object"
          raw_value.is_a?(Hash) ? raw_value : JSON.parse(raw_value)
        else
          raw_value
        end
      end

      def parsed_targeting_rules
        return nil if targeting_rules.blank?

        case targeting_rules
        when String
          JSON.parse(targeting_rules)
        when Array
          targeting_rules
        else
          targeting_rules
        end
      end

      def validate_targeting_rules
        return if targeting_rules.blank?

        rules = case targeting_rules
                when Array then targeting_rules
                when String
                  begin
                    JSON.parse(targeting_rules)
                  rescue JSON::ParserError
                    errors.add(:targeting_rules, "must be valid JSON")
                    return
                  end
                else
                  errors.add(:targeting_rules, "must be an array of rules")
                  return
                end

        rules.each_with_index do |rule, index|
          unless rule.is_a?(Hash)
            errors.add(:targeting_rules, "rule #{index} must be a hash")
            next
          end

          rule = rule.transform_keys(&:to_s)
          errors.add(:targeting_rules, "rule #{index} must have a 'value' key") unless rule.key?("value")
          errors.add(:targeting_rules, "rule #{index} must have a 'conditions' key") unless rule.key?("conditions")
        end
      end
    end
  end
end
