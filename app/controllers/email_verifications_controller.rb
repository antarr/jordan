class EmailVerificationsController < ApplicationController
  before_action :require_authentication, except: [:show]
  before_action :find_user_by_token, only: [:show]

  def show
    if @user&.email_verification_token_valid?(params[:token])
      @user.verify_email!
      sign_in(@user)
      redirect_to dashboard_path, notice: I18n.t('controllers.email_verifications.show.success')
    else
      redirect_to new_session_path, alert: I18n.t('controllers.email_verifications.show.invalid_or_expired')
    end
  end

  def create
    if current_user.email_verified?
      redirect_to dashboard_path, notice: I18n.t('controllers.email_verifications.create.already_verified')
    else
      current_user.generate_email_verification_token!
      EmailVerificationJob.perform_later(current_user)
      redirect_to dashboard_path, notice: I18n.t('controllers.email_verifications.create.sent')
    end
  end

  private

  def find_user_by_token
    @user = User.find_by(email_verification_token: params[:token]) if params[:token].present?
  end
end
