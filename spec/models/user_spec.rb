require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    describe 'email' do
      it 'is valid with valid attributes' do
        user = User.new(email: 'test@example.com', password: 'password123')
        expect(user).to be_valid
      end

      it 'is not valid without an email' do
        user = User.new(password: 'password123')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'is not valid with an invalid email format' do
        invalid_emails = [
          'invalid-email',
          'user@',
          '@example.com',
          'user example@test.com',
          'user@example..com'
        ]

        invalid_emails.each do |invalid_email|
          user = User.new(email: invalid_email, password: 'password123')
          expect(user).not_to be_valid, "Expected #{invalid_email} to be invalid"
          expect(user.errors[:email]).to include('is invalid')
        end
      end

      it 'accepts valid email formats' do
        valid_emails = [
          'user@example.com',
          'user.name@example.com',
          'user+tag@example.co.uk',
          'user_name@example-domain.com',
          '123@example.com',
          'user@subdomain.example.com'
        ]

        valid_emails.each do |valid_email|
          user = User.new(email: valid_email, password: 'password123')
          expect(user).to be_valid, "Expected #{valid_email} to be valid"
        end
      end

      it 'is not valid with a duplicate email' do
        User.create!(email: 'test@example.com', password: 'password123')
        user = User.new(email: 'test@example.com', password: 'password456')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('has already been taken')
      end

      it 'enforces uniqueness case-insensitively' do
        User.create!(email: 'Test@Example.com', password: 'password123')
        user = User.new(email: 'test@example.com', password: 'password456')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('has already been taken')
      end

      it 'normalizes email by stripping whitespace and downcasing' do
        user = User.create!(email: '  Test@Example.com  ', password: 'password123')
        expect(user.email).to eq('test@example.com')
      end

      it 'does not accept nil email' do
        user = User.new(email: nil, password: 'password123')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end

      it 'does not accept empty string email' do
        user = User.new(email: '', password: 'password123')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include("can't be blank")
      end
    end
  end

  describe 'has_secure_password' do
    let(:user) { User.new(email: 'test@example.com', password: 'password123') }

    it 'authenticates with correct password' do
      user.save!
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'does not authenticate with incorrect password' do
      user.save!
      expect(user.authenticate('wrongpassword')).to be_falsey
    end

    it 'requires a password on creation' do
      user = User.new(email: 'test@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'does not require password on update when not changed' do
      user.save!
      user.email = 'newemail@example.com'
      expect(user).to be_valid
    end

    it 'encrypts the password' do
      user.save!
      expect(user.password_digest).not_to eq('password123')
      expect(user.password_digest).to be_present
    end

    it 'accepts passwords with minimum length' do
      user = User.new(email: 'test@example.com', password: '123456')
      expect(user).to be_valid
    end

    it 'rejects empty passwords' do
      user = User.new(email: 'test@example.com', password: '')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'rejects nil passwords' do
      user = User.new(email: 'test@example.com', password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'allows long passwords up to 72 characters' do
      long_password = 'a' * 72
      user = User.new(email: 'test@example.com', password: long_password)
      expect(user).to be_valid
    end

    it 'rejects passwords longer than 72 characters' do
      # BCrypt has a 72 character limit and Rails validates this
      password = 'a' * 73
      user = User.new(email: 'test@example.com', password: password)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too long')
    end
  end

  describe 'callbacks' do
    it 'normalizes email before validation' do
      user = User.create!(email: '  Test@Example.com  ', password: 'password123')
      expect(user.email).to eq('test@example.com')
    end

    it 'generates email verification token before creation' do
      user = User.new(email: 'test@example.com', password: 'password123')
      expect(user.email_verification_token).to be_nil
      user.save!
      expect(user.email_verification_token).to be_present
      expect(user.email_verification_token_expires_at).to be_present
    end
  end

  describe 'scopes' do
    let!(:verified_user) { User.create!(email: 'verified@example.com', password: 'password123', email_verified_at: Time.current) }
    let!(:unverified_user) { User.create!(email: 'unverified@example.com', password: 'password123') }

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
      user = User.create!(email: 'test@example.com', password: 'password123', email_verified_at: Time.current)
      expect(user.email_verified?).to be true
    end

    it 'returns false when email_verified_at is nil' do
      user = User.create!(email: 'test@example.com', password: 'password123')
      expect(user.email_verified?).to be false
    end
  end

  describe '#verify_email!' do
    let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

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
    let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

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
    let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

    it 'returns false for unexpired tokens' do
      user.update!(email_verification_token_expires_at: 1.hour.from_now)
      expect(user.email_verification_token_expired?).to be false
    end

    it 'returns true for expired tokens' do
      user.update!(email_verification_token_expires_at: 1.hour.ago)
      expect(user.email_verification_token_expired?).to be true
    end

    it 'returns false when expiration time is nil' do
      user.update!(email_verification_token_expires_at: nil)
      expect(user.email_verification_token_expired?).to be false
    end
  end

  describe '#email_verification_token_valid?' do
    let(:user) { User.create!(email: 'test@example.com', password: 'password123') }

    it 'returns true for valid, unexpired token' do
      token = user.email_verification_token
      expect(user.email_verification_token_valid?(token)).to be true
    end

    it 'returns false for invalid token' do
      expect(user.email_verification_token_valid?('invalid_token')).to be false
    end

    it 'returns false for expired token' do
      user.update!(email_verification_token_expires_at: 1.hour.ago)
      token = user.email_verification_token
      expect(user.email_verification_token_valid?(token)).to be false
    end

    it 'returns false when token is blank' do
      user.update!(email_verification_token: nil)
      expect(user.email_verification_token_valid?('any_token')).to be false
    end
  end
end