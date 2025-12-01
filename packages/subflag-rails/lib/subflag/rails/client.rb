# frozen_string_literal: true

module Subflag
  module Rails
    # Client for evaluating feature flags
    #
    # This is the low-level client used by FlagAccessor.
    # Most users should use `Subflag.flags` instead.
    #
    class Client
      # Check if a boolean flag is enabled
      #
      # @param flag_key [String] The flag key (already normalized)
      # @param user [Object, nil] The user object for targeting
      # @param context [Hash, nil] Additional context attributes
      # @param default [Boolean] Default value if flag not found (defaults to false)
      # @return [Boolean]
      def enabled?(flag_key, user: nil, context: nil, default: false)
        ctx = ContextBuilder.build(user: user, context: context)
        cache_key = build_cache_key(flag_key, ctx, :boolean)

        result = RequestCache.fetch(cache_key) do
          openfeature_client.fetch_boolean_value(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        end

        log_evaluation(flag_key, result, default)
        result
      end

      # Get a flag value - default is required to determine type
      #
      # @param flag_key [String] The flag key (already normalized)
      # @param user [Object, nil] The user object for targeting
      # @param context [Hash, nil] Additional context attributes
      # @param default [Object] Default value (required - determines expected type)
      # @return [Object] The flag value
      # @raise [ArgumentError] If default is nil
      def value(flag_key, user: nil, context: nil, default:)
        ctx = ContextBuilder.build(user: user, context: context)
        cache_key = build_cache_key(flag_key, ctx, default.class)

        result = RequestCache.fetch(cache_key) do
          fetch_value_by_type(flag_key, default, ctx)
        end

        log_evaluation(flag_key, result, default)
        result
      end

      # Evaluate a flag and get full details - default is required
      #
      # @param flag_key [String] The flag key (already normalized)
      # @param user [Object, nil] The user object for targeting
      # @param context [Hash, nil] Additional context attributes
      # @param default [Object] Default value (required - determines expected type)
      # @return [EvaluationResult] Full evaluation result
      # @raise [ArgumentError] If default is nil
      def evaluate(flag_key, user: nil, context: nil, default:)
        ctx = ContextBuilder.build(user: user, context: context)
        cache_key = build_cache_key(flag_key, ctx, "details:#{default.class}")

        details = RequestCache.fetch(cache_key) do
          fetch_details_by_type(flag_key, default, ctx)
        end

        log_evaluation(flag_key, details[:value], default)
        EvaluationResult.from_openfeature(details, flag_key: flag_key)
      end

      private

      def build_cache_key(flag_key, ctx, type)
        context_hash = ctx ? ctx.hash : "no_context"
        "subflag:#{flag_key}:#{context_hash}:#{type}"
      end

      def openfeature_client
        @openfeature_client ||= OpenFeature::SDK.build_client
      end

      def fetch_value_by_type(flag_key, default, ctx)
        case default
        when String
          openfeature_client.fetch_string_value(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        when Integer
          openfeature_client.fetch_integer_value(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        when Float
          openfeature_client.fetch_float_value(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        when TrueClass, FalseClass
          openfeature_client.fetch_boolean_value(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        when Hash
          openfeature_client.fetch_object_value(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        when NilClass
          raise ArgumentError, "default is required for value flags (it determines the expected type)"
        else
          raise ArgumentError, "Unsupported default type: #{default.class}. Use String, Integer, Float, Boolean, or Hash."
        end
      end

      def fetch_details_by_type(flag_key, default, ctx)
        case default
        when String
          openfeature_client.fetch_string_details(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        when Integer
          openfeature_client.fetch_integer_details(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        when Float
          openfeature_client.fetch_float_details(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        when TrueClass, FalseClass
          openfeature_client.fetch_boolean_details(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        when Hash
          openfeature_client.fetch_object_details(flag_key: flag_key, default_value: default, evaluation_context: ctx)
        when NilClass
          raise ArgumentError, "default is required for evaluate (it determines the expected type)"
        else
          raise ArgumentError, "Unsupported default type: #{default.class}. Use String, Integer, Float, Boolean, or Hash."
        end
      end

      def configuration
        Subflag::Rails.configuration
      end

      def log_evaluation(flag_key, result, default)
        return unless configuration.logging_enabled

        logger = defined?(::Rails.logger) ? ::Rails.logger : nil
        return unless logger

        message = "[Subflag] #{flag_key} = #{result.inspect}"
        message += " (default)" if result == default

        case configuration.log_level
        when :info
          logger.info(message)
        when :warn
          logger.warn(message)
        else
          logger.debug(message)
        end
      end
    end
  end
end
