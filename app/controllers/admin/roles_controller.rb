class Admin::RolesController < ApplicationController
  include Authorization
  
  before_action :require_admin!
  before_action :set_role, only: [:show, :edit, :update, :destroy]
  
  def index
    @roles = Role.includes(:permissions, :users).order(:name)
  end
  
  def show
    @permissions = Permission.order(:resource, :action)
    @users = @role.users.includes(:role)
  end
  
  def new
    @role = Role.new
  end
  
  def create
    @role = Role.new(role_params)
    
    if @role.save
      redirect_to admin_roles_path, notice: I18n.t('admin.roles.create.success')
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @role.update(role_params)
      redirect_to admin_roles_path, notice: 'Role was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @role.system_role?
      redirect_to admin_roles_path, alert: 'System roles cannot be deleted.'
    elsif @role.users.any?
      redirect_to admin_roles_path, alert: 'Cannot delete role with assigned users.'
    else
      @role.destroy
      redirect_to admin_roles_path, notice: 'Role was successfully deleted.'
    end
  end
  
  private
  
  def set_role
    @role = Role.find(params[:id])
  end
  
  def role_params
    params.require(:role).permit(:name, :description)
  end
end