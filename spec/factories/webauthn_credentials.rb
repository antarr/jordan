FactoryBot.define do
  factory :webauthn_credential do
    user
    sequence(:webauthn_id) { |n| "webauthn_id_#{n}" }
    public_key { 'sample_public_key_data' }
    sequence(:nickname) { |n| "Security Key #{n}" }
    sign_count { 0 }
  end
end
