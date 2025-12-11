# frozen_string_literal: true

require_relative "targeting_engine"

module Subflag
  module Rails
    # Targeting module for evaluating rules that control who sees what flag values.
    #
    # Rules are stored as JSON in the database and evaluated at runtime.
    # Use targeting to roll out features to internal teams before wider release.
    #
    # ## Rule Format
    #
    # Rules are an array of objects, each with a `value` and `conditions`:
    #
    #   [
    #     {
    #       "value" => "true",
    #       "conditions" => {
    #         "type" => "OR",
    #         "conditions" => [
    #           { "attribute" => "email", "operator" => "ENDS_WITH", "value" => "@company.com" },
    #           { "attribute" => "role", "operator" => "IN", "value" => ["admin", "qa"] }
    #         ]
    #       }
    #     }
    #   ]
    #
    # ## Supported Operators
    #
    # - EQUALS, NOT_EQUALS - exact match
    # - IN, NOT_IN - list membership
    # - CONTAINS, NOT_CONTAINS - substring match
    # - STARTS_WITH, ENDS_WITH - prefix/suffix match
    # - GREATER_THAN, LESS_THAN, GREATER_THAN_OR_EQUAL, LESS_THAN_OR_EQUAL - numeric
    # - MATCHES - regex match
    #
    # ## Evaluation
    #
    # Rules are evaluated in order. First match wins.
    # If no rules match, the flag's default value is returned.
    #
    # TODO: Add admin UI for managing targeting rules
    #
    module Targeting
    end
  end
end
