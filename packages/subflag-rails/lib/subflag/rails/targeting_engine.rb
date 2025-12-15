# frozen_string_literal: true

require "murmurhash3"

module Subflag
  module Rails
    # Evaluates targeting rules against evaluation contexts.
    #
    # Rules are arrays of { "value" => X, "conditions" => {...} } hashes.
    # First matching rule wins. Falls back to flag's default value if nothing matches.
    #
    # @example Rule structure
    #   [
    #     {
    #       "value" => "100",
    #       "conditions" => {
    #         "type" => "OR",
    #         "conditions" => [
    #           { "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" },
    #           { "attribute" => "role", "operator" => "IN", "value" => ["admin", "developer"] }
    #         ]
    #       }
    #     }
    #   ]
    #
    module TargetingEngine
      OPERATORS = %w[
        EQUALS NOT_EQUALS IN NOT_IN
        CONTAINS NOT_CONTAINS STARTS_WITH ENDS_WITH
        GREATER_THAN LESS_THAN GREATER_THAN_OR_EQUAL LESS_THAN_OR_EQUAL
        MATCHES
      ].freeze

      class << self
        # Evaluate targeting rules against a context
        #
        # @param rules [Array<Hash>, nil] Array of targeting rules with values
        # @param context [Hash, nil] Evaluation context with attributes
        # @param flag_key [String, nil] The flag key (required for percentage rollouts)
        # @return [String, nil] The matched rule's value, or nil if no match
        def evaluate(rules, context, flag_key: nil)
          return nil if rules.nil? || rules.empty?
          return nil if context.nil? || context.empty?

          normalized_context = normalize_context(context)
          targeting_key = extract_targeting_key(normalized_context)

          rules.each do |rule|
            rule = rule.transform_keys(&:to_s)
            conditions = rule["conditions"]
            percentage = rule["percentage"]

            segment_matches = if conditions.nil? || conditions.empty?
                                true
                              else
                                evaluate_rule(conditions, normalized_context)
                              end

            next unless segment_matches

            if percentage
              next unless targeting_key && flag_key
              next unless evaluate_percentage(targeting_key, flag_key, percentage)
            end

            return rule["value"]
          end

          nil
        end

        # Evaluate percentage rollout using MurmurHash3
        #
        # @param targeting_key [String] Unique identifier for the context
        # @param flag_key [String] The flag being evaluated
        # @param percentage [Integer] Target percentage (0-100)
        # @return [Boolean] true if context falls within percentage
        def evaluate_percentage(targeting_key, flag_key, percentage)
          percentage = percentage.to_i
          return false if percentage <= 0
          return true if percentage >= 100

          hash_input = "#{targeting_key}:#{flag_key}"
          hash_bytes = MurmurHash3::V128.str_hash(hash_input)
          hash_code = [hash_bytes[0]].pack("L").unpack1("l")
          bucket = hash_code.abs % 100

          bucket < percentage
        end

        private

        def normalize_context(context)
          context.transform_keys(&:to_s).transform_values do |v|
            v.is_a?(Symbol) ? v.to_s : v
          end
        end

        def extract_targeting_key(context)
          context["targeting_key"] || context["targetingKey"]
        end

        # Evaluate an AND/OR rule block
        def evaluate_rule(rule, context)
          rule = rule.transform_keys(&:to_s)
          type = rule["type"]&.upcase || "AND"
          conditions = rule["conditions"] || []

          case type
          when "AND"
            conditions.all? { |c| evaluate_condition(c, context) }
          when "OR"
            conditions.any? { |c| evaluate_condition(c, context) }
          else
            false
          end
        end

        # Evaluate a single condition
        def evaluate_condition(condition, context)
          condition = condition.transform_keys(&:to_s)
          attribute = condition["attribute"]
          operator = condition["operator"]&.upcase
          expected = condition["value"]

          return false unless attribute && operator

          actual = context[attribute]
          return false if actual.nil?

          case operator
          when "EQUALS"
            compare_equals(actual, expected)
          when "NOT_EQUALS"
            !compare_equals(actual, expected)
          when "IN"
            compare_in(actual, expected)
          when "NOT_IN"
            !compare_in(actual, expected)
          when "CONTAINS"
            compare_contains(actual, expected)
          when "NOT_CONTAINS"
            !compare_contains(actual, expected)
          when "STARTS_WITH"
            compare_starts_with(actual, expected)
          when "ENDS_WITH"
            compare_ends_with(actual, expected)
          when "GREATER_THAN"
            compare_numeric(actual, expected) { |a, e| a > e }
          when "LESS_THAN"
            compare_numeric(actual, expected) { |a, e| a < e }
          when "GREATER_THAN_OR_EQUAL"
            compare_numeric(actual, expected) { |a, e| a >= e }
          when "LESS_THAN_OR_EQUAL"
            compare_numeric(actual, expected) { |a, e| a <= e }
          when "MATCHES"
            compare_matches(actual, expected)
          else
            false
          end
        end

        def compare_equals(actual, expected)
          normalize_value(actual) == normalize_value(expected)
        end

        def compare_in(actual, expected)
          return false unless expected.is_a?(Array)

          normalized_actual = normalize_value(actual)
          expected.any? { |e| normalize_value(e) == normalized_actual }
        end

        def compare_contains(actual, expected)
          actual.to_s.include?(expected.to_s)
        end

        def compare_starts_with(actual, expected)
          actual.to_s.start_with?(expected.to_s)
        end

        def compare_ends_with(actual, expected)
          actual.to_s.end_with?(expected.to_s)
        end

        def compare_numeric(actual, expected)
          a = to_number(actual)
          e = to_number(expected)
          return false if a.nil? || e.nil?

          yield(a, e)
        end

        def compare_matches(actual, expected)
          Regexp.new(expected.to_s).match?(actual.to_s)
        rescue RegexpError
          false
        end

        def normalize_value(value)
          case value
          when Symbol then value.to_s
          when TrueClass then true
          when FalseClass then false
          when Numeric then value
          else value.to_s
          end
        end

        def to_number(value)
          case value
          when Numeric then value
          when String
            if value.include?(".")
              Float(value)
            else
              Integer(value)
            end
          else
            nil
          end
        rescue ArgumentError, TypeError
          nil
        end
      end
    end
  end
end
