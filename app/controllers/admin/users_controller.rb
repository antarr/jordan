class Admin::UsersController < ApplicationController
  include Authorization
  
  before_action :require_admin!
  before_action :set_user, only: [:lock, :unlock]
  
  def index
    @users = User.includes(:role).order(:email)
    @users = @users.where('email ILIKE ? OR username ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @users = @users.limit(50) # Simple pagination
  end

  def lock
    if @user == current_user
      redirect_to admin_users_path, alert: t('admin.users.lock.cannot_lock_own_account')
      return
    end

    if @user.admin?
      redirect_to admin_users_path, alert: t('admin.users.lock.cannot_lock_admin_accounts')
      return
    end

    @user.lock_account!(admin_locked: true)
    redirect_to admin_users_path, notice: t('admin.users.lock.account_locked', email: @user.email)
  end

  def unlock
    @user.unlock_account!
    redirect_to admin_users_path, notice: t('admin.users.unlock.account_unlocked', email: @user.email)
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end