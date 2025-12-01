# frozen_string_literal: true

module Subflag
  module Rails
    # Builds OpenFeature evaluation context from user objects and additional attributes
    class ContextBuilder
      # Build an OpenFeature EvaluationContext
      #
      # @param user [Object, nil] The user object for targeting
      # @param context [Hash, nil] Additional context attributes
      # @return [OpenFeature::SDK::EvaluationContext, nil] The combined context or nil if empty
      def self.build(user: nil, context: nil)
        new(user: user, context: context).build
      end

      def initialize(user: nil, context: nil)
        @user = user
        @context = context || {}
      end

      # Build the OpenFeature EvaluationContext
      #
      # @return [OpenFeature::SDK::EvaluationContext, nil]
      def build
        result = {}

        # Add user context if configured
        if @user
          user_context = configuration.build_user_context(@user)
          result.merge!(user_context) if user_context
        end

        # Merge in additional context (overrides user context)
        result.merge!(@context) if @context.is_a?(Hash)

        # Return nil if empty (no context to send)
        return nil if result.empty?

        # Convert to OpenFeature EvaluationContext
        normalized = normalize_context(result)
        OpenFeature::SDK::EvaluationContext.new(**normalized)
      end

      private

      def configuration
        Subflag::Rails.configuration
      end

      # Normalize context to OpenFeature format
      #
      # @param ctx [Hash] The raw context
      # @return [Hash] Normalized context with targeting_key at top level
      def normalize_context(ctx)
        # Ensure targeting_key is a string
        if ctx[:targeting_key]
          ctx[:targeting_key] = ctx[:targeting_key].to_s
        elsif ctx["targeting_key"]
          ctx[:targeting_key] = ctx.delete("targeting_key").to_s
        end

        ctx.transform_keys(&:to_sym)
      end
    end
  end
end
