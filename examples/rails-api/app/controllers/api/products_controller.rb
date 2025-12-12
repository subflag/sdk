# frozen_string_literal: true

module Api
  class ProductsController < ApplicationController
    PRODUCTS = [
      { id: 1, name: "Laptop Pro", price: 1299.99, category: "electronics" },
      { id: 2, name: "Wireless Headphones", price: 199.99, category: "electronics" },
      { id: 3, name: "Running Shoes", price: 129.99, category: "apparel" },
      { id: 4, name: "Coffee Maker", price: 79.99, category: "home" },
      { id: 5, name: "Ergonomic Chair", price: 449.99, category: "furniture" }
    ].freeze

    # GET /api/products
    def index
      # Boolean flag: Toggle checkout feature
      checkout_enabled = subflag_enabled?(:enable_checkout)

      # String flag: A/B test button text
      button_text = subflag_value(:button_text, default: "View Details")

      # Integer flag: Dynamic rate limiting
      rate_limit = subflag_value(:rate_limit, default: 100)

      # Float flag: Dynamic discount rate
      discount_rate = subflag_value(:discount_rate, default: 0.0)

      # Object flag: Payment provider configuration
      payment_config = subflag_value(:payment_config, default: { "provider" => "stripe" })

      # Apply discount to products
      products = PRODUCTS.map do |product|
        discounted_price = (product[:price] * (1 - discount_rate)).round(2)
        product.merge(
          original_price: product[:price],
          discounted_price: discounted_price,
          discount_percent: (discount_rate * 100).round(0)
        )
      end

      render json: {
        success: true,
        metadata: {
          checkoutEnabled: checkout_enabled,
          buttonText: button_text,
          rateLimit: rate_limit,
          discountRate: discount_rate,
          paymentConfig: payment_config
        },
        products: products
      }
    end

    # GET /api/products/:id
    def show
      product = PRODUCTS.find { |p| p[:id] == params[:id].to_i }

      if product.nil?
        render json: { error: "Product not found" }, status: :not_found
        return
      end

      discount_rate = subflag_value(:discount_rate, default: 0.0)
      premium_features = subflag_enabled?(:premium_features)

      discounted_price = (product[:price] * (1 - discount_rate)).round(2)

      render json: {
        success: true,
        product: product.merge(
          original_price: product[:price],
          discounted_price: discounted_price,
          discount_percent: (discount_rate * 100).round(0),
          premium_features: premium_features
        )
      }
    end
  end
end
