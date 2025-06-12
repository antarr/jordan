class WebauthnCredential < ApplicationRecord
  belongs_to :user

  validates :webauthn_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :nickname, presence: true, uniqueness: { scope: :user_id }
  validates :sign_count, presence: true, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_defaults, on: :create

  scope :for_user, ->(user) { where(user: user) }

  def increment_sign_count!
    increment!(:sign_count)
  end

  private

  def set_defaults
    self.sign_count ||= 0
  end
end
