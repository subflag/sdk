# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Backend integration" do
  describe "memory backend" do
    before do
      Subflag::Rails.configure do |config|
        config.backend = :memory
      end
    end

    it "uses MemoryProvider" do
      expect(Subflag::Rails.provider).to be_a(Subflag::Rails::Backends::MemoryProvider)
    end

    it "allows setting flags via provider" do
      Subflag::Rails.provider.set(:test_flag, true)

      client = Subflag::Rails.client
      expect(client.enabled?("test-flag", default: false)).to eq(true)
    end

    it "returns default when flag not set" do
      client = Subflag::Rails.client
      expect(client.value("missing-flag", default: "fallback")).to eq("fallback")
    end
  end

  describe "subflag backend without api_key" do
    before do
      Subflag::Rails.configure do |config|
        config.backend = :subflag
        config.api_key = nil
      end
    end

    it "does not create a provider" do
      expect(Subflag::Rails.provider).to be_nil
    end
  end
end
