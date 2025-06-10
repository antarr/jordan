class Role < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :permissions, through: :role_permissions
  has_many :users, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true

  scope :system_roles, -> { where(system_role: true) }
  scope :custom_roles, -> { where(system_role: false) }

  def can?(permission_name)
    permissions.exists?(name: permission_name)
  end

  def can_access?(resource, action)
    permissions.exists?(resource: resource, action: action)
  end

  def admin?
    name == 'admin'
  end

  def moderator?
    name == 'moderator'
  end

  def user?
    name == 'user'
  end

  def system?
    system_role?
  end
end
