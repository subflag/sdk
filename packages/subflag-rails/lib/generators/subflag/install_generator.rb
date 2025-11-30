# frozen_string_literal: true

require "rails/generators/base"

module Subflag
  module Generators
    # Generator for setting up Subflag in a Rails application
    #
    # Usage:
    #   rails generate subflag:install
    #
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Creates a Subflag initializer and provides setup instructions"

      def create_initializer
        template "initializer.rb", "config/initializers/subflag.rb"
      end

      def show_instructions
        say ""
        say "Subflag installed!", :green
        say ""
        say "Next steps:"
        say ""
        say "1. Add your API key to Rails credentials:"
        say "   $ rails credentials:edit"
        say ""
        say "   subflag:"
        say "     api_key: sdk-production-your-key-here"
        say ""
        say "   Or set SUBFLAG_API_KEY environment variable."
        say ""
        say "2. Configure user context in config/initializers/subflag.rb"
        say ""
        say "3. Use flags in your code:"
        say ""
        say "   # Controller (auto-scoped to current_user)"
        say "   if subflag_enabled?(:new_checkout)"
        say "     # ..."
        say "   end"
        say ""
        say "   max = subflag_value(:max_projects, default: 3)"
        say ""
        say "   # View"
        say "   <% if subflag_enabled?(:new_checkout) %>"
        say "     <%= render 'new_checkout' %>"
        say "   <% end %>"
        say ""
        say "Docs: https://docs.subflag.com/rails"
        say ""
      end
    end
  end
end
