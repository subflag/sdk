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
    let(:api_response) do
      [
        { "flagKey" => "feature-a", "value" => true, "variant" => "enabled", "reason" => "DEFAULT" },
        { "flagKey" => "feature-b", "value" => "hello", "variant" => "greeting", "reason" => "TARGETING_MATCH" }
      ]
    end

    before do
      # Stub the API call
      stub_request(:post, "https://api.subflag.com/sdk/evaluate-all")
        .to_return(
          status: 200,
          body: api_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    context "without Rails.cache (cache_ttl not set)" do
      it "fetches from API on every call" do
        result = client.prefetch_all

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(a_request(:post, "https://api.subflag.com/sdk/evaluate-all")).to have_been_made.once
      end
    end

    context "with Rails.cache (cache_ttl set)" do
      before do
        Subflag::Rails.configuration.cache_ttl = 30
      end

      it "caches results in Rails.cache" do
        # First call - should hit API
        client.prefetch_all

        # Second call - should use cache
        client.prefetch_all

        # API should only be called once
        expect(a_request(:post, "https://api.subflag.com/sdk/evaluate-all")).to have_been_made.once
      end

      it "returns cached results on subsequent calls" do
        first_result = client.prefetch_all
        second_result = client.prefetch_all

        expect(first_result).to eq(second_result)
      end

      it "uses different cache keys for different contexts" do
        user1 = double("User1", id: 1, email: "user1@example.com")
        user2 = double("User2", id: 2, email: "user2@example.com")

        Subflag::Rails.configure do |config|
          config.api_key = "sdk-test-key"
          config.cache_ttl = 30
          config.user_context do |u|
            { targeting_key: u.id.to_s, email: u.email }
          end
        end

        # Prefetch for user1
        client.prefetch_all(user: user1)
        # Prefetch for user2 - should hit API again (different context)
        client.prefetch_all(user: user2)

        expect(a_request(:post, "https://api.subflag.com/sdk/evaluate-all")).to have_been_made.twice
      end
    end

    context "populating RequestCache" do
      before do
        Subflag::Rails::RequestCache.start
      end

      after do
        Subflag::Rails::RequestCache.clear
      end

      it "populates RequestCache for subsequent lookups" do
        Subflag::Rails.configuration.cache_ttl = 30
        client.prefetch_all

        # Check that RequestCache has the prefetched values
        cache = Subflag::Rails::RequestCache.current_cache
        expect(cache.keys.any? { |k| k.include?("prefetch:feature-a") }).to be true
        expect(cache.keys.any? { |k| k.include?("prefetch:feature-b") }).to be true
      end
    end
  end
end
