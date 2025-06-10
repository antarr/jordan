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
      redirect_to admin_users_path, alert: 'Cannot lock your own account.'
      return
    end

    if @user.admin?
      redirect_to admin_users_path, alert: 'Cannot lock admin accounts.'
      return
    end

    @user.lock_account!(admin_locked: true)
    redirect_to admin_users_path, notice: "#{@user.email} has been locked."
  end

  def unlock
    @user.unlock_account!
    redirect_to admin_users_path, notice: "#{@user.email} has been unlocked."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end