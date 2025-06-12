class SessionsController < ApplicationController
  def new
    # Render sign in form
  end

  def create
    if params[:login_type] == 'phone'
      handle_phone_login
    elsif params[:login_type] == 'email'
      handle_email_login
    else
      # Default to email for backward compatibility
      handle_email_login
    end
  end

  def destroy
    sign_out
    redirect_to new_session_path
  end

  def request_sms
    user = User.find_by(phone: params[:phone])

    unless user
      render json: { error: I18n.t('controllers.sessions.request_sms.phone_not_found') },
             status: :unprocessable_entity
      return
    end

    unless user.phone_verified?
      render json: { error: I18n.t('controllers.sessions.request_sms.phone_not_verified') },
             status: :unprocessable_entity
      return
    end

    user.generate_sms_verification_code!
    success = SmsService.send_login_code(user.phone, user.sms_verification_code)

    if success
      response_data = { message: I18n.t('controllers.sessions.request_sms.sent') }

      # In development, include the SMS code in the response for easy testing
      response_data[:development_sms_code] = user.sms_verification_code if Rails.env.development?

      render json: response_data
    else
      render json: { error: I18n.t('controllers.sessions.request_sms.failed') },
             status: :unprocessable_entity
    end
  end

  private

  def handle_email_login
    @email = params[:email]
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      if user.locked?
        if user.auto_locked?
          flash[:alert] = I18n.t('controllers.sessions.create.account_auto_locked')
        else
          flash[:alert] = I18n.t('controllers.sessions.create.account_locked')
        end
        redirect_to new_session_path
      elsif user.email_verified?
        # Reset failed login attempts on successful login
        user.reset_failed_login_attempts!
        
        if user.two_factor_enabled?
          # Store user ID in session for 2FA verification
          session[:pending_user_id] = user.id
          session[:two_factor_verified] = false
          redirect_to two_factor_verification_path
        else
          sign_in(user)
          redirect_to dashboard_path
        end
      else
        flash[:alert] = I18n.t('controllers.sessions.create.unverified_email')
        redirect_to new_session_path
      end
    else
      # Check if user will be locked before recording failed attempt
      will_be_locked = user && user.failed_login_attempts >= (Lockable::MAX_FAILED_LOGIN_ATTEMPTS - 1)
      
      # Record failed login attempt if user exists
      user&.record_failed_login!
      
      # Show appropriate message based on whether account was just locked
      if will_be_locked && user&.locked?
        flash.now[:alert] = I18n.t('controllers.sessions.create.account_just_locked')
      else
        flash.now[:alert] = I18n.t('controllers.sessions.create.invalid_credentials')
      end
      
      # Clear password for security when authentication fails
      params[:password] = nil
      render :new, status: :unprocessable_entity
    end
  end

  def handle_phone_login
    @phone = params[:phone]
    auth_service = PhoneAuthenticationService.new(
      phone: params[:phone],
      sms_code: params[:sms_code],
      password: params[:password]
    )

    if auth_service.authenticate
      user = auth_service.user
      if user.two_factor_enabled?
        # Store user ID in session for 2FA verification
        session[:pending_user_id] = user.id
        session[:two_factor_verified] = false
        redirect_to two_factor_verification_path
      else
        sign_in(user)
        redirect_to dashboard_path
      end
    else
      flash.now[:alert] = auth_service.error_message
      # Clear password for security when authentication fails
      params[:password] = nil
      render :new, status: :unprocessable_entity
    end
  end
end
