class SeedDefaultRolesAndPermissions < ActiveRecord::Migration[8.0]
  def up
    # Create default roles
    admin_role = Role.create!(
      name: 'admin',
      description: 'System administrator with full access',
      system_role: true
    )

    moderator_role = Role.create!(
      name: 'moderator',
      description: 'Content moderator with limited admin access',
      system_role: true
    )

    user_role = Role.create!(
      name: 'user',
      description: 'Standard user with basic access',
      system_role: true
    )

    # Create default permissions
    permissions = [
      # User management
      { name: 'users.read', description: 'View users', resource: 'users', action: 'read' },
      { name: 'users.create', description: 'Create users', resource: 'users', action: 'create' },
      { name: 'users.update', description: 'Update users', resource: 'users', action: 'update' },
      { name: 'users.delete', description: 'Delete users', resource: 'users', action: 'delete' },

      # Profile management
      { name: 'profiles.read', description: 'View profiles', resource: 'profiles', action: 'read' },
      { name: 'profiles.update', description: 'Update profiles', resource: 'profiles', action: 'update' },

      # Dashboard access
      { name: 'dashboard.read', description: 'Access dashboard', resource: 'dashboard', action: 'read' },

      # Role management
      { name: 'roles.read', description: 'View roles', resource: 'roles', action: 'read' },
      { name: 'roles.create', description: 'Create roles', resource: 'roles', action: 'create' },
      { name: 'roles.update', description: 'Update roles', resource: 'roles', action: 'update' },
      { name: 'roles.delete', description: 'Delete roles', resource: 'roles', action: 'delete' },

      # Permission management
      { name: 'permissions.read', description: 'View permissions', resource: 'permissions', action: 'read' },
      { name: 'permissions.create', description: 'Create permissions', resource: 'permissions', action: 'create' },
      { name: 'permissions.update', description: 'Update permissions', resource: 'permissions', action: 'update' },
      { name: 'permissions.delete', description: 'Delete permissions', resource: 'permissions', action: 'delete' },

      # Admin panel access
      { name: 'admin.read', description: 'Access admin panel', resource: 'admin', action: 'read' }
    ]

    created_permissions = permissions.map do |perm_data|
      Permission.create!(perm_data)
    end

    # Assign permissions to roles

    # Admin gets all permissions
    admin_role.permissions = created_permissions

    # Moderator gets limited permissions
    moderator_permissions = created_permissions.select do |permission|
      %w[
        users.read users.update
        profiles.read profiles.update
        dashboard.read
        roles.read
        permissions.read
      ].include?(permission.name)
    end
    moderator_role.permissions = moderator_permissions

    # User gets basic permissions
    user_permissions = created_permissions.select do |permission|
      %w[
        profiles.read profiles.update
        dashboard.read
      ].include?(permission.name)
    end
    user_role.permissions = user_permissions

    # Set default role for existing users
    User.where(role: nil).update_all(role_id: user_role.id)
  end

  def down
    # Remove all role permissions
    RolePermission.delete_all

    # Remove all permissions
    Permission.delete_all

    # Remove role from users
    User.update_all(role_id: nil)

    # Remove all roles
    Role.delete_all
  end
end
