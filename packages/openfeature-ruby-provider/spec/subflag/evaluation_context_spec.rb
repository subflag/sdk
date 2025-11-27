# frozen_string_literal: true

require "spec_helper"

RSpec.describe Subflag::EvaluationContext do
  describe "#initialize" do
    it "creates empty context" do
      context = described_class.new

      expect(context.targeting_key).to be_nil
      expect(context.kind).to be_nil
      expect(context.attributes).to eq({})
    end

    it "accepts targeting_key" do
      context = described_class.new(targeting_key: "user-123")

      expect(context.targeting_key).to eq("user-123")
    end

    it "accepts kind" do
      context = described_class.new(kind: "organization")

      expect(context.kind).to eq("organization")
    end

    it "accepts attributes" do
      context = described_class.new(attributes: { plan: "premium", country: "US" })

      expect(context.attributes).to eq({ plan: "premium", country: "US" })
    end

    it "defaults attributes to empty hash when nil" do
      context = described_class.new(attributes: nil)

      expect(context.attributes).to eq({})
    end
  end

  describe "#to_h" do
    it "converts to hash with camelCase keys" do
      context = described_class.new(
        targeting_key: "user-123",
        kind: "user",
        attributes: { plan: "premium" }
      )

      expect(context.to_h).to eq({
                                   targetingKey: "user-123",
                                   kind: "user",
                                   attributes: { plan: "premium" }
                                 })
    end

    it "omits nil values" do
      context = described_class.new(targeting_key: "user-123")

      result = context.to_h

      expect(result).to eq({ targetingKey: "user-123" })
      expect(result).not_to have_key(:kind)
      expect(result).not_to have_key(:attributes)
    end

    it "omits empty attributes" do
      context = described_class.new(targeting_key: "user-123", attributes: {})

      result = context.to_h

      expect(result).not_to have_key(:attributes)
    end
  end

  describe ".from_openfeature" do
    it "handles nil context" do
      context = described_class.from_openfeature(nil)

      expect(context.targeting_key).to be_nil
      expect(context.kind).to be_nil
      expect(context.attributes).to eq({})
    end

    it "converts hash with symbol keys" do
      openfeature_context = {
        targeting_key: "user-456",
        plan: "enterprise",
        country: "UK"
      }

      context = described_class.from_openfeature(openfeature_context)

      expect(context.targeting_key).to eq("user-456")
      expect(context.kind).to eq("user")
      expect(context.attributes).to eq({ plan: "enterprise", country: "UK" })
    end

    it "converts hash with string keys" do
      openfeature_context = {
        "targeting_key" => "user-789",
        "plan" => "free"
      }

      context = described_class.from_openfeature(openfeature_context)

      expect(context.targeting_key).to eq("user-789")
      expect(context.attributes).to eq({ plan: "free" })
    end

    it "excludes targeting_key from attributes" do
      openfeature_context = {
        targeting_key: "user-123",
        extra: "value"
      }

      context = described_class.from_openfeature(openfeature_context)

      expect(context.attributes).not_to have_key(:targeting_key)
      expect(context.attributes).to eq({ extra: "value" })
    end

    it "handles object with to_h method" do
      mock_context = double("OpenFeatureContext")
      allow(mock_context).to receive(:to_h).and_return({ targeting_key: "user-abc" })

      context = described_class.from_openfeature(mock_context)

      expect(context.targeting_key).to eq("user-abc")
    end

    it "handles object without to_h or hash behavior" do
      invalid_context = "not a context"

      context = described_class.from_openfeature(invalid_context)

      expect(context.targeting_key).to be_nil
      expect(context.attributes).to eq({})
    end

    it "defaults kind to 'user'" do
      openfeature_context = { targeting_key: "user-123" }

      context = described_class.from_openfeature(openfeature_context)

      expect(context.kind).to eq("user")
    end
  end
end
