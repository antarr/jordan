# frozen_string_literal: true

class PhoneSessionsController < ApplicationController
  include ApplicationHelper

  def new
    # Render phone login form
  end

  def create
    @phone = params[:phone]
    user = User.find_by(phone: params[:phone])

    unless user
      flash.now[:alert] = I18n.t('phone_sessions.create.phone_not_found')
      render :new, status: :unprocessable_entity
      return
    end

    unless user.phone_verified?
      flash.now[:alert] = I18n.t('phone_sessions.create.phone_not_verified')
      render :new, status: :unprocessable_entity
      return
    end

    # Check if user provided SMS code (for SMS login)
    if params[:sms_code].present?
      if user.sms_verification_code_valid?(params[:sms_code])
        sign_in(user)
        # Clear the SMS code after successful login
        user.update!(sms_verification_code: nil, sms_verification_code_expires_at: nil)
        redirect_to dashboard_path
      else
        flash.now[:alert] = I18n.t('phone_sessions.create.invalid_sms_code')
        render :new, status: :unprocessable_entity
      end
    # Check if user provided password (for password login)
    elsif params[:password].present?
      if user.password_digest.present? && user.authenticate(params[:password])
        sign_in(user)
        redirect_to dashboard_path
      else
        flash.now[:alert] = I18n.t('phone_sessions.create.invalid_password')
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = I18n.t('phone_sessions.create.missing_credentials')
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
