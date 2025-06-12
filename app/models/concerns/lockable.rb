# frozen_string_literal: true

module Lockable
  extend ActiveSupport::Concern

  included do
    # Account locking scopes (only for ActiveRecord classes)
    if respond_to?(:scope)
      scope :locked, -> { where.not(locked_at: nil) }
      scope :unlocked, -> { where(locked_at: nil) }
      scope :auto_locked, -> { where.not(locked_at: nil).where(locked_by_admin: false) }
      scope :admin_locked, -> { where.not(locked_at: nil).where(locked_by_admin: true) }
    end
  end

  # Constants
  MAX_FAILED_LOGIN_ATTEMPTS = 5
  FAILED_LOGIN_RESET_TIME = 24.hours

  # Account status methods
  def locked?
    locked_at.present?
  end

  def unlocked?
    !locked?
  end

  def auto_locked?
    locked? && !locked_by_admin
  end

  def admin_locked?
    locked? && locked_by_admin
  end

  def can_self_unlock?
    auto_locked?
  end

  def active_for_authentication?
    !locked?
  end

  # Account locking and unlocking
  def lock_account!(admin_locked: false)
    update!(
      locked_at: Time.current,
      locked_by_admin: admin_locked
    )
  end

  def unlock_account!
    update!(
      locked_at: nil,
      locked_by_admin: false,
      failed_login_attempts: 0,
      auto_unlock_token: nil
    )
  end

  # Failed login attempt tracking
  def record_failed_login!
    now = Time.current
    
    # Reset failed attempts if it's been more than 24 hours since last failed login
    if last_failed_login_at && last_failed_login_at < FAILED_LOGIN_RESET_TIME.ago
      self.failed_login_attempts = 0
    end
    
    self.failed_login_attempts += 1
    self.last_failed_login_at = now
    
    # Auto-lock account if max attempts reached
    if failed_login_attempts >= MAX_FAILED_LOGIN_ATTEMPTS
      self.locked_at = now
      self.locked_by_admin = false
      generate_auto_unlock_token
      
      # Send notification email if user has email
      send_account_locked_notification if respond_to?(:email) && email.present?
    end
    
    save!
  end

  def reset_failed_login_attempts!
    update!(
      failed_login_attempts: 0,
      last_failed_login_at: nil
    )
  end

  def generate_auto_unlock_token
    self.auto_unlock_token = SecureRandom.urlsafe_base64(32)
  end

  def generate_auto_unlock_token!
    generate_auto_unlock_token
    save!
  end

  private

  def send_account_locked_notification
    UserMailer.account_locked(self).deliver_now
  end
end