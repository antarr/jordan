class SessionsController < ApplicationController
  def new
    # Render sign in form
  end

  def create
    # Handle sign in
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      sign_in(user)
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out
    redirect_to root_path
  end
end
