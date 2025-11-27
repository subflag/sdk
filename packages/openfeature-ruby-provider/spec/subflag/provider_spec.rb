# frozen_string_literal: true

require "spec_helper"

RSpec.describe Subflag::Provider do
  let(:provider) { described_class.new(api_url: TestHelpers::API_URL, api_key: TestHelpers::API_KEY) }

  describe "#metadata" do
    it "returns provider name" do
      expect(provider.metadata).to eq({ name: "Subflag Ruby Provider" })
    end
  end

  describe "#init" do
    it "does not raise" do
      expect { provider.init }.not_to raise_error
    end
  end

  describe "#shutdown" do
    it "does not raise" do
      expect { provider.shutdown }.not_to raise_error
    end
  end

  describe "#fetch_boolean_value" do
    context "when successful" do
      it "returns resolution details with boolean value" do
        stub_evaluate(
          flag_key: "bool-flag",
          response: success_response(flag_key: "bool-flag", value: true, variant: "enabled")
        )

        result = provider.fetch_boolean_value(flag_key: "bool-flag", default_value: false)

        expect(result[:value]).to eq(true)
        expect(result[:variant]).to eq("enabled")
        expect(result[:reason]).to eq(:default)
        expect(result[:flag_metadata]).to eq({ flag_key: "bool-flag" })
      end

      it "handles false values correctly" do
        stub_evaluate(
          flag_key: "disabled-flag",
          response: success_response(flag_key: "disabled-flag", value: false, variant: "disabled")
        )

        result = provider.fetch_boolean_value(flag_key: "disabled-flag", default_value: true)

        expect(result[:value]).to eq(false)
      end
    end

    context "when type mismatch" do
      it "returns default value with type_mismatch error" do
        stub_evaluate(
          flag_key: "string-flag",
          response: success_response(flag_key: "string-flag", value: "not a bool", variant: "text")
        )

        result = provider.fetch_boolean_value(flag_key: "string-flag", default_value: false)

        expect(result[:value]).to eq(false)
        expect(result[:reason]).to eq(:error)
        expect(result[:error_code]).to eq(:type_mismatch)
      end
    end

    context "when flag not found" do
      it "returns default value with flag_not_found error" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/unknown")
          .to_return(status: 404, body: { message: "Flag not found" }.to_json)

        result = provider.fetch_boolean_value(flag_key: "unknown", default_value: true)

        expect(result[:value]).to eq(true)
        expect(result[:reason]).to eq(:error)
        expect(result[:error_code]).to eq(:flag_not_found)
      end
    end

    context "when authentication fails" do
      it "returns default value with invalid_context error" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/my-flag")
          .to_return(status: 401, body: { message: "Invalid API key" }.to_json)

        result = provider.fetch_boolean_value(flag_key: "my-flag", default_value: false)

        expect(result[:value]).to eq(false)
        expect(result[:reason]).to eq(:error)
        expect(result[:error_code]).to eq(:invalid_context)
      end
    end

    context "with evaluation context" do
      it "forwards context to API" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/targeted-flag")
          .with(body: hash_including(targetingKey: "user-123"))
          .to_return(
            status: 200,
            body: success_response(flag_key: "targeted-flag", value: true, reason: "TARGETING_MATCH").to_json,
            headers: { "Content-Type" => "application/json" }
          )

        context = { targeting_key: "user-123", plan: "premium" }
        result = provider.fetch_boolean_value(
          flag_key: "targeted-flag",
          default_value: false,
          evaluation_context: context
        )

        expect(result[:value]).to eq(true)
        expect(result[:reason]).to eq(:targeting_match)
      end
    end
  end

  describe "#fetch_string_value" do
    it "returns string value" do
      stub_evaluate(
        flag_key: "string-flag",
        response: success_response(flag_key: "string-flag", value: "hello", variant: "greeting")
      )

      result = provider.fetch_string_value(flag_key: "string-flag", default_value: "default")

      expect(result[:value]).to eq("hello")
    end

    it "returns default on type mismatch" do
      stub_evaluate(
        flag_key: "bool-flag",
        response: success_response(flag_key: "bool-flag", value: true)
      )

      result = provider.fetch_string_value(flag_key: "bool-flag", default_value: "default")

      expect(result[:value]).to eq("default")
      expect(result[:error_code]).to eq(:type_mismatch)
    end
  end

  describe "#fetch_number_value" do
    it "returns numeric value" do
      stub_evaluate(
        flag_key: "number-flag",
        response: success_response(flag_key: "number-flag", value: 42.5)
      )

      result = provider.fetch_number_value(flag_key: "number-flag", default_value: 0)

      expect(result[:value]).to eq(42.5)
    end

    it "accepts integer as number" do
      stub_evaluate(
        flag_key: "int-flag",
        response: success_response(flag_key: "int-flag", value: 42)
      )

      result = provider.fetch_number_value(flag_key: "int-flag", default_value: 0)

      expect(result[:value]).to eq(42)
    end
  end

  describe "#fetch_integer_value" do
    it "returns integer value" do
      stub_evaluate(
        flag_key: "int-flag",
        response: success_response(flag_key: "int-flag", value: 42)
      )

      result = provider.fetch_integer_value(flag_key: "int-flag", default_value: 0)

      expect(result[:value]).to eq(42)
    end

    it "converts float to integer" do
      stub_evaluate(
        flag_key: "float-flag",
        response: success_response(flag_key: "float-flag", value: 42.9)
      )

      result = provider.fetch_integer_value(flag_key: "float-flag", default_value: 0)

      expect(result[:value]).to eq(42)
    end
  end

  describe "#fetch_float_value" do
    it "returns float value" do
      stub_evaluate(
        flag_key: "float-flag",
        response: success_response(flag_key: "float-flag", value: 3.14)
      )

      result = provider.fetch_float_value(flag_key: "float-flag", default_value: 0.0)

      expect(result[:value]).to eq(3.14)
    end

    it "converts integer to float" do
      stub_evaluate(
        flag_key: "int-flag",
        response: success_response(flag_key: "int-flag", value: 42)
      )

      result = provider.fetch_float_value(flag_key: "int-flag", default_value: 0.0)

      expect(result[:value]).to eq(42.0)
    end
  end

  describe "#fetch_object_value" do
    it "returns object/hash value" do
      stub_evaluate(
        flag_key: "config-flag",
        response: success_response(flag_key: "config-flag", value: { "theme" => "dark", "limit" => 100 })
      )

      result = provider.fetch_object_value(flag_key: "config-flag", default_value: {})

      expect(result[:value]).to eq({ "theme" => "dark", "limit" => 100 })
    end

    it "returns default on type mismatch" do
      stub_evaluate(
        flag_key: "string-flag",
        response: success_response(flag_key: "string-flag", value: "not an object")
      )

      result = provider.fetch_object_value(flag_key: "string-flag", default_value: { "default" => true })

      expect(result[:value]).to eq({ "default" => true })
      expect(result[:error_code]).to eq(:type_mismatch)
    end
  end

  describe "reason mapping" do
    it "maps DEFAULT to :default" do
      stub_evaluate(
        flag_key: "flag",
        response: success_response(flag_key: "flag", value: true, reason: "DEFAULT")
      )

      result = provider.fetch_boolean_value(flag_key: "flag", default_value: false)

      expect(result[:reason]).to eq(:default)
    end

    it "maps TARGETING_MATCH to :targeting_match" do
      stub_evaluate(
        flag_key: "flag",
        response: success_response(flag_key: "flag", value: true, reason: "TARGETING_MATCH")
      )

      result = provider.fetch_boolean_value(flag_key: "flag", default_value: false)

      expect(result[:reason]).to eq(:targeting_match)
    end

    it "maps SEGMENT_MATCH to :targeting_match" do
      stub_evaluate(
        flag_key: "flag",
        response: success_response(flag_key: "flag", value: true, reason: "SEGMENT_MATCH")
      )

      result = provider.fetch_boolean_value(flag_key: "flag", default_value: false)

      expect(result[:reason]).to eq(:targeting_match)
    end

    it "maps OVERRIDE to :static" do
      stub_evaluate(
        flag_key: "flag",
        response: success_response(flag_key: "flag", value: true, reason: "OVERRIDE")
      )

      result = provider.fetch_boolean_value(flag_key: "flag", default_value: false)

      expect(result[:reason]).to eq(:static)
    end

    it "maps PERCENTAGE_ROLLOUT to :split" do
      stub_evaluate(
        flag_key: "flag",
        response: success_response(flag_key: "flag", value: true, reason: "PERCENTAGE_ROLLOUT")
      )

      result = provider.fetch_boolean_value(flag_key: "flag", default_value: false)

      expect(result[:reason]).to eq(:split)
    end

    it "maps ERROR to :error" do
      stub_evaluate(
        flag_key: "flag",
        response: success_response(flag_key: "flag", value: true, reason: "ERROR")
      )

      result = provider.fetch_boolean_value(flag_key: "flag", default_value: false)

      expect(result[:reason]).to eq(:error)
    end
  end

  describe "error handling" do
    it "handles network timeout gracefully" do
      stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/flag")
        .to_raise(Faraday::TimeoutError.new("timeout"))

      result = provider.fetch_boolean_value(flag_key: "flag", default_value: true)

      expect(result[:value]).to eq(true)
      expect(result[:reason]).to eq(:error)
      expect(result[:error_code]).to eq(:general)
    end

    it "handles connection error gracefully" do
      stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/flag")
        .to_raise(Faraday::ConnectionFailed.new("connection refused"))

      result = provider.fetch_boolean_value(flag_key: "flag", default_value: false)

      expect(result[:value]).to eq(false)
      expect(result[:reason]).to eq(:error)
      expect(result[:error_code]).to eq(:general)
    end
  end
end
