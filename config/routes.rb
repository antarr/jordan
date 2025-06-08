# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Authentication routes
  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]

  # Dashboard routes
  get 'dashboard' => 'dashboard#index', as: :dashboard

  # Cypress test helpers (test and development environment only)
  if Rails.env.test? || Rails.env.development?
    namespace :cypress_test_helpers do
      delete 'clear_users'
      post 'create_user'
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Coming soon page
  get 'coming-soon' => 'pages#coming_soon', as: :coming_soon

  # Defines the root path route ("/")
  root 'pages#coming_soon'
end
