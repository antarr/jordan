class DashboardController < ApplicationController
  before_action :require_login

  def index
    # Dashboard home page
  end

  private

  def require_login
    return if session[:user_id]

    redirect_to new_session_path, alert: 'Please log in to access the dashboard.'
  end
end
