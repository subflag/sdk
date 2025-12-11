# frozen_string_literal: true

require "spec_helper"
require "subflag/rails/targeting"

RSpec.describe Subflag::Rails::TargetingEngine do
  describe ".evaluate" do
    context "with no rules" do
      it "returns nil" do
        expect(described_class.evaluate(nil, { email: "test@example.com" })).to be_nil
        expect(described_class.evaluate([], { email: "test@example.com" })).to be_nil
      end
    end

    context "with no context" do
      it "returns nil" do
        rules = [{ "value" => "matched", "conditions" => { "type" => "AND", "conditions" => [] } }]
        expect(described_class.evaluate(rules, nil)).to be_nil
        expect(described_class.evaluate(rules, {})).to be_nil
      end
    end

    context "with EQUALS operator" do
      let(:rules) do
        [{
          "value" => "admin-value",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "role", "operator" => "EQUALS", "value" => "admin" }
            ]
          }
        }]
      end

      it "matches when attribute equals value" do
        expect(described_class.evaluate(rules, { role: "admin" })).to eq("admin-value")
      end

      it "does not match when attribute differs" do
        expect(described_class.evaluate(rules, { role: "user" })).to be_nil
      end

      it "handles symbol/string conversion" do
        expect(described_class.evaluate(rules, { "role" => "admin" })).to eq("admin-value")
        expect(described_class.evaluate(rules, { role: :admin })).to eq("admin-value")
      end
    end

    context "with NOT_EQUALS operator" do
      let(:rules) do
        [{
          "value" => "non-admin",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "role", "operator" => "NOT_EQUALS", "value" => "admin" }
            ]
          }
        }]
      end

      it "matches when attribute does not equal value" do
        expect(described_class.evaluate(rules, { role: "user" })).to eq("non-admin")
      end

      it "does not match when attribute equals value" do
        expect(described_class.evaluate(rules, { role: "admin" })).to be_nil
      end
    end

    context "with IN operator" do
      let(:rules) do
        [{
          "value" => "internal",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "role", "operator" => "IN", "value" => ["admin", "developer", "qa"] }
            ]
          }
        }]
      end

      it "matches when attribute is in array" do
        expect(described_class.evaluate(rules, { role: "admin" })).to eq("internal")
        expect(described_class.evaluate(rules, { role: "developer" })).to eq("internal")
        expect(described_class.evaluate(rules, { role: "qa" })).to eq("internal")
      end

      it "does not match when attribute is not in array" do
        expect(described_class.evaluate(rules, { role: "user" })).to be_nil
      end
    end

    context "with NOT_IN operator" do
      let(:rules) do
        [{
          "value" => "allowed",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "country", "operator" => "NOT_IN", "value" => ["RU", "CN"] }
            ]
          }
        }]
      end

      it "matches when attribute is not in array" do
        expect(described_class.evaluate(rules, { country: "US" })).to eq("allowed")
      end

      it "does not match when attribute is in array" do
        expect(described_class.evaluate(rules, { country: "RU" })).to be_nil
      end
    end

    context "with ENDS_WITH operator" do
      let(:rules) do
        [{
          "value" => "company-user",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" }
            ]
          }
        }]
      end

      it "matches when attribute ends with value" do
        expect(described_class.evaluate(rules, { email: "alice@company.com" })).to eq("company-user")
      end

      it "does not match when attribute does not end with value" do
        expect(described_class.evaluate(rules, { email: "alice@gmail.com" })).to be_nil
      end
    end

    context "with STARTS_WITH operator" do
      let(:rules) do
        [{
          "value" => "test-user",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "user_id", "operator" => "STARTS_WITH", "value" => "test-" }
            ]
          }
        }]
      end

      it "matches when attribute starts with value" do
        expect(described_class.evaluate(rules, { user_id: "test-123" })).to eq("test-user")
      end

      it "does not match when attribute does not start with value" do
        expect(described_class.evaluate(rules, { user_id: "prod-123" })).to be_nil
      end
    end

    context "with CONTAINS operator" do
      let(:rules) do
        [{
          "value" => "beta-user",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "email", "operator" => "CONTAINS", "value" => "+beta" }
            ]
          }
        }]
      end

      it "matches when attribute contains value" do
        expect(described_class.evaluate(rules, { email: "alice+beta@example.com" })).to eq("beta-user")
      end

      it "does not match when attribute does not contain value" do
        expect(described_class.evaluate(rules, { email: "alice@example.com" })).to be_nil
      end
    end

    context "with GREATER_THAN operator" do
      let(:rules) do
        [{
          "value" => "premium",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "age", "operator" => "GREATER_THAN", "value" => 18 }
            ]
          }
        }]
      end

      it "matches when attribute is greater than value" do
        expect(described_class.evaluate(rules, { age: 21 })).to eq("premium")
      end

      it "does not match when attribute is equal to value" do
        expect(described_class.evaluate(rules, { age: 18 })).to be_nil
      end

      it "does not match when attribute is less than value" do
        expect(described_class.evaluate(rules, { age: 16 })).to be_nil
      end
    end

    context "with MATCHES operator" do
      let(:rules) do
        [{
          "value" => "internal",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "email", "operator" => "MATCHES", "value" => ".*@(company|internal)\\.com$" }
            ]
          }
        }]
      end

      it "matches when attribute matches regex" do
        expect(described_class.evaluate(rules, { email: "alice@company.com" })).to eq("internal")
        expect(described_class.evaluate(rules, { email: "bob@internal.com" })).to eq("internal")
      end

      it "does not match when attribute does not match regex" do
        expect(described_class.evaluate(rules, { email: "alice@gmail.com" })).to be_nil
      end
    end

    context "with OR logic" do
      let(:rules) do
        [{
          "value" => "special",
          "conditions" => {
            "type" => "OR",
            "conditions" => [
              { "attribute" => "role", "operator" => "EQUALS", "value" => "admin" },
              { "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" }
            ]
          }
        }]
      end

      it "matches when any condition is true" do
        expect(described_class.evaluate(rules, { role: "admin", email: "alice@gmail.com" })).to eq("special")
        expect(described_class.evaluate(rules, { role: "user", email: "alice@company.com" })).to eq("special")
      end

      it "does not match when all conditions are false" do
        expect(described_class.evaluate(rules, { role: "user", email: "alice@gmail.com" })).to be_nil
      end
    end

    context "with AND logic" do
      let(:rules) do
        [{
          "value" => "enterprise-admin",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "role", "operator" => "EQUALS", "value" => "admin" },
              { "attribute" => "plan", "operator" => "EQUALS", "value" => "enterprise" }
            ]
          }
        }]
      end

      it "matches when all conditions are true" do
        expect(described_class.evaluate(rules, { role: "admin", plan: "enterprise" })).to eq("enterprise-admin")
      end

      it "does not match when any condition is false" do
        expect(described_class.evaluate(rules, { role: "admin", plan: "free" })).to be_nil
        expect(described_class.evaluate(rules, { role: "user", plan: "enterprise" })).to be_nil
      end
    end

    context "with multiple rules (first match wins)" do
      let(:rules) do
        [
          {
            "value" => "unlimited",
            "conditions" => {
              "type" => "AND",
              "conditions" => [
                { "attribute" => "role", "operator" => "EQUALS", "value" => "admin" }
              ]
            }
          },
          {
            "value" => "100",
            "conditions" => {
              "type" => "AND",
              "conditions" => [
                { "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" }
              ]
            }
          },
          {
            "value" => "25",
            "conditions" => {
              "type" => "AND",
              "conditions" => [
                { "attribute" => "plan", "operator" => "EQUALS", "value" => "pro" }
              ]
            }
          }
        ]
      end

      it "returns the first matching rule's value" do
        expect(described_class.evaluate(rules, { role: "admin" })).to eq("unlimited")
        expect(described_class.evaluate(rules, { email: "alice@company.com" })).to eq("100")
        expect(described_class.evaluate(rules, { plan: "pro" })).to eq("25")
      end

      it "returns nil when no rules match" do
        expect(described_class.evaluate(rules, { role: "user", email: "alice@gmail.com", plan: "free" })).to be_nil
      end

      it "stops at first match even if later rules would also match" do
        # This user is both admin AND has company email, but admin rule comes first
        expect(described_class.evaluate(rules, { role: "admin", email: "alice@company.com" })).to eq("unlimited")
      end
    end
  end
end
