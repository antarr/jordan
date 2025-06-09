class SessionsController < ApplicationController
  def new
    # Render sign in form
  end

  def create
    # Handle sign in
    @email = params[:email]
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    if user&.authenticate(params[:password])
      if user.email_verified?
        sign_in(user)
        redirect_to dashboard_path
      else
        flash[:alert] = I18n.t('controllers.sessions.create.unverified_email')
        redirect_to new_session_path
      end
    else
      flash.now[:alert] = I18n.t('controllers.sessions.create.invalid_credentials')
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to new_session_path
  end
end
