class Admin::UsersController < ApplicationController
  include Authorization
  
  before_action :require_admin!
  
  def index
    @users = User.includes(:role).order(:email)
    @users = @users.where('email ILIKE ? OR username ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @users = @users.limit(50) # Simple pagination
  end
end