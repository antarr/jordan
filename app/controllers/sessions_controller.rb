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
      if user.email_verified?
        sign_in(user)
        redirect_to dashboard_path
      else
        flash[:alert] = I18n.t('controllers.sessions.create.unverified_email')
        redirect_to new_session_path
      end
    else
      flash.now[:alert] = I18n.t('controllers.sessions.create.invalid_credentials')
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
      sign_in(auth_service.user)
      redirect_to dashboard_path
    else
      flash.now[:alert] = auth_service.error_message
      render :new, status: :unprocessable_entity
    end
  end
end
