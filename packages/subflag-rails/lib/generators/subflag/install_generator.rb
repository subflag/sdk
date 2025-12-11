# frozen_string_literal: true

require "rails/generators/base"

module Subflag
  module Generators
    # Generator for setting up Subflag in a Rails application
    #
    # Usage:
    #   rails generate subflag:install                     # Default: Subflag Cloud
    #   rails generate subflag:install --backend=subflag   # Explicit: Subflag Cloud
    #   rails generate subflag:install --backend=active_record  # Self-hosted DB
    #   rails generate subflag:install --backend=memory    # Testing only
    #
    class InstallGenerator < ::Rails::Generators::Base
      include ::Rails::Generators::Migration if defined?(::Rails::Generators::Migration)

      source_root File.expand_path("templates", __dir__)

      desc "Creates a Subflag initializer and optionally a migration for ActiveRecord backend"

      class_option :backend, type: :string, default: "subflag",
                   desc: "Backend to use: subflag (cloud), active_record (self-hosted), or memory (testing)"

      def self.next_migration_number(dirname)
        if defined?(::ActiveRecord::Generators::Base)
          ::ActiveRecord::Generators::Base.next_migration_number(dirname)
        else
          Time.now.utc.strftime("%Y%m%d%H%M%S")
        end
      end

      # Helper for templates to detect PostgreSQL adapter
      def postgresql?
        return false unless defined?(::ActiveRecord::Base)

        adapter = ::ActiveRecord::Base.connection_db_config.adapter.to_s rescue nil
        adapter&.include?("postgresql") || adapter&.include?("postgis")
      end

      def create_initializer
        template "initializer.rb.tt", "config/initializers/subflag.rb"
      end

      def create_flags_migration
        return unless options[:backend] == "active_record"

        migration_template "create_subflag_flags.rb.tt",
                          "db/migrate/create_subflag_flags.rb"
      end

      def show_instructions
        say ""

        case options[:backend]
        when "active_record"
          say "Subflag installed with ActiveRecord backend!", :green
          say ""
          say "Next steps:"
          say ""
          say "1. Run the migration:"
          say "   $ rails db:migrate"
          say ""
          say "2. Create your first flag:"
          say ""
          say "   Subflag::Rails::Flag.create!("
          say "     key: 'new-checkout',"
          say "     value: 'true',"
          say "     value_type: 'boolean'"
          say "   )"
          say ""
          say "3. Use flags in your code:"
          say ""
          say "   if subflag_enabled?(:new_checkout)"
          say "     # ..."
          say "   end"
          say ""
          say "When you're ready for a dashboard, environments, and user targeting:"
          say "  https://subflag.com", :yellow
          say ""

        when "memory"
          say "Subflag installed with Memory backend!", :green
          say ""
          say "Note: Memory backend is for testing only. Flags reset on restart."
          say ""
          say "Set flags in your tests or initializer:"
          say ""
          say "  Subflag::Rails.provider.set(:new_checkout, true)"
          say "  Subflag::Rails.provider.set(:max_projects, 100)"
          say ""
          say "Use flags:"
          say ""
          say "  subflag_enabled?(:new_checkout)        # => true"
          say "  subflag_value(:max_projects, default: 3)  # => 100"
          say ""

        else # subflag (cloud)
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
          say "Docs: https://docs.subflag.com/rails"
          say ""
        end
      end
    end
  end
end
