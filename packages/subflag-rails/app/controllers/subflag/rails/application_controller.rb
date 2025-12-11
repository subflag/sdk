# frozen_string_literal: true

module Subflag
  module Rails
    class ApplicationController < ActionController::Base
      include ActionController::Flash

      protect_from_forgery with: :exception

      before_action :authenticate_admin!

      private

      def authenticate_admin!
        auth_callback = Subflag::Rails.configuration.admin_auth_callback
        return unless auth_callback

        instance_exec(&auth_callback)
      end
    end
  end
end
