# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Health check and development tools (outside locale scope)
  get 'up' => 'rails/health#show', as: :rails_health_check

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  # Locale-based routes
  scope '(:locale)', locale: /#{I18n.available_locales.join('|')}/ do
    # Authentication routes
    resource :session, only: %i[new create destroy]
    post 'session/request_sms', to: 'sessions#request_sms', as: :request_sms_login
    resource :registration, only: %i[new create]

    # Phone authentication routes
    resource :phone_session, only: %i[new create], path: 'phone_login'
    post 'phone_login/request_sms', to: 'phone_sessions#request_sms', as: :request_sms_phone_login

    # Wicked wizard routes for multi-step registration
    resources :registration_steps, only: %i[show update], controller: 'registrations', path: 'registration'

    # Email verification routes
    get 'email_verification/:token', to: 'email_verifications#show', as: :email_verification
    resource :email_verification, only: [:create], path: 'email_verification'
    resource :email_verification_request, only: %i[new create], path: 'resend_verification'

    # SMS verification routes
    post 'sms_verification', to: 'sms_verifications#verify', as: :sms_verification
    post 'sms_verification/resend', to: 'sms_verifications#resend', as: :resend_sms_verification

    # Account unlock routes
    resource :account_unlock, only: %i[new create], path: 'unlock-account'
    get 'unlock-account/:token', to: 'account_unlocks#unlock', as: :unlock_account_token

    # Dashboard routes
    get 'dashboard' => 'dashboard#index', as: :dashboard

    # Profile routes
    resource :profile, only: %i[edit update] do
      patch :change_password
      delete :remove_photo
    end

    # WebAuthn/2FA routes
    resources :webauthn_credentials, only: [:index, :new, :create, :destroy] do
      collection do
        get :auth_options
        post :verify
      end
    end

    # Two-factor authentication verification
    get 'two_factor_verification', to: 'two_factor_verifications#show'
    post 'two_factor_verification/verify', to: 'two_factor_verifications#verify', as: :two_factor_verification_verify

    # Admin routes
    namespace :admin do
      resources :roles do
        resources :role_permissions, only: [:create, :destroy], path: 'permissions'
        resource :permissions, only: [:update], controller: 'role_permissions'
      end
      resources :users, only: [:index] do
        member do
          patch :lock
          patch :unlock
        end
        resource :role, only: [:edit, :update], controller: 'user_roles'
      end
    end

    # Coming soon page
    get 'coming-soon' => 'pages#coming_soon', as: :coming_soon

    # Defines the root path route ("/")
    root 'pages#coming_soon'
  end

  # Redirect root without locale to default locale
  get '/', to: redirect("/#{I18n.default_locale}")

  # API routes (outside locale scope)
  namespace :api do
    namespace :v1 do
      post 'login', to: 'authentication#login'
      delete 'logout', to: 'authentication#logout'
      post 'refresh', to: 'authentication#refresh'
    end
  end
end
