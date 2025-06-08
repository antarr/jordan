class CypressTestHelpersController < ApplicationController
  # Only allow these endpoints in test environment
  before_action :ensure_test_environment
  skip_before_action :verify_authenticity_token

  def clear_users
    User.delete_all
    head :ok
  end

  def create_user
    user = User.create!(
      email: params[:email] || 'test@example.com',
      password: params[:password] || 'password123',
      password_confirmation: params[:password] || 'password123'
    )
    render json: { id: user.id, email: user.email }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: 422
  end

  private

  def ensure_test_environment
    unless Rails.env.test? || Rails.env.development?
      render json: { error: 'Test helpers only available in test and development environments' }, status: 403
    end
  end
end