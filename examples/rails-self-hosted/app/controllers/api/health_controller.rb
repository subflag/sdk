# frozen_string_literal: true

module Api
  class HealthController < ApplicationController
    # GET /api/health
    def show
      # Boolean flag: API kill switch
      api_enabled = subflag_enabled?(:api_enabled, default: true)

      # Boolean flag: Maintenance mode
      maintenance_mode = subflag_enabled?(:maintenance_mode)

      if !api_enabled || maintenance_mode
        render json: {
          status: "unavailable",
          message: maintenance_mode ? "System under maintenance" : "Service temporarily unavailable",
          maintenance_mode: maintenance_mode,
          retry_after: 300
        }, status: :service_unavailable
        return
      end

      render json: {
        status: "healthy",
        timestamp: Time.current.iso8601,
        version: "1.0.0"
      }
    end
  end
end
