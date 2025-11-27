# frozen_string_literal: true

require "spec_helper"

RSpec.describe Subflag::EvaluationResult do
  describe ".from_response" do
    it "parses API response" do
      response = {
        "flagKey" => "test-flag",
        "value" => "hello",
        "variant" => "greeting",
        "reason" => "TARGETING_MATCH"
      }

      result = described_class.from_response(response)

      expect(result.flag_key).to eq("test-flag")
      expect(result.value).to eq("hello")
      expect(result.variant).to eq("greeting")
      expect(result.reason).to eq("TARGETING_MATCH")
    end
  end

  describe "#success?" do
    it "returns false for ERROR reason" do
      result = described_class.new(flag_key: "f", value: true, variant: "v", reason: "ERROR")
      expect(result.success?).to eq(false)
    end

    it "returns true for other reasons" do
      result = described_class.new(flag_key: "f", value: true, variant: "v", reason: "DEFAULT")
      expect(result.success?).to eq(true)
    end
  end
end
