# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Health check and development tools (outside locale scope)
  get 'up' => 'rails/health#show', as: :rails_health_check
  
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end

  # Locale-based routes
  scope '(:locale)', locale: /#{I18n.available_locales.join('|')}/ do
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

    # Profile routes
    resource :profile, only: %i[edit update]

    # Coming soon page
    get 'coming-soon' => 'pages#coming_soon', as: :coming_soon

    # Defines the root path route ("/")
    root 'pages#coming_soon'
  end

  # Redirect root without locale to default locale
  get '/', to: redirect("/#{I18n.default_locale}")
end
