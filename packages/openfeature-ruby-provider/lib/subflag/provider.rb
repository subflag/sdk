# frozen_string_literal: true

module Subflag
  # OpenFeature provider for Subflag feature flag management.
  #
  # This provider implements the OpenFeature provider interface using duck-typing,
  # following the on-demand evaluation pattern (like the Node.js provider).
  # Each flag evaluation makes an HTTP request to the Subflag API.
  #
  # @example Basic usage with OpenFeature
  #   require "openfeature/sdk"
  #   require "subflag"
  #
  #   provider = Subflag::Provider.new(
  #     api_url: "https://api.subflag.com",
  #     api_key: "sdk-production-abc123"
  #   )
  #
  #   OpenFeature::SDK.configure do |config|
  #     config.set_provider(provider)
  #   end
  #
  #   client = OpenFeature::SDK.build_client
  #   enabled = client.fetch_boolean_value(flag_key: "dark-mode", default_value: false)
  #
  # @example With evaluation context
  #   context = { targeting_key: "user-123", plan: "premium" }
  #   enabled = client.fetch_boolean_value(
  #     flag_key: "premium-feature",
  #     default_value: false,
  #     evaluation_context: context
  #   )
  class Provider
    # Provider metadata for OpenFeature SDK
    # @return [Hash] Provider metadata
    def metadata
      { name: "Subflag Ruby Provider" }
    end

    # @param api_url [String] The base URL of the Subflag API
    # @param api_key [String] The SDK API key (format: sdk-{env}-{random})
    # @param timeout [Integer] Request timeout in seconds (default: 5)
    def initialize(api_url:, api_key:, timeout: Client::DEFAULT_TIMEOUT)
      @client = Client.new(api_url: api_url, api_key: api_key, timeout: timeout)
    end

    # Called when provider is registered with OpenFeature
    # Named `init` instead of `initialize` to avoid Ruby constructor conflict
    def init
      # No-op for on-demand evaluation pattern
      # Could be used for connection validation or pre-warming in the future
    end

    # Called when provider is unregistered or SDK is shutdown
    def shutdown
      # No-op for stateless HTTP client
      # Could be used for connection pool cleanup in the future
    end

    # Evaluate a boolean flag
    #
    # @param flag_key [String] The flag key to evaluate
    # @param default_value [Boolean] Value to return if evaluation fails
    # @param evaluation_context [Hash, nil] Optional targeting context
    # @return [Hash] Resolution details with :value, :reason, :variant, :error_code, :error_message
    def fetch_boolean_value(flag_key:, default_value:, evaluation_context: nil)
      evaluate_flag(flag_key, default_value, evaluation_context, :boolean)
    end

    # Evaluate a string flag
    #
    # @param flag_key [String] The flag key to evaluate
    # @param default_value [String] Value to return if evaluation fails
    # @param evaluation_context [Hash, nil] Optional targeting context
    # @return [Hash] Resolution details
    def fetch_string_value(flag_key:, default_value:, evaluation_context: nil)
      evaluate_flag(flag_key, default_value, evaluation_context, :string)
    end

    # Evaluate a number flag (returns Float)
    #
    # @param flag_key [String] The flag key to evaluate
    # @param default_value [Numeric] Value to return if evaluation fails
    # @param evaluation_context [Hash, nil] Optional targeting context
    # @return [Hash] Resolution details
    def fetch_number_value(flag_key:, default_value:, evaluation_context: nil)
      evaluate_flag(flag_key, default_value, evaluation_context, :number)
    end

    # Evaluate an integer flag
    #
    # @param flag_key [String] The flag key to evaluate
    # @param default_value [Integer] Value to return if evaluation fails
    # @param evaluation_context [Hash, nil] Optional targeting context
    # @return [Hash] Resolution details
    def fetch_integer_value(flag_key:, default_value:, evaluation_context: nil)
      evaluate_flag(flag_key, default_value, evaluation_context, :integer)
    end

    # Evaluate a float flag
    #
    # @param flag_key [String] The flag key to evaluate
    # @param default_value [Float] Value to return if evaluation fails
    # @param evaluation_context [Hash, nil] Optional targeting context
    # @return [Hash] Resolution details
    def fetch_float_value(flag_key:, default_value:, evaluation_context: nil)
      evaluate_flag(flag_key, default_value, evaluation_context, :float)
    end

    # Evaluate an object/hash flag
    #
    # @param flag_key [String] The flag key to evaluate
    # @param default_value [Hash] Value to return if evaluation fails
    # @param evaluation_context [Hash, nil] Optional targeting context
    # @return [Hash] Resolution details
    def fetch_object_value(flag_key:, default_value:, evaluation_context: nil)
      evaluate_flag(flag_key, default_value, evaluation_context, :object)
    end

    private

    # Core evaluation logic shared by all type-specific methods
    def evaluate_flag(flag_key, default_value, evaluation_context, expected_type)
      context = EvaluationContext.from_openfeature(evaluation_context)
      result = @client.evaluate(flag_key, context: context)

      # Validate type matches
      unless type_matches?(result.value, expected_type)
        return error_result(
          default_value,
          error_code: :type_mismatch,
          error_message: "Flag '#{flag_key}' value type doesn't match requested type #{expected_type}"
        )
      end

      # Convert value if needed (e.g., number -> integer)
      converted_value = convert_value(result.value, expected_type)

      {
        value: converted_value,
        reason: map_reason(result.reason),
        variant: result.variant,
        flag_metadata: { flag_key: result.flag_key }
      }
    rescue FlagNotFoundError => e
      error_result(default_value, error_code: :flag_not_found, error_message: e.message)
    rescue AuthenticationError => e
      error_result(default_value, error_code: :invalid_context, error_message: e.message)
    rescue TypeMismatchError => e
      error_result(default_value, error_code: :type_mismatch, error_message: e.message)
    rescue TimeoutError, ConnectionError => e
      error_result(default_value, error_code: :general, error_message: e.message)
    rescue StandardError => e
      error_result(default_value, error_code: :general, error_message: "Unexpected error: #{e.message}")
    end

    # Check if value matches expected type
    def type_matches?(value, expected_type)
      case expected_type
      when :boolean
        value == true || value == false
      when :string
        value.is_a?(String)
      when :number, :integer, :float
        value.is_a?(Numeric)
      when :object
        value.is_a?(Hash)
      else
        true
      end
    end

    # Convert value to specific type if needed
    def convert_value(value, expected_type)
      case expected_type
      when :integer
        value.to_i
      when :float
        value.to_f
      else
        value
      end
    end

    # Map Subflag reason to OpenFeature reason
    def map_reason(subflag_reason)
      case subflag_reason
      when "DEFAULT"
        :default
      when "TARGETING_MATCH", "SEGMENT_MATCH"
        :targeting_match
      when "OVERRIDE"
        :static
      when "PERCENTAGE_ROLLOUT"
        :split
      when "ERROR"
        :error
      else
        :unknown
      end
    end

    # Build error result hash
    def error_result(default_value, error_code:, error_message:)
      {
        value: default_value,
        reason: :error,
        error_code: error_code,
        error_message: error_message
      }
    end
  end
end
