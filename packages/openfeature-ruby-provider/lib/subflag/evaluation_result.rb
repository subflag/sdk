# frozen_string_literal: true

module Subflag
  # Represents the result of a flag evaluation from the Subflag API
  class EvaluationResult
    # Valid evaluation reasons
    REASONS = %w[
      DEFAULT
      OVERRIDE
      SEGMENT_MATCH
      PERCENTAGE_ROLLOUT
      TARGETING_MATCH
      ERROR
    ].freeze

    attr_reader :flag_key, :value, :variant, :reason

    # @param flag_key [String] The key of the evaluated flag
    # @param value [Object] The evaluated value (type depends on flag configuration)
    # @param variant [String] The name of the selected variant
    # @param reason [String] Why this value was selected (one of REASONS)
    def initialize(flag_key:, value:, variant:, reason:)
      @flag_key = flag_key
      @value = value
      @variant = variant
      @reason = reason
    end

    # Create from API response hash
    # @param data [Hash] The API response data
    # @return [EvaluationResult]
    def self.from_response(data)
      new(
        flag_key: fetch_key(data, "flagKey"),
        value: fetch_key(data, "value"),
        variant: fetch_key(data, "variant"),
        reason: fetch_key(data, "reason")
      )
    end

    # Fetch a key from hash, checking both string and symbol keys
    # Can't use || because false values would be skipped
    def self.fetch_key(data, key)
      data.key?(key) ? data[key] : data[key.to_sym]
    end

    # Check if evaluation was successful (not an error)
    # @return [Boolean]
    def success?
      reason != "ERROR"
    end

    # Convert to hash
    # @return [Hash]
    def to_h
      {
        flag_key: @flag_key,
        value: @value,
        variant: @variant,
        reason: @reason
      }
    end
  end
end
