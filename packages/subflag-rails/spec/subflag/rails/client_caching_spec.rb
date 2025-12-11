# frozen_string_literal: true

require "spec_helper"

RSpec.describe Subflag::Rails::Client do
  let(:client) { described_class.new }

  before do
    configure_subflag
  end

  describe "configuration" do
    describe "#rails_cache_enabled?" do
      it "returns false when cache_ttl is nil" do
        Subflag::Rails.configuration.cache_ttl = nil
        expect(Subflag::Rails.configuration.rails_cache_enabled?).to be false
      end

      it "returns false when cache_ttl is 0" do
        Subflag::Rails.configuration.cache_ttl = 0
        expect(Subflag::Rails.configuration.rails_cache_enabled?).to be false
      end

      it "returns true when cache_ttl is set and Rails.cache is present" do
        Subflag::Rails.configuration.cache_ttl = 30
        expect(Subflag::Rails.configuration.rails_cache_enabled?).to be true
      end
    end
  end

  describe "#prefetch_all" do
    context "with memory backend" do
      before do
        Subflag::Rails.configure do |config|
          config.backend = :memory
        end
        Subflag::Rails.provider.set(:feature_a, true)
        Subflag::Rails.provider.set(:feature_b, "hello")
      end

      it "returns empty array (memory is already in-memory)" do
        result = client.prefetch_all
        expect(result).to eq([])
      end
    end

    context "caching behavior" do
      before do
        Subflag::Rails::RequestCache.start
        Subflag::Rails.configure do |config|
          config.backend = :memory
        end
        Subflag::Rails.provider.set(:cached_flag, 42)
      end

      after do
        Subflag::Rails::RequestCache.clear
      end

      it "caches individual flag lookups within a request" do
        # First call
        result1 = client.value("cached-flag", default: 0)
        # Change the underlying value
        Subflag::Rails.provider.set(:cached_flag, 999)
        # Second call should return cached value (not the new value)
        result2 = client.value("cached-flag", default: 0)

        expect(result1).to eq(42)
        expect(result2).to eq(42)
      end

      it "does not cache across different flag keys" do
        Subflag::Rails.provider.set(:flag_one, "first")
        Subflag::Rails.provider.set(:flag_two, "second")

        result1 = client.value("flag-one", default: "")
        result2 = client.value("flag-two", default: "")

        expect(result1).to eq("first")
        expect(result2).to eq("second")
      end
    end
  end
end
