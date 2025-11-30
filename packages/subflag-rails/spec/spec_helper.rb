# frozen_string_literal: true

require "bundler/setup"
require "webmock/rspec"

# Mock Rails before requiring subflag-rails
module Rails
  def self.application
    @application ||= OpenStruct.new(
      credentials: OpenStruct.new
    )
  end

  def self.logger
    @logger ||= Logger.new($stdout, level: Logger::WARN)
  end

  def self.env
    ActiveSupport::StringInquirer.new("test")
  end
end

module ActiveSupport
  class StringInquirer < String
    def method_missing(method_name, *args)
      if method_name.to_s.end_with?("?")
        self == method_name.to_s.chomp("?")
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_name.to_s.end_with?("?") || super
    end
  end
end

require "subflag-rails"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do
    Subflag::Rails.reset!
    WebMock.reset!
  end
end

# Test helpers
def stub_flag_evaluation(flag_key:, value:, variant: "default", reason: "DEFAULT")
  stub_request(:post, %r{/sdk/evaluate/#{flag_key}})
    .to_return(
      status: 200,
      body: {
        flagKey: flag_key,
        value: value,
        variant: variant,
        reason: reason
      }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
end

def configure_subflag(api_key: "sdk-test-key")
  Subflag::Rails.configure do |config|
    config.api_key = api_key
  end
end
