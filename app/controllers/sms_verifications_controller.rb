# frozen_string_literal: true

class SmsVerificationsController < ApplicationController
  include ApplicationHelper

  def verify
    @user = User.find_by(phone: params[:phone])

    unless @user
      redirect_to new_session_path, alert: I18n.t('sms_verifications.verify.user_not_found')
      return
    end

    unless @user.sms_verification_code_valid?(params[:code])
      redirect_to new_session_path, alert: I18n.t('sms_verifications.verify.invalid_code')
      return
    end

    @user.verify_phone!

    # Auto-sign in the user after successful verification
    session[:user_id] = @user.id
    redirect_to dashboard_path, notice: I18n.t('sms_verifications.verify.success')
  end

  def resend
    @user = User.find_by(phone: params[:phone])

    unless @user
      redirect_to new_session_path, alert: I18n.t('sms_verifications.resend.user_not_found')
      return
    end

    if @user.phone_verified?
      redirect_to new_session_path, alert: I18n.t('sms_verifications.resend.already_verified')
      return
    end

    @user.generate_sms_verification_code!
    SmsVerificationJob.perform_later(@user)

    redirect_to new_session_path, notice: I18n.t('sms_verifications.resend.sent')
  end
end
