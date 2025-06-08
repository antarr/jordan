class EmailVerificationRequestsController < ApplicationController
  def new
    # Show form to request verification email
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)

    if user && !user.email_verified?
      user.generate_email_verification_token!
      EmailVerificationJob.perform_later(user)
    end

    # Always show the same message for security
    redirect_to new_session_path, notice: I18n.t('controllers.email_verification_requests.create.sent')
  end
end
