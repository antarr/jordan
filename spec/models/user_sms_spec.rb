require 'rails_helper'

RSpec.describe User, 'SMS functionality', type: :model do
  let(:phone_user) { build(:user, :phone_user, :step_two) }

  describe 'SMS verification' do
    describe '#phone_verified?' do
      it 'returns true when phone_verified_at is present' do
        user = create(:user, phone_verified_at: Time.current)
        expect(user.phone_verified?).to be true
      end

      it 'returns false when phone_verified_at is nil' do
        user = create(:user, phone_verified_at: nil)
        expect(user.phone_verified?).to be false
      end
    end

    describe '#verify_phone!' do
      it 'sets phone_verified_at to current time' do
        user = create(:user, phone_verified_at: nil)
        expect { user.verify_phone! }.to change { user.phone_verified_at }.from(nil)
        expect(user.phone_verified_at).to be_within(1.second).of(Time.current)
      end

      it 'clears sms_verification_code' do
        user = create(:user, sms_verification_code: '123456')
        user.verify_phone!
        expect(user.sms_verification_code).to be_nil
      end

      it 'clears sms_verification_code_expires_at' do
        user = create(:user, sms_verification_code_expires_at: 1.hour.from_now)
        user.verify_phone!
        expect(user.sms_verification_code_expires_at).to be_nil
      end
    end

    describe '#generate_sms_verification_code!' do
      it 'generates a new code' do
        user = create(:user, sms_verification_code: nil)
        user.generate_sms_verification_code!
        expect(user.sms_verification_code).to be_present
        expect(user.sms_verification_code).to match(/\A\d{6}\z/)
      end

      it 'sets expiration time to 15 minutes from now' do
        user = create(:user)
        user.generate_sms_verification_code!
        expect(user.sms_verification_code_expires_at).to be_within(1.second).of(15.minutes.from_now)
      end

      it 'generates a unique code each time' do
        user = create(:user)
        user.generate_sms_verification_code!
        first_code = user.sms_verification_code

        user.generate_sms_verification_code!
        second_code = user.sms_verification_code

        expect(first_code).not_to eq(second_code)
      end
    end

    describe '#sms_verification_code_expired?' do
      it 'returns false for unexpired codes' do
        user = create(:user, sms_verification_code_expires_at: 5.minutes.from_now)
        expect(user.sms_verification_code_expired?).to be false
      end

      it 'returns true for expired codes' do
        user = create(:user, sms_verification_code_expires_at: 5.minutes.ago)
        expect(user.sms_verification_code_expired?).to be true
      end

      it 'returns false when expiration time is nil' do
        user = create(:user, sms_verification_code_expires_at: nil)
        expect(user.sms_verification_code_expired?).to be false
      end
    end

    describe '#sms_verification_code_valid?' do
      it 'returns true for valid, unexpired code' do
        code = '123456'
        user = create(:user, 
                     sms_verification_code: code, 
                     sms_verification_code_expires_at: 5.minutes.from_now)
        expect(user.sms_verification_code_valid?(code)).to be true
      end

      it 'returns false for invalid code' do
        user = create(:user, 
                     sms_verification_code: '123456', 
                     sms_verification_code_expires_at: 5.minutes.from_now)
        expect(user.sms_verification_code_valid?('wrong')).to be false
      end

      it 'returns false for expired code' do
        code = '123456'
        user = create(:user, 
                     sms_verification_code: code, 
                     sms_verification_code_expires_at: 5.minutes.ago)
        expect(user.sms_verification_code_valid?(code)).to be false
      end

      it 'returns false when code is blank' do
        user = create(:user, sms_verification_code: nil)
        expect(user.sms_verification_code_valid?('123456')).to be false
      end
    end
  end

  describe 'scopes' do
    describe '.phone_verified' do
      it 'returns only phone verified users' do
        verified_user = create(:user, phone_verified_at: Time.current)
        unverified_user = create(:user, phone_verified_at: nil)

        expect(User.phone_verified).to include(verified_user)
        expect(User.phone_verified).not_to include(unverified_user)
      end
    end

    describe '.phone_unverified' do
      it 'returns only phone unverified users' do
        verified_user = create(:user, phone_verified_at: Time.current)
        unverified_user = create(:user, phone_verified_at: nil)

        expect(User.phone_unverified).to include(unverified_user)
        expect(User.phone_unverified).not_to include(verified_user)
      end
    end
  end

  describe 'password validation for phone users' do
    it 'does not require password for phone users during registration' do
      user = build(:user, :phone_user, password: nil, password_confirmation: nil)
      user.registration_step = 2
      expect(user).to be_valid
    end

    it 'validates password when phone user sets one' do
      user = build(:user, :phone_user, password: 'short', password_confirmation: 'short')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too short (minimum is 6 characters)')
    end

    it 'allows phone user to set a valid password' do
      user = build(:user, :phone_user, password: 'ValidPass123!', password_confirmation: 'ValidPass123!')
      expect(user).to be_valid
    end
  end
end