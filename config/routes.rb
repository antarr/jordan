# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Authentication routes
  resource :session, only: %i[new create destroy]
  resource :registration, only: %i[new create]
  
  # Wicked wizard routes for multi-step registration
  resources :registration_steps, only: %i[show update], controller: 'registrations', path: 'registration'
  
  # Email verification routes
  get 'email_verification/:token', to: 'email_verifications#show', as: :email_verification
  resource :email_verification, only: [:create], path: 'email_verification'
  resource :email_verification_request, only: [:new, :create], path: 'resend_verification'

  # Dashboard routes
  get 'dashboard' => 'dashboard#index', as: :dashboard

  # Development tools
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
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
