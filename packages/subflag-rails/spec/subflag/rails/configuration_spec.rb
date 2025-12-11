# frozen_string_literal: true

require "spec_helper"

RSpec.describe Subflag::Rails::Configuration do
  let(:config) { described_class.new }

  describe "#backend=" do
    it "raises ArgumentError for invalid backend" do
      expect { config.backend = :redis }.to raise_error(
        ArgumentError,
        /Invalid backend: redis/
      )
    end

    it "converts string to symbol" do
      config.backend = "active_record"
      expect(config.backend).to eq(:active_record)
    end
  end
end
