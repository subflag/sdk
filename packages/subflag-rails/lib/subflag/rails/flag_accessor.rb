# frozen_string_literal: true

module Subflag
  module Rails
    # Dynamic flag accessor using method_missing
    #
    # Provides a clean DSL for accessing flags:
    #
    # @example Boolean flags (? suffix) - default is optional (false)
    #   Subflag.flags.new_checkout?
    #   Subflag.flags.new_checkout?(default: true)
    #
    # @example Value flags - default is REQUIRED
    #   Subflag.flags.homepage_headline(default: "Welcome")
    #   Subflag.flags.max_projects(default: 3)
    #   Subflag.flags.tax_rate(default: 0.08)
    #   Subflag.flags.feature_limits(default: {})
    #
    # @example With user context
    #   Subflag.flags(user: current_user).max_projects(default: 3)
    #
    # @example Bracket access (exact flag names, default required)
    #   Subflag.flags["my-exact-flag", default: "value"]
    #
    # @example Full evaluation details
    #   result = Subflag.flags.evaluate(:max_projects, default: 3)
    #   result.value    # => 100
    #   result.reason   # => :targeting_match
    #
    # Flag names are automatically converted:
    # - Underscores become dashes: `new_checkout` → `new-checkout`
    # - Trailing ? is removed for booleans: `enabled?` → `enabled`
    #
    class FlagAccessor
      def initialize(user: nil, context: nil)
        @user = user
        @context = context
      end

      # Bracket access for exact flag names (no conversion)
      #
      # @param flag_name [String, Symbol] The exact flag name
      # @param default [Object] Default value (required)
      # @return [Object] The flag value
      # @raise [ArgumentError] If default is not provided
      #
      # @example
      #   Subflag.flags["my-exact-flag", default: "value"]
      #
      def [](flag_name, default:)
        flag_key = flag_name.to_s
        client.value(flag_key, user: @user, context: @context, default: default)
      end

      # Get full evaluation details for a flag
      #
      # @param flag_name [String, Symbol] The flag name
      # @param default [Object] Default value (required)
      # @return [EvaluationResult] Full evaluation result
      # @raise [ArgumentError] If default is not provided
      #
      # @example
      #   result = Subflag.flags.evaluate(:max_projects, default: 3)
      #   result.value    # => 100
      #   result.variant  # => "premium"
      #   result.reason   # => :targeting_match
      #
      def evaluate(flag_name, default:)
        flag_key = normalize_flag_name(flag_name)
        client.evaluate(flag_key, user: @user, context: @context, default: default)
      end

      # Handle dynamic flag access
      #
      # Method names ending in ? are treated as boolean flags (default: false).
      # All other methods require a default: keyword argument.
      #
      # @example Boolean (default optional)
      #   flags.new_checkout?              # default: false
      #   flags.new_checkout?(default: true)
      #
      # @example Value (default required)
      #   flags.max_projects(default: 3)
      #   flags.headline(default: "Hi")
      #
      def method_missing(method_name, *args, **kwargs, &block)
        flag_key = normalize_flag_name(method_name)

        if method_name.to_s.end_with?("?")
          # Boolean flag - default is optional (false)
          default = kwargs.fetch(:default, false)
          client.enabled?(flag_key, user: @user, context: @context, default: default)
        else
          # Value flag - default is required
          unless kwargs.key?(:default)
            raise ArgumentError, "default is required: Subflag.flags.#{method_name}(default: <value>)"
          end
          client.value(flag_key, user: @user, context: @context, default: kwargs[:default])
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        true
      end

      private

      def client
        Subflag::Rails.client
      end

      # Convert Ruby method name to flag key
      #
      # - Removes trailing ? for boolean methods
      # - Converts underscores to dashes
      #
      # @param method_name [Symbol, String] The method/flag name
      # @return [String] The normalized flag key
      #
      # @example
      #   normalize_flag_name(:new_checkout?)  # => "new-checkout"
      #   normalize_flag_name(:max_projects)   # => "max-projects"
      #
      def normalize_flag_name(method_name)
        method_name.to_s.chomp("?").tr("_", "-")
      end
    end
  end
end
