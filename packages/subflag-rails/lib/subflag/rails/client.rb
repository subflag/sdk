# frozen_string_literal: true

module Subflag
  module Rails
    # Lightweight struct for caching prefetched flag results
    # Used by ActiveRecord and Memory backends where we don't have Subflag::EvaluationResult
    PrefetchedFlag = Struct.new(:flag_key, :value, :reason, :variant, keyword_init: true)

    # Client for evaluating feature flags
    #
    # This is the low-level client used by FlagAccessor.
    # Most users should use `Subflag.flags` instead.
    #
    class Client
      # Prefetch all flags for a user/context
      #
      # Fetches all flags and caches them for subsequent lookups.
      # Behavior varies by backend:
      # - :subflag — Single API call to fetch all flags
      # - :active_record — Single DB query to load all enabled flags
      # - :memory — No-op (flags already in memory)
      #
      # @param user [Object, nil] The user object for targeting
      # @param context [Hash, nil] Additional context attributes
      # @return [Array<Hash>] Array of prefetched flag results (for inspection)
      #
      # @example
      #   Subflag::Rails.client.prefetch_all(user: current_user)
      #   # Subsequent lookups use cache - no API calls
      #   subflag_enabled?(:new_feature)
      #
      def prefetch_all(user: nil, context: nil)
        case configuration.backend
        when :subflag
          prefetch_from_subflag_api(user: user, context: context)
        when :active_record
          prefetch_from_active_record(user: user, context: context)
        when :memory
          # Already in memory, nothing to prefetch
          []
        else
          []
        end
      end

      # Check if a boolean flag is enabled
      #
      # @param flag_key [String] The flag key (already normalized)
      # @param user [Object, nil] The user object for targeting
      # @param context [Hash, nil] Additional context attributes
      # @param default [Boolean] Default value if flag not found (defaults to false)
      # @return [Boolean]
      def enabled?(flag_key, user: nil, context: nil, default: false)
        ctx = ContextBuilder.build(user: user, context: context)

        # Check prefetch cache first
        prefetched = get_prefetched_value(flag_key, ctx, :boolean)
        if !prefetched.nil?
          log_evaluation(flag_key, prefetched, default)
          return prefetched
        end

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

        # Check prefetch cache first
        expected_type = type_from_default(default)
        prefetched = get_prefetched_value(flag_key, ctx, expected_type)
        if !prefetched.nil?
          log_evaluation(flag_key, prefetched, default)
          return prefetched
        end

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

        # Check prefetch cache first - returns full EvaluationResult
        prefetched_result = get_prefetched_result(flag_key, ctx)
        if prefetched_result
          log_evaluation(flag_key, prefetched_result.value, default)
          return EvaluationResult.from_subflag(prefetched_result)
        end

        cache_key = build_cache_key(flag_key, ctx, "details:#{default.class}")

        details = RequestCache.fetch(cache_key) do
          fetch_details_by_type(flag_key, default, ctx)
        end

        log_evaluation(flag_key, details[:value], default)
        EvaluationResult.from_openfeature(details, flag_key: flag_key)
      end

      private

      # Prefetch flags from Subflag Cloud API
      def prefetch_from_subflag_api(user:, context:)
        ctx = ContextBuilder.build(user: user, context: context)
        context_hash = ctx ? ctx.hash : "no_context"

        # Use Rails.cache for cross-request caching if enabled
        if configuration.rails_cache_enabled?
          return prefetch_with_rails_cache(ctx, context_hash)
        end

        # Otherwise fetch directly from API (per-request cache only)
        prefetch_from_api(ctx, context_hash)
      end

      # Fetch flags from API and populate RequestCache
      def prefetch_from_api(ctx, context_hash)
        subflag_context = build_subflag_context(ctx)
        results = subflag_client.evaluate_all(context: subflag_context)

        # Cache each result in RequestCache for this request
        results.each do |result|
          cache_prefetched_result(result, context_hash)
        end

        results.map(&:to_h)
      end

      # Fetch flags using Rails.cache with TTL, falling back to API on cache miss
      def prefetch_with_rails_cache(ctx, context_hash)
        rails_cache_key = "subflag:all_flags:#{context_hash}"

        cached_data = ::Rails.cache.fetch(rails_cache_key, expires_in: configuration.cache_ttl) do
          # Cache miss - fetch from API
          subflag_context = build_subflag_context(ctx)
          results = subflag_client.evaluate_all(context: subflag_context)
          results.map(&:to_h)
        end

        # Populate RequestCache from cached data (whether from Rails.cache or fresh fetch)
        populate_request_cache_from_data(cached_data, context_hash)

        cached_data
      end

      # Populate RequestCache from cached hash data (Subflag API)
      def populate_request_cache_from_data(data_array, context_hash)
        return unless RequestCache.enabled?

        data_array.each do |result_hash|
          result = ::Subflag::EvaluationResult.from_response(result_hash)
          cache_prefetched_result(result, context_hash)
        end
      end

      # Prefetch flags from ActiveRecord database
      # Loads all enabled flags in one query and caches their values
      def prefetch_from_active_record(user:, context:)
        return [] unless RequestCache.enabled?

        ctx = ContextBuilder.build(user: user, context: context)
        context_hash = ctx ? ctx.hash : "no_context"

        prefetched = []

        Subflag::Rails::Flag.enabled.find_each do |flag|
          prefetch_key = "subflag:prefetch:#{flag.key}:#{context_hash}"
          RequestCache.current_cache[prefetch_key] = PrefetchedFlag.new(
            flag_key: flag.key,
            value: flag.typed_value,
            reason: "STATIC",
            variant: "default"
          )
          prefetched << { flag_key: flag.key, value: flag.typed_value }
        end

        prefetched
      end

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

      # Build Subflag::EvaluationContext from OpenFeature context
      def build_subflag_context(openfeature_ctx)
        return nil unless openfeature_ctx

        ::Subflag::EvaluationContext.from_openfeature(openfeature_ctx)
      end

      # Get or create the Subflag HTTP client for direct API calls
      def subflag_client
        @subflag_client ||= ::Subflag::Client.new(
          api_url: configuration.api_url,
          api_key: configuration.api_key
        )
      end

      # Cache a prefetched result for subsequent lookups
      def cache_prefetched_result(result, context_hash)
        # Store with a prefetch-specific key that includes the raw result
        prefetch_key = "subflag:prefetch:#{result.flag_key}:#{context_hash}"
        RequestCache.current_cache[prefetch_key] = result
      end

      # Check if a flag was prefetched and return its value
      def get_prefetched_value(flag_key, ctx, expected_type)
        return nil unless RequestCache.enabled?

        context_hash = ctx ? ctx.hash : "no_context"
        prefetch_key = "subflag:prefetch:#{flag_key}:#{context_hash}"
        result = RequestCache.current_cache[prefetch_key]

        return nil unless result

        # Convert value to expected type if needed
        convert_prefetched_value(result.value, expected_type)
      end

      # Get the full prefetched result for a flag (for evaluate method)
      def get_prefetched_result(flag_key, ctx)
        return nil unless RequestCache.enabled?

        context_hash = ctx ? ctx.hash : "no_context"
        prefetch_key = "subflag:prefetch:#{flag_key}:#{context_hash}"
        RequestCache.current_cache[prefetch_key]
      end

      # Convert prefetched value to expected type
      def convert_prefetched_value(value, expected_type)
        case expected_type
        when :boolean
          value == true || value == false ? value : nil
        when :string
          value.is_a?(String) ? value : nil
        when :integer
          value.is_a?(Numeric) ? value.to_i : nil
        when :float
          value.is_a?(Numeric) ? value.to_f : nil
        when :object
          value.is_a?(Hash) ? value : nil
        else
          value
        end
      end

      # Get expected type from default value
      def type_from_default(default)
        case default
        when TrueClass, FalseClass then :boolean
        when String then :string
        when Integer then :integer
        when Float then :float
        when Hash then :object
        else :unknown
        end
      end
    end
  end
end
