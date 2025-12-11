# frozen_string_literal: true

Subflag::Rails::Engine.routes.draw do
  resources :flags do
    member do
      post :toggle
      post :test
    end
  end

  root to: "flags#index"
end
