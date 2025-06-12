require 'rails_helper'

RSpec.describe PhoneAuthenticationService, type: :service do
  let(:phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: Time.current) }
  let(:unverified_phone_user) { create(:user, :phone_user, :step_two, phone_verified_at: nil) }
  let(:phone_user_with_password) do
    create(:user, :phone_user, :step_two,
           phone_verified_at: Time.current,
           password: 'ValidPass123!',
           password_confirmation: 'ValidPass123!')
  end

  describe '#authenticate' do
    context 'with SMS code authentication' do
      before do
        phone_user.generate_sms_verification_code!
      end

      it 'succeeds with valid SMS code' do
        service = described_class.new(
          phone: phone_user.phone,
          sms_code: phone_user.sms_verification_code
        )

        expect(service.authenticate).to be true
        expect(service.user).to eq(phone_user)
        expect(service.success?).to be true
      end

      it 'clears SMS code after successful authentication' do
        service = described_class.new(
          phone: phone_user.phone,
          sms_code: phone_user.sms_verification_code
        )

        service.authenticate
        expect(phone_user.reload.sms_verification_code).to be_nil
        expect(phone_user.sms_verification_code_expires_at).to be_nil
      end

      it 'fails with invalid SMS code' do
        service = described_class.new(
          phone: phone_user.phone,
          sms_code: '000000'
        )

        expect(service.authenticate).to be false
        expect(service.success?).to be false
        expect(service.error_message).to eq(I18n.t('phone_sessions.create.invalid_sms_code'))
      end

      it 'fails with expired SMS code' do
        phone_user.update!(sms_verification_code_expires_at: 1.hour.ago)

        service = described_class.new(
          phone: phone_user.phone,
          sms_code: phone_user.sms_verification_code
        )

        expect(service.authenticate).to be false
        expect(service.error_message).to eq(I18n.t('phone_sessions.create.invalid_sms_code'))
      end
    end

    context 'with password authentication' do
      it 'succeeds with valid password' do
        service = described_class.new(
          phone: phone_user_with_password.phone,
          password: 'ValidPass123!'
        )

        expect(service.authenticate).to be true
        expect(service.user).to eq(phone_user_with_password)
        expect(service.success?).to be true
      end

      it 'fails with invalid password' do
        service = described_class.new(
          phone: phone_user_with_password.phone,
          password: 'WrongPassword'
        )

        expect(service.authenticate).to be false
        expect(service.success?).to be false
        expect(service.error_message).to eq(I18n.t('phone_sessions.create.invalid_password'))
      end

      it 'fails when user has no password_digest' do
        service = described_class.new(
          phone: phone_user.phone,
          password: 'SomePassword'
        )

        expect(service.authenticate).to be false
        expect(service.error_message).to eq(I18n.t('phone_sessions.create.invalid_password'))
      end
    end

    context 'with missing credentials' do
      it 'fails when neither SMS code nor password provided' do
        service = described_class.new(phone: phone_user.phone)

        expect(service.authenticate).to be false
        expect(service.error_message).to eq(I18n.t('phone_sessions.create.missing_credentials'))
      end
    end

    context 'with non-existent phone number' do
      it 'fails and returns phone not found error' do
        service = described_class.new(
          phone: '+1234567890',
          sms_code: '123456'
        )

        expect(service.authenticate).to be false
        expect(service.error_message).to eq(I18n.t('phone_sessions.create.phone_not_found'))
      end
    end

    context 'with unverified phone number' do
      it 'fails and returns phone not verified error' do
        service = described_class.new(
          phone: unverified_phone_user.phone,
          sms_code: '123456'
        )

        expect(service.authenticate).to be false
        expect(service.error_message).to eq(I18n.t('phone_sessions.create.phone_not_verified'))
      end
    end
  end

  describe '#success?' do
    it 'returns true when no errors' do
      service = described_class.new(phone: phone_user.phone)
      expect(service.success?).to be true
    end

    it 'returns false when there are errors' do
      service = described_class.new(phone: '+1234567890')
      service.authenticate
      expect(service.success?).to be false
    end
  end

  describe '#error_message' do
    it 'returns the first error message' do
      service = described_class.new(phone: '+1234567890')
      service.authenticate
      expect(service.error_message).to eq(I18n.t('phone_sessions.create.phone_not_found'))
    end

    it 'returns nil when no errors' do
      service = described_class.new(phone: phone_user.phone)
      expect(service.error_message).to be_nil
    end
  end
end
