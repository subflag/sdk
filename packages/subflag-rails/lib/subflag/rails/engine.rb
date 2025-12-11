# frozen_string_literal: true

module Subflag
  module Rails
    # Mountable engine for the Subflag admin UI.
    #
    # Mount in your routes to get a web UI for managing flags:
    #
    #   # config/routes.rb
    #   mount Subflag::Rails::Engine => "/subflag"
    #
    # The engine provides:
    # - Flag CRUD (list, create, edit, delete)
    # - Targeting rule builder
    # - Rule testing interface
    #
    # Security: Configure authentication in an initializer:
    #
    #   Subflag::Rails.configure do |config|
    #     config.admin_auth do |controller|
    #       controller.authenticate_admin!  # Your auth method
    #     end
    #   end
    #
    class Engine < ::Rails::Engine
      isolate_namespace Subflag::Rails

      # Load engine routes
      initializer "subflag.routes" do |app|
        # Routes are loaded automatically from config/routes.rb
      end
    end
  end
end
