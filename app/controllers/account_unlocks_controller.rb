class AccountUnlocksController < ApplicationController
  before_action :redirect_if_signed_in, only: [:new, :create]

  def new
    # Form to request account unlock
  end

  def create
    @email = params[:email]&.strip&.downcase
    user = User.find_by(email: @email) if @email.present?

    if user&.auto_locked?
      # Generate unlock token if user doesn't have one
      user.generate_auto_unlock_token! unless user.auto_unlock_token.present?
      
      # Send unlock email
      UserMailer.account_unlock(user).deliver_now
      flash[:notice] = I18n.t('account_unlocks.create.sent')
    else
      # Don't reveal whether email exists or account status for security
      flash[:notice] = I18n.t('account_unlocks.create.sent')
    end

    redirect_to new_session_path
  end

  def unlock
    @token = params[:token]
    user = User.find_by(auto_unlock_token: @token) if @token.present?

    if user&.auto_locked? && user.auto_unlock_token == @token
      user.unlock_account!
      flash[:notice] = I18n.t('account_unlocks.unlock.success')
      redirect_to new_session_path
    else
      flash[:alert] = I18n.t('account_unlocks.unlock.invalid_token')
      redirect_to new_session_path
    end
  end

  private

  def redirect_if_signed_in
    redirect_to dashboard_path if user_signed_in?
  end
end
