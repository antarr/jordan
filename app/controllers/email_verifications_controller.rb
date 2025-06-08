class EmailVerificationsController < ApplicationController
  before_action :require_authentication, except: [:show]
  before_action :find_user_by_token, only: [:show]

  def show
    if @user&.email_verification_token_valid?(params[:token])
      @user.verify_email!
      sign_in(@user)
      redirect_to dashboard_path, notice: "Your email has been verified successfully!"
    else
      redirect_to new_session_path, alert: "Invalid or expired verification link."
    end
  end

  def create
    if current_user.email_verified?
      redirect_to dashboard_path, notice: "Your email is already verified."
    else
      current_user.generate_email_verification_token!
      EmailVerificationJob.perform_later(current_user)
      redirect_to dashboard_path, notice: "Verification email sent! Please check your inbox."
    end
  end

  private

  def find_user_by_token
    @user = User.find_by(email_verification_token: params[:token]) if params[:token].present?
  end
end