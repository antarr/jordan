class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || changes[:password_digest] }

  before_validation :normalize_email
  before_create :generate_email_verification_token

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

  private

  def normalize_email
    self.email = email.to_s.downcase.strip
  end

  def generate_email_verification_token
    self.email_verification_token = SecureRandom.urlsafe_base64(32)
    self.email_verification_token_expires_at = 24.hours.from_now
  end
end
