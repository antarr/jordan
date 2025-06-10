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
    return false unless verify_account_status

    success = authenticate_with_credentials
    
    if success
      # Reset failed login attempts on successful login
      @user.reset_failed_login_attempts!
    else
      # Check if user will be locked before recording failed attempt
      will_be_locked = @user.failed_login_attempts >= (Lockable::MAX_FAILED_LOGIN_ATTEMPTS - 1)
      
      # Record failed login attempt
      @user.record_failed_login!
      
      # Update error message if account was just locked
      if will_be_locked && @user.locked?
        @errors = [I18n.t('phone_sessions.create.account_just_locked')]
      end
    end
    
    success
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

  def verify_account_status
    if @user.locked?
      if @user.auto_locked?
        @errors << I18n.t('phone_sessions.create.account_auto_locked')
      else
        @errors << I18n.t('phone_sessions.create.account_locked')
      end
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
