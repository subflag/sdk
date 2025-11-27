# frozen_string_literal: true

require "webmock/rspec"
require "subflag"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Use expect syntax
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Disable real network connections
  WebMock.disable_net_connect!
end

# Shared test helpers
module TestHelpers
  API_URL = "https://api.subflag.com"
  API_KEY = "sdk-test-abc123"

  def stub_evaluate(flag_key:, response:, status: 200, context: nil)
    stub = stub_request(:post, "#{API_URL}/sdk/evaluate/#{flag_key}")
    stub = stub.with(body: context.to_json) if context
    stub.to_return(
      status: status,
      body: response.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  def stub_evaluate_all(response:, status: 200)
    stub_request(:post, "#{API_URL}/sdk/evaluate-all")
      .to_return(
        status: status,
        body: response.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_auth_error
    stub_request(:post, /#{API_URL}\/sdk\//)
      .to_return(
        status: 401,
        body: { message: "Invalid API key" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def success_response(flag_key:, value:, variant: "default", reason: "DEFAULT")
    {
      flagKey: flag_key,
      value: value,
      variant: variant,
      reason: reason
    }
  end
end

RSpec.configure do |config|
  config.include TestHelpers
end
