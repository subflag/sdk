# frozen_string_literal: true

module Subflag
  module Rails
    # Result of a flag evaluation with full details
    #
    # @example
    #   result = Subflag.flags(user: current_user).evaluate(:max_projects, default: 3)
    #   result.value       # => 100
    #   result.variant     # => "premium"
    #   result.reason      # => :targeting_match
    #   result.flag_key    # => "max-projects"
    #   result.default?    # => false
    #   result.error?      # => false
    #
    class EvaluationResult
      # @return [Object] The resolved flag value
      attr_reader :value

      # @return [String, nil] The variant name that was selected
      attr_reader :variant

      # @return [Symbol] The reason for this evaluation result
      #   Possible values: :default, :targeting_match, :static, :split, :error, :unknown
      attr_reader :reason

      # @return [String] The flag key that was evaluated
      attr_reader :flag_key

      # @return [Symbol, nil] Error code if evaluation failed
      attr_reader :error_code

      # @return [String, nil] Error message if evaluation failed
      attr_reader :error_message

      def initialize(value:, variant: nil, reason: :unknown, flag_key:, error_code: nil, error_message: nil)
        @value = value
        @variant = variant
        @reason = reason
        @flag_key = flag_key
        @error_code = error_code
        @error_message = error_message
      end

      # Check if the default value was returned
      #
      # @return [Boolean]
      def default?
        reason == :default
      end

      # Check if there was an error during evaluation
      #
      # @return [Boolean]
      def error?
        reason == :error || !error_code.nil?
      end

      # Check if the value came from targeting rules
      #
      # @return [Boolean]
      def targeted?
        reason == :targeting_match
      end

      # Convert to hash representation
      #
      # @return [Hash]
      def to_h
        {
          value: value,
          variant: variant,
          reason: reason,
          flag_key: flag_key,
          error_code: error_code,
          error_message: error_message
        }.compact
      end

      # Build from OpenFeature evaluation details
      #
      # @param details [Hash] OpenFeature evaluation details hash
      # @param flag_key [String] The flag key
      # @return [EvaluationResult]
      def self.from_openfeature(details, flag_key:)
        new(
          value: details[:value],
          variant: details[:variant],
          reason: details[:reason] || :unknown,
          flag_key: flag_key,
          error_code: details[:error_code],
          error_message: details[:error_message]
        )
      end

      # Build from Subflag::EvaluationResult (from Ruby provider)
      #
      # @param result [Subflag::EvaluationResult] The provider's evaluation result
      # @return [EvaluationResult]
      def self.from_subflag(result)
        # Convert uppercase reason string to lowercase symbol
        reason = result.reason&.downcase&.to_sym || :unknown

        new(
          value: result.value,
          variant: result.variant,
          reason: reason,
          flag_key: result.flag_key
        )
      end
    end
  end
end
