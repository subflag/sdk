# frozen_string_literal: true

require "spec_helper"

RSpec.describe Subflag::Rails::FlagAccessor do
  before do
    configure_subflag
  end

  describe "#method_missing" do
    context "boolean flags (? suffix)" do
      it "returns true when flag is enabled" do
        stub_flag_evaluation(flag_key: "new-checkout", value: true)

        flags = described_class.new
        expect(flags.new_checkout?).to be true
      end

      it "returns false when flag is disabled" do
        stub_flag_evaluation(flag_key: "new-checkout", value: false)

        flags = described_class.new
        expect(flags.new_checkout?).to be false
      end

      it "converts underscores to dashes" do
        stub_flag_evaluation(flag_key: "new-checkout", value: true)

        flags = described_class.new
        expect(flags.new_checkout?).to be true
      end

      it "uses default: false when not specified" do
        stub_request(:post, %r{/sdk/evaluate/new-checkout})
          .to_return(status: 404, body: { error: "not found" }.to_json)

        flags = described_class.new
        expect(flags.new_checkout?).to be false
      end
    end

    context "value flags" do
      it "returns string values" do
        stub_flag_evaluation(flag_key: "headline", value: "Welcome!")

        flags = described_class.new
        expect(flags.headline(default: "Default")).to eq("Welcome!")
      end

      it "returns integer values" do
        stub_flag_evaluation(flag_key: "max-projects", value: 100)

        flags = described_class.new
        expect(flags.max_projects(default: 3)).to eq(100)
      end

      it "raises ArgumentError when default is not provided" do
        flags = described_class.new
        expect { flags.headline }.to raise_error(ArgumentError, /default is required/)
      end

      it "converts underscores to dashes" do
        stub_flag_evaluation(flag_key: "max-api-requests", value: 1000)

        flags = described_class.new
        expect(flags.max_api_requests(default: 100)).to eq(1000)
      end
    end
  end

  describe "#[]" do
    it "uses exact flag name without conversion" do
      stub_flag_evaluation(flag_key: "my-exact-flag", value: "value")

      flags = described_class.new
      expect(flags["my-exact-flag", default: "default"]).to eq("value")
    end

    it "requires default parameter" do
      flags = described_class.new
      expect { flags["flag"] }.to raise_error(ArgumentError)
    end
  end

  describe "#evaluate" do
    it "returns full evaluation result" do
      stub_flag_evaluation(
        flag_key: "max-projects",
        value: 100,
        variant: "premium",
        reason: "TARGETING_MATCH"
      )

      flags = described_class.new
      result = flags.evaluate(:max_projects, default: 3)

      expect(result).to be_a(Subflag::Rails::EvaluationResult)
      expect(result.value).to eq(100)
      expect(result.variant).to eq("premium")
      expect(result.reason).to eq(:targeting_match)
      expect(result.flag_key).to eq("max-projects")
    end
  end

  describe "with user context" do
    it "passes user to evaluation" do
      user = double("User", id: 123, email: "test@example.com")

      Subflag::Rails.configure do |config|
        config.api_key = "sdk-test-key"
        config.user_context do |u|
          { targeting_key: u.id.to_s, email: u.email }
        end
      end

      stub_request(:post, %r{/sdk/evaluate/new-checkout})
        .with(body: hash_including("targetingKey" => "123"))
        .to_return(
          status: 200,
          body: { flagKey: "new-checkout", value: true, reason: "TARGETING_MATCH" }.to_json
        )

      flags = described_class.new(user: user)
      expect(flags.new_checkout?).to be true
    end
  end
end
