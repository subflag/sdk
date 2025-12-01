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

# Test helpers - mock at OpenFeature client level
def stub_flag_evaluation(flag_key:, value:, variant: "default", reason: "DEFAULT")
  mock_client = double("OpenFeatureClient")
  allow(OpenFeature::SDK).to receive(:build_client).and_return(mock_client)

  # All fetch_*_value methods return the value directly
  allow(mock_client).to receive(:fetch_boolean_value).and_return(value)
  allow(mock_client).to receive(:fetch_string_value).and_return(value)
  allow(mock_client).to receive(:fetch_integer_value).and_return(value)
  allow(mock_client).to receive(:fetch_float_value).and_return(value)
  allow(mock_client).to receive(:fetch_object_value).and_return(value)

  # All fetch_*_details methods return EvaluationDetails
  details = { value: value, variant: variant, reason: reason.downcase.to_sym, flag_key: flag_key }
  allow(mock_client).to receive(:fetch_boolean_details).and_return(details)
  allow(mock_client).to receive(:fetch_string_details).and_return(details)
  allow(mock_client).to receive(:fetch_integer_details).and_return(details)
  allow(mock_client).to receive(:fetch_float_details).and_return(details)
  allow(mock_client).to receive(:fetch_object_details).and_return(details)
end

def configure_subflag(api_key: "sdk-test-key")
  Subflag::Rails.configure do |config|
    config.api_key = api_key
  end
end
