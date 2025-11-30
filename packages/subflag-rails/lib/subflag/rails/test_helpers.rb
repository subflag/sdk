# frozen_string_literal: true

module Subflag
  module Rails
    # Test helpers for stubbing feature flags in specs
    #
    # @example RSpec setup
    #   # spec/rails_helper.rb
    #   require "subflag/rails/test_helpers"
    #   RSpec.configure do |config|
    #     config.include Subflag::Rails::TestHelpers
    #   end
    #
    # @example Minitest setup
    #   # test/test_helper.rb
    #   require "subflag/rails/test_helpers"
    #   class ActiveSupport::TestCase
    #     include Subflag::Rails::TestHelpers
    #   end
    #
    # @example Usage
    #   it "shows new checkout when enabled" do
    #     stub_subflag(:new_checkout, true)
    #     visit checkout_path
    #     expect(page).to have_content("New Checkout")
    #   end
    #
    #   it "limits projects based on plan" do
    #     stub_subflag(:max_projects, 100)
    #     expect(subflag_value(:max_projects, default: 3)).to eq(100)
    #   end
    #
    module TestHelpers
      # Stub a flag to return a specific value
      #
      # @param flag_name [Symbol, String] The flag name (underscores or dashes)
      # @param value [Object] The value to return
      #
      # @example Boolean
      #   stub_subflag(:new_checkout, true)
      #
      # @example String
      #   stub_subflag(:headline, "Welcome!")
      #
      # @example Integer
      #   stub_subflag(:max_projects, 100)
      #
      # @example Hash
      #   stub_subflag(:limits, { max_items: 50 })
      #
      def stub_subflag(flag_name, value)
        flag_key = normalize_flag_key(flag_name)
        stubbed_flags[flag_key] = value
      end

      # Stub multiple flags at once
      #
      # @param flags [Hash] Flag names to values
      #
      # @example
      #   stub_subflags(
      #     new_checkout: true,
      #     max_projects: 100,
      #     headline: "Welcome!"
      #   )
      #
      def stub_subflags(flags)
        flags.each { |name, value| stub_subflag(name, value) }
      end

      # Clear all stubbed flags
      def clear_stubbed_subflags
        stubbed_flags.clear
      end

      private

      def stubbed_flags
        @stubbed_flags ||= {}
      end

      def normalize_flag_key(flag_name)
        flag_name.to_s.tr("_", "-")
      end
    end

    # Stubbed client that returns test values
    class StubbedClient
      def initialize(stubs)
        @stubs = stubs
      end

      def enabled?(flag_key, user: nil, context: nil, default: false)
        @stubs.fetch(flag_key, default)
      end

      def value(flag_key, user: nil, context: nil, default:)
        @stubs.fetch(flag_key, default)
      end

      def evaluate(flag_key, user: nil, context: nil, default:)
        value = @stubs.fetch(flag_key, default)
        EvaluationResult.new(
          value: value,
          variant: "stubbed",
          reason: @stubs.key?(flag_key) ? :static : :default,
          flag_key: flag_key
        )
      end
    end
  end
end

# Patch FlagAccessor to use stubbed values in tests
module Subflag
  module Rails
    class FlagAccessor
      private

      alias_method :original_client, :client

      def client
        if test_stubs_active?
          StubbedClient.new(current_test_stubs)
        else
          original_client
        end
      end

      def test_stubs_active?
        Thread.current[:subflag_test_stubs].is_a?(Hash) &&
          !Thread.current[:subflag_test_stubs].empty?
      end

      def current_test_stubs
        Thread.current[:subflag_test_stubs] || {}
      end
    end

    # Update TestHelpers to use thread-local storage
    module TestHelpers
      private

      def stubbed_flags
        Thread.current[:subflag_test_stubs] ||= {}
      end
    end
  end
end
