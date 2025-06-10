# frozen_string_literal: true

module Authorizable
  extend ActiveSupport::Concern

  included do
    belongs_to :role, optional: true
    after_create :assign_default_role
  end

  # Role-based authorization methods
  def has_role?(role_name)
    role&.name == role_name.to_s
  end

  def admin?
    has_role?(:admin)
  end

  def moderator?
    has_role?(:moderator)
  end

  def can?(permission_name)
    role&.can?(permission_name) || false
  end

  def can_access?(resource, action)
    role&.can_access?(resource, action) || false
  end

  def assign_default_role
    return if role.present?

    default_role = Role.find_by(name: 'user')
    update!(role: default_role) if default_role
  end

  def role_name
    role&.name || 'no_role'
  end

  def permissions
    role&.permissions || Permission.none
  end
end
