class EmailVerificationRequestsController < ApplicationController
  def new
    # Show form to request verification email
  end

  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    
    if user&.email_verified?
      redirect_to new_session_path, notice: "Your email is already verified. You can sign in."
    elsif user
      user.generate_email_verification_token!
      EmailVerificationJob.perform_later(user)
      redirect_to new_session_path, notice: "Verification email sent! Please check your inbox."
    else
      flash.now[:alert] = "No account found with that email address."
      render :new, status: :unprocessable_entity
    end
  end
end