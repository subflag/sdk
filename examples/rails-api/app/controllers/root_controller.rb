# frozen_string_literal: true

class RootController < ApplicationController
  # GET /
  def index
    render json: {
      name: "Subflag Rails API Example",
      version: "1.0.0",
      description: "Feature flags with Ruby on Rails using subflag-rails",
      endpoints: {
        root: { path: "/", method: "GET" },
        products: { path: "/api/products", method: "GET" },
        product: { path: "/api/products/:id", method: "GET" },
        health: { path: "/api/health", method: "GET" }
      },
      feature_flags: {
        boolean: %w[enable-checkout premium-features api-enabled maintenance-mode],
        string: %w[button-text],
        integer: %w[rate-limit],
        double: %w[discount-rate],
        object: %w[payment-config]
      }
    }
  end
end
