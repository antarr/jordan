module Authorization
  extend ActiveSupport::Concern

  included do
    before_action :ensure_user_has_role
  end

  private

  def ensure_user_has_role
    return unless user_signed_in?
    return if current_user.role.present?

    current_user.assign_default_role
  end

  def authorize!(permission_name)
    return if current_user&.can?(permission_name)

    handle_authorization_failure(permission_name)
  end

  def authorize_resource!(resource, action)
    return if current_user&.can_access?(resource, action)

    handle_authorization_failure("#{resource}.#{action}")
  end

  def require_admin!
    return if current_user&.admin?

    handle_authorization_failure('admin access')
  end

  def require_moderator_or_admin!
    return if current_user&.admin? || current_user&.moderator?

    handle_authorization_failure('moderator or admin access')
  end

  def can?(permission_name)
    current_user&.can?(permission_name) || false
  end

  def can_access?(resource, action)
    current_user&.can_access?(resource, action) || false
  end

  def admin?
    current_user&.admin? || false
  end

  def moderator?
    current_user&.moderator? || false
  end

  def handle_authorization_failure(permission)
    respond_to do |format|
      format.html do
        flash[:alert] = I18n.t('authorization.access_denied')
        redirect_to dashboard_path
      end
      format.json do
        render json: {
          error: I18n.t('authorization.access_denied'),
          required_permission: permission
        }, status: :forbidden
      end
    end
  end

  # Helper methods for views
  def current_user_can?(permission_name)
    can?(permission_name)
  end

  def current_user_can_access?(resource, action)
    can_access?(resource, action)
  end

  def current_user_admin?
    admin?
  end

  def current_user_moderator?
    moderator?
  end

  helper_method :current_user_can?, :current_user_can_access?,
                :current_user_admin?, :current_user_moderator?
end
