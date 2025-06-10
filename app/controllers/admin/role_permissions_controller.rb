class Admin::RolePermissionsController < ApplicationController
  include Authorization
  
  before_action :require_admin!
  before_action :set_role
  before_action :set_permission, only: [:create, :destroy]
  
  def update
    permission_ids = params[:permission_ids] || []
    
    # Use a transaction to ensure atomic updates
    ActiveRecord::Base.transaction do
      @role.permission_ids = permission_ids
    end
    
    redirect_to admin_role_path(@role), notice: 'Permissions updated successfully.'
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_role_path(@role), alert: "Failed to update permissions: #{e.message}"
  end
  
  def create
    if @role.permissions.include?(@permission)
      redirect_to admin_role_path(@role), alert: 'Permission is already assigned to this role.'
      return
    end
    
    @role.permissions << @permission
    redirect_to admin_role_path(@role), notice: 'Permission was successfully added to role.'
  rescue ActiveRecord::RecordInvalid => e
    redirect_to admin_role_path(@role), alert: "Failed to add permission: #{e.message}"
  end
  
  def destroy
    role_permission = @role.role_permissions.find_by(permission: @permission)
    
    if role_permission
      role_permission.destroy
      redirect_to admin_role_path(@role), notice: 'Permission was successfully removed from role.'
    else
      redirect_to admin_role_path(@role), alert: 'Permission is not assigned to this role.'
    end
  end
  
  private
  
  def set_role
    @role = Role.find(params[:role_id])
  end
  
  def set_permission
    @permission = Permission.find(params[:id])
  end
end