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
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    context 'when contact_method is email and registration_step >= 2' do
      subject { build(:user, :email_user, :step_two) }

      it { is_expected.to validate_presence_of(:email) }
      it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
      it { is_expected.to allow_value(Faker::Internet.email).for(:email) }
      it { is_expected.not_to allow_value('invalid-email').for(:email) }
      it { is_expected.not_to allow_value('user@').for(:email) }
      it { is_expected.not_to allow_value('@example.com').for(:email) }
      it { is_expected.not_to allow_value('user example@test.com').for(:email) }
      it { is_expected.not_to allow_value('user@example..com').for(:email) }

      it 'accepts valid email formats' do
        valid_emails = [
          Faker::Internet.email,
          'user.name@example.com',
          'user+tag@example.co.uk',
          'user_name@example-domain.com',
          '123@example.com',
          'user@subdomain.example.com'
        ]

        valid_emails.each do |valid_email|
          user = build(:user, :email_user, :step_two, email: valid_email)
          expect(user).to be_valid, "Expected #{valid_email} to be valid"
        end
      end

      it 'normalizes email by stripping whitespace and downcasing' do
        email = Faker::Internet.email.upcase
        user = create(:user, :email_user, :step_two, email: "  #{email}  ")
        expect(user.email).to eq(email.downcase.strip)
      end
    end

    context 'when contact_method is phone and registration_step >= 2' do
      subject { build(:user, :phone_user, :step_two) }

      it { is_expected.to validate_presence_of(:phone) }
      it { is_expected.to validate_uniqueness_of(:phone).case_insensitive }
      it { is_expected.to allow_value('+1234567890').for(:phone) }
      it { is_expected.to allow_value('+12345678901234').for(:phone) }
      it { is_expected.not_to allow_value('invalid-phone').for(:phone) }
      it { is_expected.not_to allow_value('123').for(:phone) }
    end

    context 'when registration_step >= 3' do
      subject { build(:user, :step_three) }

      it { is_expected.to validate_presence_of(:username) }
      it { is_expected.to validate_uniqueness_of(:username).case_insensitive }
      it { is_expected.to allow_value(Faker::Internet.username(specifier: 5..12, separators: %w[_])).for(:username) }
      it { is_expected.not_to allow_value('invalid@username!').for(:username) }
    end

    context 'when registration_step >= 4' do
      subject { build(:user, :step_four) }

      it { is_expected.to validate_presence_of(:bio) }
      it { is_expected.to validate_length_of(:bio).is_at_least(25) }
    end

    context 'password validations' do
      subject { build(:user, :step_two) }

      it { is_expected.to validate_presence_of(:password) }
      it { is_expected.to validate_length_of(:password).is_at_least(6).is_at_most(72) }
      it { is_expected.to validate_presence_of(:password_confirmation) }

      it 'validates password confirmation matches' do
        user = build(:user, password: 'password123', password_confirmation: 'different')
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to include("doesn't match Password")
      end
    end

    context 'contact_method validation' do
      it { is_expected.to allow_value('email').for(:contact_method) }
      it { is_expected.to allow_value('phone').for(:contact_method) }
      it { is_expected.not_to allow_value('invalid').for(:contact_method) }
    end

    context 'location validations' do
      it { is_expected.to allow_value(37.7749).for(:latitude) }
      it { is_expected.to allow_value(-122.4194).for(:longitude) }
      it { is_expected.not_to allow_value(91).for(:latitude) }
      it { is_expected.not_to allow_value(-91).for(:latitude) }
      it { is_expected.not_to allow_value(181).for(:longitude) }
      it { is_expected.not_to allow_value(-181).for(:longitude) }

      it 'requires longitude when latitude is present' do
        user = build(:user, latitude: 37.7749, longitude: nil)
        expect(user).not_to be_valid
        expect(user.errors[:longitude]).to include("can't be blank")
      end

      it 'requires latitude when longitude is present' do
        user = build(:user, latitude: nil, longitude: -122.4194)
        expect(user).not_to be_valid
        expect(user.errors[:latitude]).to include("can't be blank")
      end

      it 'allows both latitude and longitude to be nil' do
        user = build(:user, latitude: nil, longitude: nil)
        expect(user).to be_valid
      end

      it 'allows both latitude and longitude to be present' do
        user = build(:user, latitude: 37.7749, longitude: -122.4194)
        expect(user).to be_valid
      end
    end
  end

  describe 'password authentication' do
    let(:user) { create(:user) }

    it 'authenticates with correct password' do
      expect(user.authenticate(user.password)).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      expect(user.authenticate(Faker::Internet.password)).to be_falsey
    end

    it 'does not require password on update when not changed' do
      user.email = Faker::Internet.email
      expect(user).to be_valid
    end

    it 'encrypts the password' do
      expect(user.password_digest).not_to eq(user.password)
      expect(user.password_digest).to be_present
    end
  end

  describe 'callbacks' do
    it 'generates email verification token before creation for email users' do
      user = build(:user, :email_user)
      expect(user.email_verification_token).to be_nil
      user.save!
      expect(user.email_verification_token).to be_present
      expect(user.email_verification_token_expires_at).to be_present
    end

    it 'does not generate email verification token for phone users' do
      user = build(:user, :phone_user)
      user.save!
      expect(user.email_verification_token).to be_nil
      expect(user.email_verification_token_expires_at).to be_nil
    end
  end

  describe 'scopes' do
    let!(:verified_user) { create(:user, :verified) }
    let!(:unverified_user) { create(:user, :unverified) }

    describe '.verified' do
      it 'returns only verified users' do
        expect(described_class.verified).to include(verified_user)
        expect(described_class.verified).not_to include(unverified_user)
      end
    end

    describe '.unverified' do
      it 'returns only unverified users' do
        expect(described_class.unverified).to include(unverified_user)
        expect(described_class.unverified).not_to include(verified_user)
      end
    end
  end

  describe '#email_verified?' do
    it 'returns true when email_verified_at is present' do
      user = create(:user, :verified)
      expect(user.email_verified?).to be true
    end

    it 'returns false when email_verified_at is nil' do
      user = create(:user, :unverified)
      expect(user.email_verified?).to be false
    end
  end

  describe '#verify_email!' do
    let(:user) { create(:user, :unverified) }

    it 'sets email_verified_at to current time' do
      expect(user.email_verified_at).to be_nil
      user.verify_email!
      expect(user.email_verified_at).to be_present
      expect(user.email_verified_at).to be_within(1.second).of(Time.current)
    end

    it 'clears email_verification_token' do
      expect(user.email_verification_token).to be_present
      user.verify_email!
      expect(user.email_verification_token).to be_nil
    end

    it 'clears email_verification_token_expires_at' do
      expect(user.email_verification_token_expires_at).to be_present
      user.verify_email!
      expect(user.email_verification_token_expires_at).to be_nil
    end
  end

  describe '#generate_email_verification_token!' do
    let(:user) { create(:user, :unverified) }

    it 'generates a new token' do
      old_token = user.email_verification_token
      user.generate_email_verification_token!
      expect(user.email_verification_token).not_to eq(old_token)
    end

    it 'sets expiration time to 24 hours from now' do
      user.generate_email_verification_token!
      expect(user.email_verification_token_expires_at).to be_within(1.minute).of(24.hours.from_now)
    end
  end

  describe '#email_verification_token_expired?' do
    it 'returns false for unexpired tokens' do
      user = create(:user, :unverified, email_verification_token_expires_at: 1.hour.from_now)
      expect(user.email_verification_token_expired?).to be false
    end

    it 'returns true for expired tokens' do
      user = create(:user)
      user.update_columns(email_verification_token_expires_at: 2.hours.ago)
      expect(user.email_verification_token_expired?).to be true
    end

    it 'returns false when expiration time is nil' do
      user = create(:user, :unverified, email_verification_token_expires_at: nil)
      expect(user.email_verification_token_expired?).to be false
    end
  end

  describe '#email_verification_token_valid?' do
    let(:user) { create(:user, :unverified) }

    it 'returns true for valid, unexpired token' do
      token = user.email_verification_token
      expect(user.email_verification_token_valid?(token)).to be true
    end

    it 'returns false for invalid token' do
      expect(user.email_verification_token_valid?(Faker::Alphanumeric.alphanumeric(number: 32))).to be false
    end

    it 'returns false for expired token' do
      user = create(:user)
      user.update_columns(email_verification_token_expires_at: 2.hours.ago)
      token = user.email_verification_token
      expect(user.email_verification_token_valid?(token)).to be false
    end

    it 'returns false when token is blank' do
      user.update!(email_verification_token: nil)
      expect(user.email_verification_token_valid?(Faker::Alphanumeric.alphanumeric(number: 32))).to be false
    end
  end

  describe '#registration_complete?' do
    it 'returns true when registration_step is 6 or higher' do
      user = create(:user, registration_step: 6)
      expect(user.registration_complete?).to be true
    end

    it 'returns false when registration_step is less than 6' do
      user = create(:user, registration_step: 5)
      expect(user.registration_complete?).to be false
    end
  end

  describe 'location methods' do
    describe '#has_location?' do
      it 'returns true when both latitude and longitude are present' do
        user = build(:user, latitude: 37.7749, longitude: -122.4194)
        expect(user.has_location?).to be true
      end

      it 'returns false when latitude is missing' do
        user = build(:user, latitude: nil, longitude: -122.4194)
        expect(user.has_location?).to be false
      end

      it 'returns false when longitude is missing' do
        user = build(:user, latitude: 37.7749, longitude: nil)
        expect(user.has_location?).to be false
      end

      it 'returns false when both are missing' do
        user = build(:user, latitude: nil, longitude: nil)
        expect(user.has_location?).to be false
      end
    end

    describe '#location_coordinates' do
      it 'returns array of latitude and longitude when location is present' do
        user = build(:user, latitude: 37.7749, longitude: -122.4194)
        expect(user.location_coordinates).to eq([37.7749, -122.4194])
      end

      it 'returns nil when location is not present' do
        user = build(:user, latitude: nil, longitude: nil)
        expect(user.location_coordinates).to be_nil
      end
    end

    describe '#location_display' do
      it 'returns location_name when present' do
        user = build(:user, latitude: 37.7749, longitude: -122.4194, location_name: 'San Francisco')
        expect(user.location_display).to eq('San Francisco')
      end

      it 'returns coordinates when location_name is not present' do
        user = build(:user, latitude: 37.7749, longitude: -122.4194, location_name: nil)
        expect(user.location_display).to eq('37.7749, -122.4194')
      end

      it 'returns "Location not set" when location is not present' do
        user = build(:user, latitude: nil, longitude: nil)
        expect(user.location_display).to eq('Location not set')
      end
    end

    describe '#location_public?' do
      it 'returns true when location is present and not private' do
        user = build(:user, latitude: 37.7749, longitude: -122.4194, location_private: false)
        expect(user.location_public?).to be true
      end

      it 'returns false when location is present but private' do
        user = build(:user, latitude: 37.7749, longitude: -122.4194, location_private: true)
        expect(user.location_public?).to be false
      end

      it 'returns false when location is not present' do
        user = build(:user, latitude: nil, longitude: nil, location_private: false)
        expect(user.location_public?).to be false
      end
    end
  end

  describe '#can_advance_to_step?' do
    let(:user) { create(:user, :step_one) }

    it 'returns true for step 2 when contact_method is present' do
      expect(user.can_advance_to_step?(2)).to be true
    end

    it 'returns true for step 3 when email is present for email users' do
      user.update!(contact_method: 'email', email: Faker::Internet.email, registration_step: 2)
      expect(user.can_advance_to_step?(3)).to be true
    end

    it 'returns true for step 3 when phone is present for phone users' do
      user.update!(contact_method: 'phone', phone: Faker::PhoneNumber.cell_phone_in_e164, registration_step: 2)
      expect(user.can_advance_to_step?(3)).to be true
    end

    it 'returns true for step 4 when username is present' do
      user = create(:user, :step_three,
                    username: Faker::Internet.username(specifier: 5..12, separators: %w[_]).gsub(/[^a-zA-Z0-9_]/, '_'))
      expect(user.can_advance_to_step?(4)).to be true
    end

    it 'returns true for step 5 when bio is present and long enough' do
      user = create(:user, :step_four, bio: Faker::Lorem.paragraph(sentence_count: 3))
      expect(user.can_advance_to_step?(5)).to be true
    end

    it 'returns true for step 6 (location step is optional)' do
      user = create(:user, :step_one)
      expect(user.can_advance_to_step?(6)).to be true
    end

    it 'returns false for step 3 when email is missing for email users' do
      user = build_stubbed(:user, contact_method: 'email', email: nil, registration_step: 2)
      expect(user.can_advance_to_step?(3)).to be false
    end

    it 'returns false for step 3 when phone is missing for phone users' do
      user = build_stubbed(:user, contact_method: 'phone', phone: nil, registration_step: 2)
      expect(user.can_advance_to_step?(3)).to be false
    end

    it 'returns false for step 4 when username is missing' do
      user = build_stubbed(:user, contact_method: 'email', email: 'test@example.com', username: nil,
                                  registration_step: 3)
      expect(user.can_advance_to_step?(4)).to be false
    end

    it 'returns false for step 5 when bio is missing' do
      user = build_stubbed(:user, contact_method: 'email', email: 'test@example.com', username: 'testuser', bio: nil,
                                  registration_step: 4)
      expect(user.can_advance_to_step?(5)).to be false
    end

    it 'returns false for step 5 when bio is too short' do
      user = build_stubbed(:user, contact_method: 'email', email: 'test@example.com', username: 'testuser',
                                  bio: 'too short', registration_step: 4)
      expect(user.can_advance_to_step?(5)).to be false
    end

    it 'returns false for invalid step numbers' do
      expect(user.can_advance_to_step?(1)).to be false
      expect(user.can_advance_to_step?(7)).to be false
      expect(user.can_advance_to_step?(0)).to be false
      expect(user.can_advance_to_step?(-1)).to be false
    end
  end

  describe '#advance_to_next_step!' do
    it 'advances to next step when conditions are met' do
      user = build_stubbed(:user, contact_method: 'email', registration_step: 1)
      allow(user).to receive(:can_advance_to_step?).with(2).and_return(true)
      allow(user).to receive(:update!).with(registration_step: 2).and_return(true)

      expect(user.advance_to_next_step!).to be true
    end

    it 'returns false when conditions are not met' do
      user = build_stubbed(:user, contact_method: nil, registration_step: 1)
      allow(user).to receive(:can_advance_to_step?).with(2).and_return(false)

      expect(user.advance_to_next_step!).to be false
    end

    it 'updates the registration_step in database' do
      user = create(:user, :step_one, contact_method: 'email', email: 'test@example.com')
      user.advance_to_next_step!
      user_from_db = described_class.find(user.id)
      expect(user_from_db.registration_step).to eq(2)
    end

    it 'works for multiple consecutive advances' do
      user = create(:user, :step_one, contact_method: 'email', email: 'test@example.com')
      expect(user.advance_to_next_step!).to be true
      expect(user.registration_step).to eq(2)

      user.update_columns(username: 'testuser')
      expect(user.advance_to_next_step!).to be true
      expect(user.registration_step).to eq(3)
    end
  end

  describe 'private methods' do
    describe '#normalize_email' do
      it 'is called before validation when email is present' do
        user = build(:user, email: '  TEST@EXAMPLE.COM  ')
        user.valid?
        expect(user.email).to eq('test@example.com')
      end

      it 'is not called when email is blank' do
        user = build(:user, email: nil)
        expect(user).not_to receive(:normalize_email)
        user.valid?
      end

      it 'handles empty string email' do
        user = build(:user, email: '')
        user.valid?
        expect(user.email).to eq('')
      end
    end

    describe '#generate_email_verification_token' do
      it 'is called before creation when email is present' do
        user = build(:user, email: 'test@example.com')
        expect(user.email_verification_token).to be_nil
        user.save!
        expect(user.email_verification_token).to be_present
        expect(user.email_verification_token_expires_at).to be_present
      end

      it 'is not called when email is blank' do
        user = build(:user, email: nil, contact_method: 'phone', phone: '+1234567890')
        user.save!
        expect(user.email_verification_token).to be_nil
        expect(user.email_verification_token_expires_at).to be_nil
      end

      it 'sets expiration time to 24 hours from now' do
        user = build(:user, email: 'test@example.com')
        user.save!
        expect(user.email_verification_token_expires_at).to be_within(1.minute).of(24.hours.from_now)
      end

      it 'generates a unique token each time' do
        user1 = create(:user, email: 'test1@example.com')
        user2 = create(:user, email: 'test2@example.com')
        expect(user1.email_verification_token).not_to eq(user2.email_verification_token)
      end
    end

    describe '#password_confirmation_matches' do
      it 'adds error when passwords do not match' do
        user = build(:user, password: 'password123', password_confirmation: 'different')
        user.valid?
        expect(user.errors[:password_confirmation]).to include("doesn't match Password")
      end

      it 'does not add error when passwords match' do
        user = build(:user, password: 'password123', password_confirmation: 'password123')
        user.valid?
        expect(user.errors[:password_confirmation]).to be_empty
      end

      it 'does not add error when password_confirmation is nil and password is nil' do
        user = build(:user, password: nil, password_confirmation: nil)
        user.valid?
        expect(user.errors[:password_confirmation]).not_to include("doesn't match Password")
      end
    end
  end

  describe 'edge cases and validations' do
    describe 'email format validation' do
      it 'allows emails with plus signs' do
        user = build(:user, :email_user, :step_two, email: 'user+tag@example.com')
        expect(user).to be_valid
      end

      it 'allows emails with dots in username' do
        user = build(:user, :email_user, :step_two, email: 'first.last@example.com')
        expect(user).to be_valid
      end

      it 'rejects emails with spaces' do
        user = build(:user, :email_user, :step_two, email: 'user @example.com')
        expect(user).not_to be_valid
      end
    end

    describe 'phone format validation' do
      it 'allows phone with country code' do
        user = build(:user, :phone_user, :step_two, phone: '+1234567890')
        expect(user).to be_valid
      end

      it 'allows phone without plus but starting with digit' do
        user = build(:user, :phone_user, :step_two, phone: '1234567890')
        expect(user).to be_valid
      end

      it 'rejects phone starting with zero' do
        user = build(:user, :phone_user, :step_two, phone: '+0123456789')
        expect(user).not_to be_valid
      end

      it 'rejects phone with letters' do
        user = build(:user, :phone_user, :step_two, phone: '+123abc7890')
        expect(user).not_to be_valid
      end
    end

    describe 'username format validation' do
      it 'allows usernames with underscores' do
        user = build(:user, :step_three, username: 'user_name')
        expect(user).to be_valid
      end

      it 'allows usernames with numbers' do
        user = build(:user, :step_three, username: 'user123')
        expect(user).to be_valid
      end

      it 'rejects usernames with special characters' do
        user = build(:user, :step_three, username: 'user@name')
        expect(user).not_to be_valid
      end

      it 'rejects usernames with spaces' do
        user = build(:user, :step_three, username: 'user name')
        expect(user).not_to be_valid
      end
    end

    describe 'password validations with has_secure_password' do
      it 'validates password length on new records' do
        user = build(:user, :step_two, password: 'short')
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
      end

      it 'validates password length on existing records when password is present' do
        user = create(:user, :step_two)
        user.password = 'short'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
      end

      it 'allows nil password on existing records when not being changed' do
        user = create(:user, :step_two)
        user.email = 'newemail@example.com'
        expect(user).to be_valid
      end
    end
  end

  describe 'account locking' do
    let(:user) { create(:user, :complete_registration) }

    describe 'scopes' do
      it 'includes locked users in locked scope' do
        locked_user = create(:user, :complete_registration, locked_at: Time.current)
        unlocked_user = create(:user, :complete_registration, locked_at: nil)

        expect(described_class.locked).to include(locked_user)
        expect(described_class.locked).not_to include(unlocked_user)
      end

      it 'includes unlocked users in unlocked scope' do
        locked_user = create(:user, :complete_registration, locked_at: Time.current)
        unlocked_user = create(:user, :complete_registration, locked_at: nil)

        expect(described_class.unlocked).to include(unlocked_user)
        expect(described_class.unlocked).not_to include(locked_user)
      end

      it 'includes auto-locked users in auto_locked scope' do
        auto_locked_user = create(:user, :complete_registration, locked_at: Time.current, locked_by_admin: false)
        admin_locked_user = create(:user, :complete_registration, locked_at: Time.current, locked_by_admin: true)
        unlocked_user = create(:user, :complete_registration, locked_at: nil)

        expect(described_class.auto_locked).to include(auto_locked_user)
        expect(described_class.auto_locked).not_to include(admin_locked_user)
        expect(described_class.auto_locked).not_to include(unlocked_user)
      end

      it 'includes admin-locked users in admin_locked scope' do
        auto_locked_user = create(:user, :complete_registration, locked_at: Time.current, locked_by_admin: false)
        admin_locked_user = create(:user, :complete_registration, locked_at: Time.current, locked_by_admin: true)
        unlocked_user = create(:user, :complete_registration, locked_at: nil)

        expect(described_class.admin_locked).to include(admin_locked_user)
        expect(described_class.admin_locked).not_to include(auto_locked_user)
        expect(described_class.admin_locked).not_to include(unlocked_user)
      end
    end

    describe '#locked?' do
      it 'returns true when locked_at is present' do
        user.update!(locked_at: Time.current)
        expect(user.locked?).to be true
      end

      it 'returns false when locked_at is nil' do
        user.update!(locked_at: nil)
        expect(user.locked?).to be false
      end
    end

    describe '#unlocked?' do
      it 'returns false when locked_at is present' do
        user.update!(locked_at: Time.current)
        expect(user.unlocked?).to be false
      end

      it 'returns true when locked_at is nil' do
        user.update!(locked_at: nil)
        expect(user.unlocked?).to be true
      end
    end

    describe '#lock_account!' do
      it 'sets locked_at timestamp' do
        travel_to Time.current do
          user.lock_account!
          expect(user.locked_at).to eq(Time.current)
        end
      end

      it 'saves the user' do
        user.lock_account!
        user.reload
        expect(user.locked_at).to be_present
      end
    end

    describe '#unlock_account!' do
      it 'clears locked_at timestamp' do
        user.update!(locked_at: Time.current)
        user.unlock_account!
        expect(user.locked_at).to be_nil
      end

      it 'saves the user' do
        user.update!(locked_at: Time.current)
        user.unlock_account!
        user.reload
        expect(user.locked_at).to be_nil
      end
    end

    describe '#active_for_authentication?' do
      it 'returns false when account is locked' do
        user.update!(locked_at: Time.current)
        expect(user.active_for_authentication?).to be false
      end

      it 'returns true when account is not locked' do
        user.update!(locked_at: nil)
        expect(user.active_for_authentication?).to be true
      end
    end
  end
end
