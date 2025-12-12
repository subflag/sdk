Rails.application.routes.draw do
  # Subflag Admin UI - manage flags and targeting rules
  mount Subflag::Rails::Engine => "/subflag"

  # Root endpoint
  root "root#index"

  # API endpoints
  namespace :api do
    resources :products, only: %i[index show]
    get "health", to: "health#show"
  end

  # Rails health check
  get "up" => "rails/health#show", as: :rails_health_check
end
