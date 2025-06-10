# frozen_string_literal: true

module Validatable
  extend ActiveSupport::Concern

  included do
    validates :email, presence: true, uniqueness: { case_sensitive: false }, if: lambda {
      contact_method == 'email' && registration_step && registration_step >= 2
    }
    validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, if: -> { email.present? }
    validates :phone, presence: true, uniqueness: { case_sensitive: false }, if: lambda {
      contact_method == 'phone' && registration_step && registration_step >= 2
    }
    validates :phone, format: { with: /\A\+?[1-9]\d{3,14}\z/ }, if: -> { phone.present? }
    validates :username, presence: true, uniqueness: { case_sensitive: false }, if: lambda {
      registration_step && registration_step >= 3
    }
    validates :username, format: { with: /\A[a-zA-Z0-9_]+\z/ }, if: -> { username.present? }
    validates :bio, presence: true, length: { minimum: 25 }, if: lambda {
      registration_step && registration_step >= 4
    }
    validates :password, presence: true, length: { minimum: 6, maximum: 72 }, if: lambda {
      # Email users must have password during registration
      # Phone users can set password later in profile (optional)
      if contact_method == 'email'
        new_record? ? (registration_step && registration_step >= 2) : password.present?
      else
        password.present? # Only validate if password is being set
      end
    }
    validates :password_confirmation, presence: true, if: -> { password.present? }
    validate :password_confirmation_matches, if: -> { password.present? && password_confirmation.present? }
    validates :contact_method, inclusion: { in: %w[email phone] }, if: -> { contact_method.present? }

    before_validation :normalize_email, if: -> { email.present? }
  end

  private

  def password_confirmation_matches
    return if password == password_confirmation

    errors.add(:password_confirmation, "doesn't match Password")
  end

  def normalize_email
    self.email = email.to_s.downcase.strip
  end
end