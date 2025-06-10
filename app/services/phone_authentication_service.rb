# frozen_string_literal: true

class PhoneAuthenticationService
  include ActiveModel::Model

  attr_accessor :phone, :sms_code, :password
  attr_reader :user, :errors

  def initialize(params = {})
    @phone = params[:phone]
    @sms_code = params[:sms_code]
    @password = params[:password]
    @errors = []
  end

  def authenticate
    return false unless find_user
    return false unless verify_phone_status

    authenticate_with_credentials
  end

  def success?
    @errors.empty?
  end

  def error_message
    @errors.first
  end

  private

  def find_user
    @user = User.find_by(phone: @phone)

    unless @user
      @errors << I18n.t('phone_sessions.create.phone_not_found')
      return false
    end

    true
  end

  def verify_phone_status
    unless @user.phone_verified?
      @errors << I18n.t('phone_sessions.create.phone_not_verified')
      return false
    end

    true
  end

  def authenticate_with_credentials
    if sms_code_provided?
      authenticate_with_sms_code
    elsif password_provided?
      authenticate_with_password
    else
      @errors << I18n.t('phone_sessions.create.missing_credentials')
      false
    end
  end

  def sms_code_provided?
    @sms_code.present?
  end

  def password_provided?
    @password.present?
  end

  def authenticate_with_sms_code
    if @user.sms_verification_code_valid?(@sms_code)
      clear_sms_code
      true
    else
      @errors << I18n.t('phone_sessions.create.invalid_sms_code')
      false
    end
  end

  def authenticate_with_password
    if @user.password_digest.present? && @user.authenticate(@password)
      true
    else
      @errors << I18n.t('phone_sessions.create.invalid_password')
      false
    end
  end

  def clear_sms_code
    @user.update!(sms_verification_code: nil, sms_verification_code_expires_at: nil)
  end
end
