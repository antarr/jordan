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
#  profile_photo                       :string
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
FactoryBot.define do
  factory :user do
    contact_method { 'email' }
    registration_step { 2 }
    email { Faker::Internet.email }
    password { Faker::Internet.password(min_length: 6, max_length: 72) }
    password_confirmation { password }
    username { Faker::Internet.username(specifier: 5..12, separators: %w[_]).gsub(/[^a-zA-Z0-9_]/, '_') }
    bio { Faker::Lorem.paragraph(sentence_count: 3, supplemental: true, random_sentences_to_add: 2) }
    phone { nil }
    profile_photo { Faker::Internet.url(host: 'example.com', path: '/photo.jpg') }
    latitude { nil }
    longitude { nil }
    location_name { nil }
    location_private { false }

    # Different registration steps
    trait :step_one do
      registration_step { 1 }
      email { nil }
      password { nil }
      password_confirmation { nil }
    end

    trait :step_two do
      registration_step { 2 }
    end

    trait :step_three do
      registration_step { 3 }
    end

    trait :step_four do
      registration_step { 4 }
    end

    trait :step_five do
      registration_step { 5 }
    end

    trait :step_six do
      registration_step { 6 }
    end

    # Contact method variants
    trait :phone_user do
      contact_method { 'phone' }
      email { nil }
      phone { Faker::PhoneNumber.cell_phone_in_e164 }
    end

    trait :email_user do
      contact_method { 'email' }
      email { Faker::Internet.email }
      phone { nil }
    end

    # Email verification states
    trait :verified do
      email_verified_at { Faker::Time.between(from: 1.week.ago, to: Time.current) }
      email_verification_token { nil }
      email_verification_token_expires_at { nil }
    end

    trait :unverified do
      email_verified_at { nil }
      email_verification_token { Faker::Alphanumeric.alphanumeric(number: 32) }
      email_verification_token_expires_at { Faker::Time.between(from: Time.current, to: 24.hours.from_now) }
    end

    trait :expired_token do
      email_verified_at { nil }
      email_verification_token { Faker::Alphanumeric.alphanumeric(number: 32) }
      email_verification_token_expires_at { 2.hours.ago }
    end

    # Registration completion states
    trait :incomplete_registration do
      registration_step { Faker::Number.between(from: 1, to: 5) }
    end

    trait :complete_registration do
      registration_step { 6 }
    end

    # Invalid data traits for testing validations
    trait :invalid_email do
      email { 'invalid-email-format' }
    end

    trait :invalid_phone do
      contact_method { 'phone' }
      phone { 'invalid-phone-format' }
    end

    trait :short_password do
      password { '12345' }
      password_confirmation { '12345' }
    end

    trait :long_password do
      password { 'a' * 73 }
      password_confirmation { 'a' * 73 }
    end

    trait :short_bio do
      bio { Faker::Lorem.sentence(word_count: 3) }
    end

    trait :invalid_username do
      username { 'invalid@username!' }
    end

    # Location traits
    trait :with_location do
      latitude { Faker::Address.latitude }
      longitude { Faker::Address.longitude }
      location_name { Faker::Address.city }
    end

    trait :with_private_location do
      latitude { Faker::Address.latitude }
      longitude { Faker::Address.longitude }
      location_name { Faker::Address.city }
      location_private { true }
    end

    trait :with_coordinates_only do
      latitude { Faker::Address.latitude }
      longitude { Faker::Address.longitude }
      location_name { nil }
    end
  end
end
