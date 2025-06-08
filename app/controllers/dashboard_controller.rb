class DashboardController < ApplicationController
  before_action :require_authentication
  before_action :require_email_verification

  def index
    # Dashboard home page
  end

  private

  def require_email_verification
    return if current_user&.email_verified?

    redirect_to new_session_path, alert: 'Please verify your email address to access the dashboard.'
  end
end
