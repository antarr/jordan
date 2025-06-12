class WebauthnCredentialsController < ApplicationController
  include Authorization

  before_action :require_authentication
  before_action :set_credential, only: %i[destroy]

  def index
    @credentials = current_user.webauthn_credentials.order(:created_at)
  end

  def new
    # Generate challenge for credential creation
    @webauthn_options = WebAuthn::Credential.options_for_create(
      user: {
        id: current_user.webauthn_user_id,
        name: current_user.email,
        display_name: current_user.username || current_user.email
      },
      exclude: current_user.webauthn_credentials.pluck(:webauthn_id)
    )

    session[:webauthn_creation_challenge] = @webauthn_options.challenge
    
    # The WebAuthn gem should handle the encoding properly
    render json: @webauthn_options
  end

  def create
    webauthn_credential = WebAuthn::Credential.from_create(params)

    begin
      webauthn_credential.verify(session[:webauthn_creation_challenge])

      # Save the credential
      credential = current_user.webauthn_credentials.build(
        webauthn_id: webauthn_credential.id,
        public_key: webauthn_credential.public_key,
        nickname: params[:nickname] || "Security Key #{current_user.webauthn_credentials.count + 1}",
        sign_count: webauthn_credential.sign_count
      )

      if credential.save
        current_user.enable_two_factor! unless current_user.two_factor_enabled?

        session.delete(:webauthn_creation_challenge)
        render json: {
          status: 'success',
          message: 'Security key registered successfully!',
          credential: {
            id: credential.id,
            nickname: credential.nickname,
            created_at: credential.created_at
          }
        }
      else
        render json: {
          status: 'error',
          message: 'Failed to save credential',
          errors: credential.errors.full_messages
        }, status: :unprocessable_entity
      end
    rescue WebAuthn::Error => e
      render json: {
        status: 'error',
        message: "WebAuthn verification failed: #{e.message}"
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @credential.destroy

    # Disable 2FA if no more credentials
    current_user.disable_two_factor! if current_user.webauthn_credentials.count == 0

    redirect_to profile_path, notice: 'Security key removed successfully.'
  end

  # Generate challenge for authentication
  def auth_options
    @webauthn_options = WebAuthn::Credential.options_for_get(
      allow: current_user.webauthn_credentials.pluck(:webauthn_id)
    )

    session[:webauthn_authentication_challenge] = @webauthn_options.challenge
    
    # The WebAuthn gem should handle the encoding properly
    render json: @webauthn_options
  end

  # Verify authentication
  def verify
    webauthn_credential = WebAuthn::Credential.from_get(params)
    stored_credential = current_user.webauthn_credentials.find_by(webauthn_id: webauthn_credential.id)

    unless stored_credential
      render json: {
        status: 'error',
        message: 'Credential not found'
      }, status: :unprocessable_entity
      return
    end

    begin
      webauthn_credential.verify(
        session[:webauthn_authentication_challenge],
        public_key: stored_credential.public_key,
        sign_count: stored_credential.sign_count
      )

      stored_credential.update!(sign_count: webauthn_credential.sign_count)
      session.delete(:webauthn_authentication_challenge)

      # Mark session as 2FA verified
      session[:two_factor_verified] = true
      session[:two_factor_verified_at] = Time.current.to_i

      render json: {
        status: 'success',
        message: 'Authentication successful!'
      }
    rescue WebAuthn::Error => e
      render json: {
        status: 'error',
        message: "Authentication failed: #{e.message}"
      }, status: :unprocessable_entity
    end
  end

  private

  def set_credential
    @credential = current_user.webauthn_credentials.find(params[:id])
  end
end
