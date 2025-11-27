# frozen_string_literal: true

module Subflag
  # Base error class for all Subflag errors
  class Error < StandardError; end

  # Raised when API request fails
  class ApiError < Error
    attr_reader :status, :details

    def initialize(message, status: nil, details: nil)
      @status = status
      @details = details
      super(message)
    end
  end

  # Raised when authentication fails (401/403)
  class AuthenticationError < ApiError
    def initialize(message = "Invalid or missing API key", **kwargs)
      super(message, **kwargs)
    end
  end

  # Raised when a flag is not found (404)
  class FlagNotFoundError < ApiError
    attr_reader :flag_key

    def initialize(flag_key, **kwargs)
      @flag_key = flag_key
      super("Flag not found: #{flag_key}", **kwargs)
    end
  end

  # Raised when flag value type doesn't match requested type
  class TypeMismatchError < Error
    attr_reader :flag_key, :expected_type, :actual_type

    def initialize(flag_key, expected_type:, actual_type:)
      @flag_key = flag_key
      @expected_type = expected_type
      @actual_type = actual_type
      super("Type mismatch for flag '#{flag_key}': expected #{expected_type}, got #{actual_type}")
    end
  end

  # Raised when network/connection fails
  class ConnectionError < Error
    def initialize(message = "Failed to connect to Subflag API")
      super(message)
    end
  end

  # Raised when request times out
  class TimeoutError < Error
    def initialize(message = "Request to Subflag API timed out")
      super(message)
    end
  end
end
