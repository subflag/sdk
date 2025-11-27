# frozen_string_literal: true

require "spec_helper"

RSpec.describe Subflag::FlagNotFoundError do
  it "includes flag key in message" do
    error = described_class.new("my-missing-flag")

    expect(error.message).to include("my-missing-flag")
    expect(error.flag_key).to eq("my-missing-flag")
  end
end

RSpec.describe Subflag::TypeMismatchError do
  it "includes type information" do
    error = described_class.new("flag", expected_type: :boolean, actual_type: :string)

    expect(error.message).to include("boolean")
    expect(error.message).to include("string")
  end
end
