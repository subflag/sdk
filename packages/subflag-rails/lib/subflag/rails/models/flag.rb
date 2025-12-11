# frozen_string_literal: true

module Subflag
  module Rails
    # ActiveRecord model for storing feature flags in your database
    #
    # @example Create a boolean flag
    #   Subflag::Rails::Flag.create!(
    #     key: "new-checkout",
    #     value: "true",
    #     value_type: "boolean"
    #   )
    #
    # @example Create an integer flag
    #   Subflag::Rails::Flag.create!(
    #     key: "max-projects",
    #     value: "100",
    #     value_type: "integer"
    #   )
    #
    # @example Create a JSON object flag
    #   Subflag::Rails::Flag.create!(
    #     key: "feature-limits",
    #     value: '{"max_items": 10, "max_users": 5}',
    #     value_type: "object"
    #   )
    #
    class Flag < ::ActiveRecord::Base
      self.table_name = "subflag_flags"

      VALUE_TYPES = %w[boolean string integer float object].freeze

      validates :key, presence: true,
                      uniqueness: true,
                      format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, and dashes" }
      validates :value_type, inclusion: { in: VALUE_TYPES }
      validates :value, presence: true

      scope :enabled, -> { where(enabled: true) }

      # Get the flag value cast to its declared type
      #
      # @param expected_type [Symbol, String, nil] Override the value_type for casting
      # @return [Object] The typed value
      def typed_value(expected_type = nil)
        type = expected_type&.to_s || value_type

        case type.to_s
        when "boolean"
          ActiveModel::Type::Boolean.new.cast(value)
        when "string"
          value.to_s
        when "integer"
          value.to_i
        when "float", "number"
          value.to_f
        when "object"
          value.is_a?(Hash) ? value : JSON.parse(value)
        else
          value
        end
      end
    end
  end
end
