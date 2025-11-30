# frozen_string_literal: true

module Subflag
  module Rails
    # Helpers for using Subflag in controllers and views
    #
    # All helpers automatically use `current_user` for targeting if available.
    # Override with `user: nil` or `user: other_user` when needed.
    #
    # @example Controller
    #   class ProjectsController < ApplicationController
    #     def index
    #       if subflag_enabled?(:new_dashboard)
    #         # show new dashboard
    #       end
    #       @max_projects = subflag_value(:max_projects, default: 3)
    #     end
    #   end
    #
    # @example View
    #   <% if subflag_enabled?(:new_checkout) %>
    #     <%= render "new_checkout" %>
    #   <% end %>
    #   <h1><%= subflag_value(:headline, default: "Welcome") %></h1>
    #
    # @example Flag accessor for multiple checks
    #   flags = subflag_for
    #   if flags.beta_feature?
    #     max = flags.max_projects(default: 3)
    #   end
    #
    module Helpers
      # Check if a boolean flag is enabled
      #
      # Automatically scoped to current_user if available.
      #
      # @param flag_name [Symbol, String] The flag name (underscores → dashes)
      # @param user [Object, nil, :auto] User for targeting (default: current_user)
      # @param context [Hash, nil] Additional context attributes
      # @param default [Boolean] Default value (optional, defaults to false)
      # @return [Boolean]
      #
      # @example
      #   <% if subflag_enabled?(:new_checkout) %>
      #   <% if subflag_enabled?(:admin_feature, user: nil) %>  <!-- no user context -->
      #
      def subflag_enabled?(flag_name, user: :auto, context: nil, default: false)
        resolved = resolve_user(user)
        Subflag.flags(user: resolved, context: context).public_send(:"#{flag_name}?", default: default)
      end

      # Get a flag value (default required)
      #
      # Automatically scoped to current_user if available.
      #
      # @param flag_name [Symbol, String] The flag name (underscores → dashes)
      # @param default [Object] Default value (required - determines type)
      # @param user [Object, nil, :auto] User for targeting (default: current_user)
      # @param context [Hash, nil] Additional context attributes
      # @return [Object] The flag value
      #
      # @example
      #   <%= subflag_value(:headline, default: "Welcome") %>
      #   <%= subflag_value(:max_items, user: nil, default: 10) %>
      #
      def subflag_value(flag_name, default:, user: :auto, context: nil)
        resolved = resolve_user(user)
        Subflag.flags(user: resolved, context: context).public_send(flag_name, default: default)
      end

      # Get a flag accessor, optionally for a specific user
      #
      # Automatically scoped to current_user if no user provided.
      #
      # @param user [Object, nil, :auto] User for targeting (default: current_user)
      # @param context [Hash, nil] Additional context attributes
      # @return [FlagAccessor] A flag accessor
      #
      # @example Using current_user automatically
      #   <% flags = subflag_for %>
      #   <% if flags.beta_feature? %>
      #     <h1><%= flags.welcome_message(default: "Hello!") %></h1>
      #   <% end %>
      #
      # @example Without user context
      #   <% flags = subflag_for(nil) %>
      #
      # @example With specific user
      #   <% flags = subflag_for(admin_user) %>
      #
      def subflag_for(user = :auto, context: nil)
        resolved = resolve_user(user)
        Subflag.flags(user: resolved, context: context)
      end

      private

      # Resolve user parameter - use current_user if :auto and available
      #
      # @param user [Object, nil, :auto]
      # @return [Object, nil]
      def resolve_user(user)
        return user unless user == :auto
        respond_to?(:current_user, true) ? current_user : nil
      end
    end
  end
end
