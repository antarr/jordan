require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    context 'when contact_method is email and registration_step >= 2' do
      subject { build(:user, :email_user, :step_two) }

      it { should validate_presence_of(:email) }
      it { should validate_uniqueness_of(:email).case_insensitive }
      it { should allow_value(Faker::Internet.email).for(:email) }
      it { should_not allow_value('invalid-email').for(:email) }
      it { should_not allow_value('user@').for(:email) }
      it { should_not allow_value('@example.com').for(:email) }
      it { should_not allow_value('user example@test.com').for(:email) }
      it { should_not allow_value('user@example..com').for(:email) }

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

      it { should validate_presence_of(:phone) }
      it { should validate_uniqueness_of(:phone).case_insensitive }
      it { should allow_value('+1234567890').for(:phone) }
      it { should allow_value('+12345678901234').for(:phone) }
      it { should_not allow_value('invalid-phone').for(:phone) }
      it { should_not allow_value('123').for(:phone) }
    end

    context 'when registration_step >= 3' do
      subject { build(:user, :step_three) }

      it { should validate_presence_of(:username) }
      it { should validate_uniqueness_of(:username).case_insensitive }
      it { should allow_value(Faker::Internet.username(specifier: 5..12, separators: %w[_])).for(:username) }
      it { should_not allow_value('invalid@username!').for(:username) }
    end

    context 'when registration_step >= 4' do
      subject { build(:user, :step_four) }

      it { should validate_presence_of(:bio) }
      it { should validate_length_of(:bio).is_at_least(25) }
    end

    context 'password validations' do
      subject { build(:user, :step_two) }

      it { should validate_presence_of(:password) }
      it { should validate_length_of(:password).is_at_least(6).is_at_most(72) }
      it { should validate_presence_of(:password_confirmation) }

      it 'validates password confirmation matches' do
        user = build(:user, password: 'password123', password_confirmation: 'different')
        expect(user).not_to be_valid
        expect(user.errors[:password_confirmation]).to include("doesn't match Password")
      end
    end

    context 'contact_method validation' do
      it { should allow_value('email').for(:contact_method) }
      it { should allow_value('phone').for(:contact_method) }
      it { should_not allow_value('invalid').for(:contact_method) }
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
        expect(User.verified).to include(verified_user)
        expect(User.verified).not_to include(unverified_user)
      end
    end

    describe '.unverified' do
      it 'returns only unverified users' do
        expect(User.unverified).to include(unverified_user)
        expect(User.unverified).not_to include(verified_user)
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
    it 'returns true when registration_step is 5 or higher' do
      user = create(:user, :complete_registration)
      expect(user.registration_complete?).to be true
    end

    it 'returns false when registration_step is less than 5' do
      user = create(:user, :incomplete_registration)
      expect(user.registration_complete?).to be false
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
      user = create(:user, :step_three, username: Faker::Internet.username)
      expect(user.can_advance_to_step?(4)).to be true
    end

    it 'returns true for step 5 when bio is present and long enough' do
      user = create(:user, :step_four, bio: Faker::Lorem.paragraph(sentence_count: 3))
      expect(user.can_advance_to_step?(5)).to be true
    end
  end
end
