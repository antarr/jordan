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

  describe 'associations' do
    it 'responds to expected associations' do
      pending 'Add association tests here when associations are added'
    end
  end

  describe 'callbacks' do
    it 'has expected callbacks' do
      pending 'Add callback tests here when callbacks are added'
    end
  end

  describe 'scopes' do
    it 'has expected scopes' do
      pending 'Add scope tests here when scopes are added'
    end
  end

  describe 'instance methods' do
    it 'has expected instance methods' do
      pending 'Add instance method tests here when custom methods are added'
    end
  end

  describe 'class methods' do
    it 'has expected class methods' do
      pending 'Add class method tests here when custom methods are added'
    end
  end
end