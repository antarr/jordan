require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
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
      user = User.new(email: 'invalid-email', password: 'password123')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('is invalid')
    end

    it 'is not valid with a duplicate email' do
      User.create!(email: 'test@example.com', password: 'password123')
      user = User.new(email: 'test@example.com', password: 'password456')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('has already been taken')
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

    it 'requires a password' do
      user = User.new(email: 'test@example.com')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end
  end
end