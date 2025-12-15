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

  describe ".evaluate_percentage" do
    let(:flag_key) { "test-feature" }

    context "edge cases" do
      it "returns false for 0%" do
        expect(described_class.evaluate_percentage("user-1", flag_key, 0)).to be false
      end

      it "returns true for 100%" do
        expect(described_class.evaluate_percentage("user-1", flag_key, 100)).to be true
      end
    end

    context "consistency" do
      it "returns the same result for the same user and flag" do
        results = 10.times.map do
          described_class.evaluate_percentage("user-123", flag_key, 50)
        end

        expect(results.uniq.size).to eq(1)
      end

      it "returns different results for different users (given enough samples)" do
        results = 100.times.map do |i|
          described_class.evaluate_percentage("user-#{i}", flag_key, 50)
        end

        expect(results).to include(true)
        expect(results).to include(false)
      end
    end

    context "distribution" do
      it "produces approximately correct distribution for 50%" do
        sample_size = 1000
        true_count = sample_size.times.count do |i|
          described_class.evaluate_percentage("user-#{i}", flag_key, 50)
        end

        expect(true_count).to be_within(100).of(500)
      end

      it "produces approximately correct distribution for 25%" do
        sample_size = 1000
        true_count = sample_size.times.count do |i|
          described_class.evaluate_percentage("user-#{i}", flag_key, 25)
        end

        expect(true_count).to be_within(100).of(250)
      end
    end

    context "flag independence" do
      it "produces different bucketing for different flags" do
        user_key = "user-stable"
        results = 50.times.map do |i|
          [
            described_class.evaluate_percentage(user_key, "flag-#{i}", 50),
            described_class.evaluate_percentage(user_key, "flag-#{i + 100}", 50)
          ]
        end

        differing = results.count { |r| r[0] != r[1] }
        expect(differing).to be > 5
      end
    end
  end

  describe ".evaluate with percentage rules" do
    let(:flag_key) { "beta-feature" }

    context "percentage-only rules" do
      let(:rules) do
        [{ "value" => "beta", "percentage" => 50 }]
      end

      it "returns value for users in the percentage" do
        in_bucket_user = (1..100).find do |i|
          described_class.evaluate_percentage("user-#{i}", flag_key, 50)
        end

        context = { targeting_key: "user-#{in_bucket_user}" }
        expect(described_class.evaluate(rules, context, flag_key: flag_key)).to eq("beta")
      end

      it "returns nil for users outside the percentage" do
        outside_bucket_user = (1..100).find do |i|
          !described_class.evaluate_percentage("user-#{i}", flag_key, 50)
        end

        context = { targeting_key: "user-#{outside_bucket_user}" }
        expect(described_class.evaluate(rules, context, flag_key: flag_key)).to be_nil
      end

      it "returns nil when context has no targeting_key" do
        context = { email: "test@example.com" }
        expect(described_class.evaluate(rules, context, flag_key: flag_key)).to be_nil
      end

      it "returns nil when flag_key is not provided" do
        context = { targeting_key: "user-1" }
        expect(described_class.evaluate(rules, context)).to be_nil
      end
    end

    context "segment + percentage rules" do
      let(:rules) do
        [{
          "value" => "beta",
          "conditions" => {
            "type" => "AND",
            "conditions" => [
              { "attribute" => "plan", "operator" => "EQUALS", "value" => "pro" }
            ]
          },
          "percentage" => 50
        }]
      end

      it "returns value only when segment AND percentage match" do
        in_bucket_user = (1..100).find do |i|
          described_class.evaluate_percentage("user-#{i}", flag_key, 50)
        end

        context = { targeting_key: "user-#{in_bucket_user}", plan: "pro" }
        expect(described_class.evaluate(rules, context, flag_key: flag_key)).to eq("beta")
      end

      it "returns nil when segment matches but percentage does not" do
        outside_bucket_user = (1..100).find do |i|
          !described_class.evaluate_percentage("user-#{i}", flag_key, 50)
        end

        context = { targeting_key: "user-#{outside_bucket_user}", plan: "pro" }
        expect(described_class.evaluate(rules, context, flag_key: flag_key)).to be_nil
      end

      it "returns nil when segment does not match (even if percentage would)" do
        in_bucket_user = (1..100).find do |i|
          described_class.evaluate_percentage("user-#{i}", flag_key, 50)
        end

        context = { targeting_key: "user-#{in_bucket_user}", plan: "free" }
        expect(described_class.evaluate(rules, context, flag_key: flag_key)).to be_nil
      end
    end

    context "multiple rules with percentages" do
      let(:rules) do
        [
          {
            "value" => "vip",
            "conditions" => {
              "type" => "AND",
              "conditions" => [{ "attribute" => "role", "operator" => "EQUALS", "value" => "admin" }]
            }
          },
          {
            "value" => "beta",
            "percentage" => 20
          }
        ]
      end

      it "admins always get VIP (no percentage check)" do
        context = { targeting_key: "admin-user", role: "admin" }
        expect(described_class.evaluate(rules, context, flag_key: flag_key)).to eq("vip")
      end

      it "non-admins get beta based on percentage" do
        in_bucket_user = (1..1000).find do |i|
          described_class.evaluate_percentage("user-#{i}", flag_key, 20)
        end

        context = { targeting_key: "user-#{in_bucket_user}", role: "user" }
        expect(described_class.evaluate(rules, context, flag_key: flag_key)).to eq("beta")
      end
    end
  end
end
