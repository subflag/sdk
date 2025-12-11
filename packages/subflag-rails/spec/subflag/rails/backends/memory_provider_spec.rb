# frozen_string_literal: true

require "spec_helper"
require "subflag/rails/backends/memory_provider"

RSpec.describe Subflag::Rails::Backends::MemoryProvider do
  let(:provider) { described_class.new }

  describe "#set" do
    it "converts underscores to dashes in keys" do
      provider.set(:my_cool_flag, true)

      result = provider.fetch_boolean_value(flag_key: "my-cool-flag", default_value: false)
      expect(result.value).to eq(true)
    end

    it "respects enabled: false" do
      provider.set(:disabled_flag, "value", enabled: false)

      result = provider.fetch_string_value(flag_key: "disabled-flag", default_value: "default")
      expect(result.value).to eq("default")
      expect(result.reason).to eq(:default)
    end
  end

  describe "#clear" do
    it "removes all flags" do
      provider.set(:flag_a, true)
      provider.set(:flag_b, "test")
      provider.clear

      result = provider.fetch_boolean_value(flag_key: "flag-a", default_value: false)
      expect(result.value).to eq(false)
    end
  end

  describe "fetch methods" do
    it "returns default when flag missing" do
      result = provider.fetch_string_value(flag_key: "nonexistent", default_value: "fallback")

      expect(result.value).to eq("fallback")
      expect(result.reason).to eq(:default)
    end

    it "returns stored value with :static reason when flag exists" do
      provider.set("test-flag", "stored")

      result = provider.fetch_string_value(flag_key: "test-flag", default_value: "default")

      expect(result.value).to eq("stored")
      expect(result.reason).to eq(:static)
    end

    it "handles all value types" do
      provider.set(:bool, true)
      provider.set(:str, "hello")
      provider.set(:int, 42)
      provider.set(:float, 3.14)
      provider.set(:obj, { key: "value" })

      expect(provider.fetch_boolean_value(flag_key: "bool", default_value: false).value).to eq(true)
      expect(provider.fetch_string_value(flag_key: "str", default_value: "").value).to eq("hello")
      expect(provider.fetch_integer_value(flag_key: "int", default_value: 0).value).to eq(42)
      expect(provider.fetch_float_value(flag_key: "float", default_value: 0.0).value).to eq(3.14)
      expect(provider.fetch_object_value(flag_key: "obj", default_value: {}).value).to eq({ key: "value" })
    end
  end
end
