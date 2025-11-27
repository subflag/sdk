# frozen_string_literal: true

require "faraday"
require "json"

module Subflag
  # HTTP client for communicating with the Subflag API
  #
  # @example Basic usage
  #   client = Client.new(api_url: "https://api.subflag.com", api_key: "sdk-dev-abc123")
  #   result = client.evaluate("my-flag")
  #
  # @example With evaluation context
  #   context = EvaluationContext.new(targeting_key: "user-123", attributes: { plan: "premium" })
  #   result = client.evaluate("my-flag", context: context)
  class Client
    DEFAULT_TIMEOUT = 5 # seconds

    attr_reader :api_url, :api_key, :timeout

    # @param api_url [String] The base URL of the Subflag API
    # @param api_key [String] The SDK API key (format: sdk-{env}-{random})
    # @param timeout [Integer] Request timeout in seconds (default: 5)
    def initialize(api_url:, api_key:, timeout: DEFAULT_TIMEOUT)
      @api_url = api_url.chomp("/")
      @api_key = api_key
      @timeout = timeout
      @connection = build_connection
    end

    # Evaluate a single flag
    #
    # @param flag_key [String] The key of the flag to evaluate
    # @param context [EvaluationContext, nil] Optional evaluation context
    # @return [EvaluationResult] The evaluation result
    # @raise [FlagNotFoundError] If the flag doesn't exist
    # @raise [AuthenticationError] If the API key is invalid
    # @raise [ApiError] For other API errors
    def evaluate(flag_key, context: nil)
      response = post("/sdk/evaluate/#{encode_uri_component(flag_key)}", context&.to_h)
      EvaluationResult.from_response(response)
    end

    # Evaluate all flags in the environment
    #
    # @param context [EvaluationContext, nil] Optional evaluation context
    # @return [Array<EvaluationResult>] Array of evaluation results
    # @raise [AuthenticationError] If the API key is invalid
    # @raise [ApiError] For other API errors
    def evaluate_all(context: nil)
      response = post("/sdk/evaluate-all", context&.to_h)
      response.map { |data| EvaluationResult.from_response(data) }
    end

    private

    def build_connection
      Faraday.new(url: @api_url) do |conn|
        conn.request :json
        conn.response :json
        conn.options.timeout = @timeout
        conn.options.open_timeout = @timeout
        conn.headers["Content-Type"] = "application/json"
        conn.headers["X-Subflag-API-Key"] = @api_key
        conn.adapter Faraday.default_adapter
      end
    end

    def post(path, body)
      response = @connection.post(path) do |req|
        req.body = body.to_json if body && !body.empty?
      end

      handle_response(response, path)
    rescue Faraday::TimeoutError => e
      raise TimeoutError, "Request timed out after #{@timeout}s: #{e.message}"
    rescue Faraday::ConnectionFailed => e
      raise ConnectionError, "Failed to connect to #{@api_url}: #{e.message}"
    rescue Faraday::Error => e
      raise ApiError.new("HTTP request failed: #{e.message}")
    end

    def handle_response(response, path)
      body = parse_body(response.body)

      case response.status
      when 200, 201
        body
      when 401, 403
        raise AuthenticationError.new(
          extract_message(body) || "Authentication failed",
          status: response.status,
          details: body
        )
      when 404
        flag_key = path.split("/").last
        raise FlagNotFoundError.new(flag_key, status: 404, details: body)
      else
        raise ApiError.new(
          extract_message(body) || "API request failed with status #{response.status}",
          status: response.status,
          details: body
        )
      end
    end

    def parse_body(body)
      return body if body.is_a?(Hash) || body.is_a?(Array)
      return {} if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError
      { "message" => body }
    end

    def extract_message(body)
      body["message"] if body.is_a?(Hash)
    end

    def encode_uri_component(str)
      URI.encode_www_form_component(str.to_s)
    end
  end
end
