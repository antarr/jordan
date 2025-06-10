class Permission < ApplicationRecord
  has_many :role_permissions, dependent: :destroy
  has_many :roles, through: :role_permissions

  validates :name, presence: true, uniqueness: true
  validates :resource, presence: true
  validates :action, presence: true
  validates :description, presence: true

  validate :unique_resource_action_combination

  scope :for_resource, ->(resource) { where(resource: resource) }
  scope :for_action, ->(action) { where(action: action) }

  def full_name
    "#{resource}.#{action}"
  end

  def self.find_by_resource_action(resource, action)
    find_by(resource: resource, action: action)
  end

  private

  def unique_resource_action_combination
    return unless resource.present? && action.present?

    existing = Permission.where(resource: resource, action: action)
    existing = existing.where.not(id: id) if persisted?

    errors.add(:base, 'Resource and action combination must be unique') if existing.exists?
  end
end
