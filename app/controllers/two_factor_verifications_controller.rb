class TwoFactorVerificationsController < ApplicationController
  before_action :require_pending_user

  def show
    @user = User.find(session[:pending_user_id])
    # Render the 2FA verification page
  end

  def verify
    # This is handled by the WebAuthn controller via AJAX
    # After successful WebAuthn verification, complete the login
    @user = User.find(session[:pending_user_id])

    if session[:two_factor_verified]
      # Complete the login process
      session.delete(:pending_user_id)
      session.delete(:two_factor_verified)
      session.delete(:two_factor_verified_at)

      sign_in(@user)
      redirect_to dashboard_path, notice: 'Successfully signed in with two-factor authentication.'
    else
      redirect_to two_factor_verification_path, alert: 'Two-factor authentication is required.'
    end
  end

  private

  def require_pending_user
    return if session[:pending_user_id]

    redirect_to new_session_path, alert: 'Please sign in first.'
  end
end
