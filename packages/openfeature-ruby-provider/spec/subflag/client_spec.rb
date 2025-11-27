# frozen_string_literal: true

require "spec_helper"

RSpec.describe Subflag::Client do
  let(:client) { described_class.new(api_url: TestHelpers::API_URL, api_key: TestHelpers::API_KEY) }

  describe "#initialize" do
    it "sets the api_url" do
      expect(client.api_url).to eq(TestHelpers::API_URL)
    end

    it "sets the api_key" do
      expect(client.api_key).to eq(TestHelpers::API_KEY)
    end

    it "sets the default timeout" do
      expect(client.timeout).to eq(5)
    end

    it "accepts custom timeout" do
      custom_client = described_class.new(
        api_url: TestHelpers::API_URL,
        api_key: TestHelpers::API_KEY,
        timeout: 10
      )
      expect(custom_client.timeout).to eq(10)
    end

    it "strips trailing slash from api_url" do
      custom_client = described_class.new(
        api_url: "#{TestHelpers::API_URL}/",
        api_key: TestHelpers::API_KEY
      )
      expect(custom_client.api_url).to eq(TestHelpers::API_URL)
    end
  end

  describe "#evaluate" do
    context "when successful" do
      it "returns an EvaluationResult for boolean flag" do
        stub_evaluate(
          flag_key: "bool-flag",
          response: success_response(flag_key: "bool-flag", value: true, variant: "enabled")
        )

        result = client.evaluate("bool-flag")

        expect(result).to be_a(Subflag::EvaluationResult)
        expect(result.flag_key).to eq("bool-flag")
        expect(result.value).to eq(true)
        expect(result.variant).to eq("enabled")
        expect(result.reason).to eq("DEFAULT")
      end

      it "returns an EvaluationResult for string flag" do
        stub_evaluate(
          flag_key: "string-flag",
          response: success_response(flag_key: "string-flag", value: "hello", variant: "greeting")
        )

        result = client.evaluate("string-flag")

        expect(result.value).to eq("hello")
        expect(result.variant).to eq("greeting")
      end

      it "returns an EvaluationResult for number flag" do
        stub_evaluate(
          flag_key: "number-flag",
          response: success_response(flag_key: "number-flag", value: 42.5, variant: "answer")
        )

        result = client.evaluate("number-flag")

        expect(result.value).to eq(42.5)
      end

      it "returns an EvaluationResult for object flag" do
        stub_evaluate(
          flag_key: "object-flag",
          response: success_response(flag_key: "object-flag", value: { "key" => "value" }, variant: "config")
        )

        result = client.evaluate("object-flag")

        expect(result.value).to eq({ "key" => "value" })
      end

      it "includes evaluation reason" do
        stub_evaluate(
          flag_key: "targeted-flag",
          response: success_response(flag_key: "targeted-flag", value: true, reason: "TARGETING_MATCH")
        )

        result = client.evaluate("targeted-flag")

        expect(result.reason).to eq("TARGETING_MATCH")
      end
    end

    context "with evaluation context" do
      it "sends context in request body" do
        context = Subflag::EvaluationContext.new(
          targeting_key: "user-123",
          kind: "user",
          attributes: { plan: "premium" }
        )

        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/my-flag")
          .with(
            body: { targetingKey: "user-123", kind: "user", attributes: { plan: "premium" } }.to_json,
            headers: { "X-Subflag-API-Key" => TestHelpers::API_KEY }
          )
          .to_return(
            status: 200,
            body: success_response(flag_key: "my-flag", value: true).to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.evaluate("my-flag", context: context)

        expect(result.value).to eq(true)
      end
    end

    context "when flag not found" do
      it "raises FlagNotFoundError" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/unknown-flag")
          .to_return(status: 404, body: { message: "Flag not found" }.to_json)

        expect { client.evaluate("unknown-flag") }.to raise_error(Subflag::FlagNotFoundError) do |error|
          expect(error.flag_key).to eq("unknown-flag")
          expect(error.status).to eq(404)
        end
      end
    end

    context "when authentication fails" do
      it "raises AuthenticationError for 401" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/my-flag")
          .to_return(status: 401, body: { message: "Invalid API key" }.to_json)

        expect { client.evaluate("my-flag") }.to raise_error(Subflag::AuthenticationError) do |error|
          expect(error.status).to eq(401)
        end
      end

      it "raises AuthenticationError for 403" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/my-flag")
          .to_return(status: 403, body: { message: "Forbidden" }.to_json)

        expect { client.evaluate("my-flag") }.to raise_error(Subflag::AuthenticationError)
      end
    end

    context "when server error occurs" do
      it "raises ApiError for 500" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/my-flag")
          .to_return(status: 500, body: { message: "Internal server error" }.to_json)

        expect { client.evaluate("my-flag") }.to raise_error(Subflag::ApiError) do |error|
          expect(error.status).to eq(500)
        end
      end
    end

    context "when network error occurs" do
      it "raises ConnectionError" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/my-flag")
          .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

        expect { client.evaluate("my-flag") }.to raise_error(Subflag::ConnectionError)
      end

      it "raises TimeoutError" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/my-flag")
          .to_raise(Faraday::TimeoutError.new("Request timed out"))

        expect { client.evaluate("my-flag") }.to raise_error(Subflag::TimeoutError)
      end
    end

    context "with special characters in flag key" do
      it "URL encodes the flag key" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate/my%2Fflag%3Ftest")
          .to_return(
            status: 200,
            body: success_response(flag_key: "my/flag?test", value: true).to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = client.evaluate("my/flag?test")

        expect(result.value).to eq(true)
      end
    end
  end

  describe "#evaluate_all" do
    context "when successful" do
      it "returns array of EvaluationResults" do
        stub_evaluate_all(
          response: [
            success_response(flag_key: "flag-1", value: true),
            success_response(flag_key: "flag-2", value: "hello"),
            success_response(flag_key: "flag-3", value: 42)
          ]
        )

        results = client.evaluate_all

        expect(results.length).to eq(3)
        expect(results[0].flag_key).to eq("flag-1")
        expect(results[0].value).to eq(true)
        expect(results[1].flag_key).to eq("flag-2")
        expect(results[1].value).to eq("hello")
        expect(results[2].flag_key).to eq("flag-3")
        expect(results[2].value).to eq(42)
      end

      it "returns empty array when no flags" do
        stub_evaluate_all(response: [])

        results = client.evaluate_all

        expect(results).to eq([])
      end
    end

    context "when authentication fails" do
      it "raises AuthenticationError" do
        stub_request(:post, "#{TestHelpers::API_URL}/sdk/evaluate-all")
          .to_return(status: 401, body: { message: "Invalid API key" }.to_json)

        expect { client.evaluate_all }.to raise_error(Subflag::AuthenticationError)
      end
    end
  end
end
