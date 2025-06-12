class Admin::UserRolesController < ApplicationController
  include Authorization
  
  before_action :require_admin!
  before_action :set_user
  
  def edit
    @roles = Role.order(:name)
  end
  
  def update
    if @user.update(user_role_params)
      redirect_to admin_users_path, notice: 'User role updated successfully.'
    else
      @roles = Role.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end
  
  private
  
  def set_user
    @user = User.find(params[:user_id])
  end
  
  def user_role_params
    params.require(:user).permit(:role_id)
  end
end