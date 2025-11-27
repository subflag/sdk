# frozen_string_literal: true

module Subflag
  # Represents the context for flag evaluation, including targeting information
  # and custom attributes for segment matching and percentage rollouts.
  #
  # @example Basic usage with targeting key
  #   context = EvaluationContext.new(targeting_key: "user-123")
  #
  # @example With custom attributes
  #   context = EvaluationContext.new(
  #     targeting_key: "user-123",
  #     kind: "user",
  #     attributes: { plan: "premium", country: "US" }
  #   )
  class EvaluationContext
    attr_reader :targeting_key, :kind, :attributes

    # @param targeting_key [String, nil] Unique identifier for targeting (user ID, session ID, etc.)
    # @param kind [String, nil] The kind of context ("user", "organization", "device", etc.)
    # @param attributes [Hash, nil] Custom attributes for targeting rules
    def initialize(targeting_key: nil, kind: nil, attributes: nil)
      @targeting_key = targeting_key
      @kind = kind
      @attributes = attributes || {}
    end

    # Convert to hash for API request
    # @return [Hash] The context as a hash
    def to_h
      {
        targetingKey: @targeting_key,
        kind: @kind,
        attributes: @attributes.empty? ? nil : @attributes
      }.compact
    end

    # Create from OpenFeature evaluation context
    # @param openfeature_context [OpenFeature::SDK::EvaluationContext, Hash, nil]
    # @return [EvaluationContext]
    def self.from_openfeature(openfeature_context)
      return new if openfeature_context.nil?

      # Handle Hash-like context (OpenFeature context is typically a hash-like object)
      if openfeature_context.respond_to?(:to_h)
        ctx = openfeature_context.to_h
      elsif openfeature_context.is_a?(Hash)
        ctx = openfeature_context
      else
        return new
      end

      # Extract targeting_key (OpenFeature standard)
      targeting_key = ctx[:targeting_key] || ctx["targeting_key"]

      # Extract other attributes (excluding targeting_key)
      attributes = ctx.reject { |k, _| [:targeting_key, "targeting_key"].include?(k) }

      new(
        targeting_key: targeting_key,
        kind: "user", # Default to "user" kind for OpenFeature contexts
        attributes: attributes.empty? ? nil : symbolize_keys(attributes)
      )
    end

    private

    def self.symbolize_keys(hash)
      hash.transform_keys(&:to_sym)
    end
  end
end
