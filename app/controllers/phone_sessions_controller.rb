class PhoneSessionsController < ApplicationController
  include ApplicationHelper

  def new
    # Render phone login form
  end

  def create
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

  def request_sms
    user = User.find_by(phone: params[:phone])

    unless user
      render json: { error: I18n.t('phone_sessions.request_sms.phone_not_found') },
             status: :unprocessable_entity
      return
    end

    unless user.phone_verified?
      render json: { error: I18n.t('phone_sessions.request_sms.phone_not_verified') },
             status: :unprocessable_entity
      return
    end

    user.generate_sms_verification_code!
    success = SmsService.send_login_code(user.phone, user.sms_verification_code)

    if success
      response_data = { message: I18n.t('phone_sessions.request_sms.sent') }

      # In development, include the SMS code in the response for easy testing
      response_data[:development_sms_code] = user.sms_verification_code if Rails.env.development?

      render json: response_data
    else
      render json: { error: I18n.t('phone_sessions.request_sms.failed') },
             status: :unprocessable_entity
    end
  end
end
