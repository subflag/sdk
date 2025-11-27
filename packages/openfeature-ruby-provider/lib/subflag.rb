# frozen_string_literal: true

require_relative "subflag/version"
require_relative "subflag/errors"
require_relative "subflag/evaluation_context"
require_relative "subflag/evaluation_result"
require_relative "subflag/client"
require_relative "subflag/provider"

# Subflag Ruby SDK for OpenFeature
#
# This module provides integration with Subflag feature flag management
# through the OpenFeature standard.
#
# @example Quick start with OpenFeature
#   require "openfeature/sdk"
#   require "subflag"
#
#   # Configure the provider
#   provider = Subflag::Provider.new(
#     api_url: ENV["SUBFLAG_API_URL"],
#     api_key: ENV["SUBFLAG_API_KEY"]
#   )
#
#   OpenFeature::SDK.configure do |config|
#     config.set_provider(provider)
#   end
#
#   # Use the client
#   client = OpenFeature::SDK.build_client
#
#   if client.fetch_boolean_value(flag_key: "new-checkout", default_value: false)
#     # New checkout flow
#   else
#     # Legacy checkout flow
#   end
#
# @example Direct client usage (without OpenFeature)
#   client = Subflag::Client.new(
#     api_url: "https://api.subflag.com",
#     api_key: "sdk-production-abc123"
#   )
#
#   result = client.evaluate("my-flag")
#   puts result.value    # => true
#   puts result.variant  # => "enabled"
#   puts result.reason   # => "DEFAULT"
#
module Subflag
end
