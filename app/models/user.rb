class User < ApplicationRecord
  has_secure_password validations: false

  validates :email, presence: true, uniqueness: { case_sensitive: false }, if: -> { 
    contact_method == 'email' && registration_step && registration_step >= 2
  }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, if: -> { email.present? }
  validates :phone, presence: true, uniqueness: { case_sensitive: false }, if: -> { 
    contact_method == 'phone' && registration_step && registration_step >= 2 
  }
  validates :phone, format: { with: /\A\+?[1-9]\d{3,14}\z/ }, if: -> { phone.present? }
  validates :username, presence: true, uniqueness: { case_sensitive: false }, if: -> { 
    registration_step && registration_step >= 3
  }
  validates :username, format: { with: /\A[a-zA-Z0-9_]+\z/ }, if: -> { username.present? }
  validates :bio, presence: true, length: { minimum: 25 }, if: -> { 
    registration_step && registration_step >= 4
  }
  validates :password, presence: true, length: { minimum: 6, maximum: 72 }, if: -> { 
    new_record? ? (registration_step && registration_step >= 2) : password.present?
  }
  validates :password_confirmation, presence: true, if: -> { password.present? }
  validate :password_confirmation_matches, if: -> { password.present? && password_confirmation.present? }
  validates :contact_method, inclusion: { in: %w[email phone] }, if: -> { contact_method.present? }

  before_validation :normalize_email, if: -> { email.present? }
  before_create :generate_email_verification_token, if: -> { email.present? }

  scope :verified, -> { where.not(email_verified_at: nil) }
  scope :unverified, -> { where(email_verified_at: nil) }

  def email_verified?
    email_verified_at.present?
  end

  def verify_email!
    update!(
      email_verified_at: Time.current,
      email_verification_token: nil,
      email_verification_token_expires_at: nil
    )
  end

  def generate_email_verification_token!
    generate_email_verification_token
    save!
  end

  def email_verification_token_expired?
    email_verification_token_expires_at.present? && email_verification_token_expires_at < Time.current
  end

  def email_verification_token_valid?(token)
    return false if email_verification_token.blank?
    return false if email_verification_token_expired?
    
    email_verification_token == token
  end

  def registration_complete?
    registration_step && registration_step >= 5
  end

  def can_advance_to_step?(step)
    case step
    when 2
      contact_method.present?
    when 3
      (contact_method == 'email' && email.present?) || (contact_method == 'phone' && phone.present?)
    when 4
      username.present?
    when 5
      bio.present? && bio.length >= 25
    else
      false
    end
  end

  def advance_to_next_step!
    return false unless can_advance_to_step?(registration_step + 1)
    update!(registration_step: registration_step + 1)
  end

  private

  def password_confirmation_matches
    return if password == password_confirmation
    errors.add(:password_confirmation, "doesn't match Password")
  end

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def generate_email_verification_token
    self.email_verification_token = SecureRandom.urlsafe_base64(32)
    self.email_verification_token_expires_at = 24.hours.from_now
  end
end
