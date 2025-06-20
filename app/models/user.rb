# == Schema Information
#
# Table name: users
#
#  id                                  :bigint           not null, primary key
#  bio                                 :text
#  contact_method                      :string
#  email                               :string
#  email_verification_token            :string
#  email_verification_token_expires_at :datetime
#  email_verified_at                   :datetime
#  latitude                            :decimal(10, 6)
#  location_name                       :string
#  location_private                    :boolean          default(FALSE), not null
#  longitude                           :decimal(10, 6)
#  password_digest                     :string
#  phone                               :string
#  registration_step                   :integer          default(1)
#  username                            :string
#  created_at                          :datetime         not null
#  updated_at                          :datetime         not null
#
# Indexes
#
#  index_users_on_email                     (email) UNIQUE
#  index_users_on_email_verification_token  (email_verification_token) UNIQUE
#  index_users_on_latitude_and_longitude    (latitude,longitude)
#  index_users_on_phone                     (phone) UNIQUE
#  index_users_on_username                  (username) UNIQUE
#

class User < ApplicationRecord
  include Locatable
  include Validatable
  include Authorizable
  include Lockable

  has_secure_password validations: false
  has_one_attached :profile_photo
  has_many :webauthn_credentials, dependent: :destroy

  before_create :generate_email_verification_token, if: -> { email.present? }

  scope :verified, -> { where.not(email_verified_at: nil) }
  scope :unverified, -> { where(email_verified_at: nil) }
  scope :phone_verified, -> { where.not(phone_verified_at: nil) }
  scope :phone_unverified, -> { where(phone_verified_at: nil) }

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

  def phone_verified?
    phone_verified_at.present?
  end

  def verify_phone!
    update!(
      phone_verified_at: Time.current,
      sms_verification_code: nil,
      sms_verification_code_expires_at: nil
    )
  end

  def generate_sms_verification_code!
    generate_sms_verification_code
    save!
  end

  def sms_verification_code_expired?
    sms_verification_code_expires_at.present? && sms_verification_code_expires_at < Time.current
  end

  def sms_verification_code_valid?(code)
    return false if sms_verification_code.blank?
    return false if sms_verification_code_expired?

    sms_verification_code == code
  end

  def registration_complete?
    registration_step && registration_step >= 6
  end

  def two_factor_enabled?
    two_factor_enabled && webauthn_credentials.any?
  end

  def enable_two_factor!
    update!(two_factor_enabled: true)
  end

  def disable_two_factor!
    webauthn_credentials.destroy_all
    update!(two_factor_enabled: false)
  end

  def webauthn_user_id
    id.to_s
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
    when 6
      true # Location step is optional
    else
      false
    end
  end

  def advance_to_next_step!
    return false unless can_advance_to_step?(registration_step + 1)

    update!(registration_step: registration_step + 1)
  end

  private

  def generate_email_verification_token
    self.email_verification_token = SecureRandom.urlsafe_base64(32)
    self.email_verification_token_expires_at = 24.hours.from_now
  end

  def generate_sms_verification_code
    self.sms_verification_code = format('%06d', SecureRandom.random_number(1_000_000))
    self.sms_verification_code_expires_at = 15.minutes.from_now
  end
end
