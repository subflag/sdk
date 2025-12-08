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

    # Valid flag statuses
    FLAG_STATUSES = %w[ACTIVE DEPRECATED].freeze

    attr_reader :flag_key, :value, :variant, :reason, :flag_status

    # @param flag_key [String] The key of the evaluated flag
    # @param value [Object] The evaluated value (type depends on flag configuration)
    # @param variant [String] The name of the selected variant
    # @param reason [String] Why this value was selected (one of REASONS)
    # @param flag_status [String, nil] Lifecycle status of the flag (ACTIVE, DEPRECATED)
    def initialize(flag_key:, value:, variant:, reason:, flag_status: nil)
      @flag_key = flag_key
      @value = value
      @variant = variant
      @reason = reason
      @flag_status = flag_status
    end

    # Create from API response hash
    # @param data [Hash] The API response data
    # @return [EvaluationResult]
    def self.from_response(data)
      new(
        flag_key: fetch_key(data, "flagKey"),
        value: fetch_key(data, "value"),
        variant: fetch_key(data, "variant"),
        reason: fetch_key(data, "reason"),
        flag_status: fetch_key(data, "flagStatus")
      )
    end

    # Fetch a key from hash, checking string, symbol, and snake_case variants
    # Can't use || because false values would be skipped
    def self.fetch_key(data, key)
      # Try camelCase string (API format)
      return data[key] if data.key?(key)
      # Try camelCase symbol
      return data[key.to_sym] if data.key?(key.to_sym)
      # Try snake_case symbol (from to_h)
      snake_key = key.gsub(/([a-z])([A-Z])/, '\1_\2').downcase.to_sym
      return data[snake_key] if data.key?(snake_key)
      # Try snake_case string
      data[snake_key.to_s]
    end

    # Check if evaluation was successful (not an error)
    # @return [Boolean]
    def success?
      reason != "ERROR"
    end

    # Check if the flag is deprecated
    # @return [Boolean]
    def deprecated?
      @flag_status == "DEPRECATED"
    end

    # Convert to hash
    # @return [Hash]
    def to_h
      {
        flag_key: @flag_key,
        value: @value,
        variant: @variant,
        reason: @reason,
        flag_status: @flag_status
      }
    end
  end
end
